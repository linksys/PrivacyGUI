import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/add_nodes/services/add_nodes_service.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

// ---------------------------------------------------------------------------
// Timing
// ---------------------------------------------------------------------------

/// How often and how long the flow reads the router.
///
/// A provider so a test can shorten every wait instead of sitting through it.
class AddNodesTimings {
  /// Between two reads of the session, and of DataElements while joining.
  ///
  /// Not the effective cadence. A generated `fetch` goes through the request
  /// throttler's 5 s completed-GET cache and cannot ask for a fresh read, so two
  /// reads inside 5 s return the same answer (#1572). That costs at most 5 s of
  /// latency on a phase that lasts tens of seconds; a cache hit is no bridge
  /// traffic, and the first tick after the entry expires reads the router again.
  /// `Start()` itself empties the cache, so the first read after it is fresh.
  final Duration pollInterval;

  /// How long a session may run before the flow stops it and gives up.
  ///
  /// Ten minutes. One node can take a scan (5 s, up to three passes), a BLE
  /// connect, `onboard_timeout` (45 s on the bench) plus `onboard_grace` (75 s),
  /// retried for a dropped BLE link — and nodes are onboarded one after another.
  /// The firmware lets a new request override a session older than 300 s, which
  /// is a wedge-breaker, not a bound on a real one.
  final Duration sessionLimit;

  /// How long after the session ends the flow waits for its nodes to appear in
  /// DataElements.
  ///
  /// Three minutes. The firmware keeps correcting late joiners for
  /// `late_join_tail` (120 s on the bench) after the session ends, and one node
  /// appeared about 30 s after `Complete` on the bench; the longest recorded,
  /// after a session that timed out, was about six minutes, which the page
  /// covers by saying the node may still come online rather than by waiting.
  final Duration joinLimit;

  const AddNodesTimings({
    this.pollInterval = const Duration(seconds: 2),
    this.sessionLimit = const Duration(minutes: 10),
    this.joinLimit = const Duration(minutes: 3),
  });
}

final addNodesTimingsProvider =
    Provider<AddNodesTimings>((ref) => const AddNodesTimings());

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// The add-nodes flow. Page-scoped: it holds one run and is discarded when the
/// page closes, which stops a session the page started.
final addNodesProvider =
    AutoDisposeNotifierProvider<AddNodesNotifier, AddNodesState>(
  AddNodesNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Adds every unconfigured node in range to the mesh, and follows each one until
/// the controller lists it.
///
/// The session runs on the router; this polls it. Three things the router's
/// answers do not settle on their own, and which this class is for:
///
/// * **Whose session it is.** `Status` and `Result` describe the router's last
///   session, whoever started it. The session counter read right after this
///   flow's `Start()` is this flow's; any other value means someone else's
///   session replaced it.
/// * **When a node has joined.** `Success` is the Wi-Fi verdict. A node is a
///   mesh node once DataElements lists it with a backhaul link, which can lag
///   the session's end — and a node the session gave up on can join anyway.
/// * **Leaving.** A session keeps running after the page that started it is
///   gone, so leaving stops it.
class AddNodesNotifier extends AutoDisposeNotifier<AddNodesState> {
  static const _tag = '[AddNodes]';

  /// Bumped by every run and by dispose. A loop compares it after each await and
  /// stops when it no longer matches, so a superseded loop never publishes.
  int _generation = 0;

  bool _disposed = false;

  /// The service and lock captured when a run starts.
  ///
  /// Captured rather than read on use because `onDispose` must send `Stop()`,
  /// and reading a provider through `ref` once the container is disposed throws.
  AddNodesService? _service;
  UspMutationLock? _lock;

  @override
  AddNodesState build() {
    ref.onDispose(() {
      _disposed = true;
      final wasRunning = state.isRunning;
      _generation++;
      if (wasRunning) _stopOnLeave();
    });
    // After build returns: the read publishes into `state`, which does not exist
    // until it has.
    final generation = ++_generation;
    Future.microtask(() => _check(generation));
    return const AddNodesState();
  }

  // ---------------------------------------------------------------------------
  // Entry
  // ---------------------------------------------------------------------------

  /// Reads the router's session again, as on entry: after a failed read, or to
  /// see whether a session someone else started has ended.
  Future<void> recheck() async {
    if (state.isRunning || state.phase == AddNodesPhase.checking) return;
    final generation = ++_generation;
    _publish(generation, const AddNodesState());
    await _check(generation);
  }

  Future<void> _check(int generation) async {
    if (!_current(generation)) return;
    final OnboardingSessionUIModel session;
    try {
      session = await ref.read(addNodesServiceProvider).fetchSession();
    } on ServiceError catch (e) {
      logger.w('$_tag reading the session on entry failed', error: e);
      _publish(
          generation, AddNodesState(phase: AddNodesPhase.loadFailed, error: e));
      return;
    }
    _publish(generation, AddNodesState(phase: _entryPhase(session)));
  }

  /// The phase a session read on entry offers.
  ///
  /// `Idle` is not "ready": the router reads idle also when it cannot run a
  /// session, and only `Result` says which. A *finished* session reads
  /// `Complete` with its outcome, and that is ready too — it is somebody's last
  /// run, not something in progress.
  static AddNodesPhase _entryPhase(OnboardingSessionUIModel session) {
    if (session.isRunning) return AddNodesPhase.busy;
    if (session.isUnavailable) return AddNodesPhase.unavailable;
    return AddNodesPhase.ready;
  }

  // ---------------------------------------------------------------------------
  // Run
  // ---------------------------------------------------------------------------

  /// Starts onboarding every unconfigured node in range, and follows the session
  /// to its end. Does nothing unless [AddNodesState.canStart].
  Future<void> start() async {
    if (!state.canStart) return;
    final generation = ++_generation;
    final service = ref.read(addNodesServiceProvider);
    final lock = ref.read(uspMutationLockProvider);
    _service = service;
    _lock = lock;

    _publish(generation, const AddNodesState(phase: AddNodesPhase.starting));

    final OnboardingStartResult started;
    try {
      // The lock is around the command only. A session runs for minutes, past
      // the lock's 30 s timeout, and holding it would block every other write in
      // the app; the reads below need no lock.
      started = await lock.withLock(service.start);
    } on ServiceError catch (e) {
      logger.w('$_tag Start() failed', error: e);
      _publish(
          generation, AddNodesState(phase: AddNodesPhase.failed, error: e));
      return;
    } on TimeoutException catch (e) {
      // Waiting for another write to release the lock, not Start() itself.
      logger.w('$_tag Start() waited too long for the mutation lock: $e');
      _publish(
          generation,
          const AddNodesState(
              phase: AddNodesPhase.failed, error: TimeoutError()));
      return;
    }

    switch (started) {
      case OnboardingStartResult.started:
        await _follow(generation, service);
      case OnboardingStartResult.busy:
        _publish(generation, const AddNodesState(phase: AddNodesPhase.busy));
      case OnboardingStartResult.unsupportedRole:
      case OnboardingStartResult.backendUnavailable:
        _publish(
            generation, const AddNodesState(phase: AddNodesPhase.unavailable));
    }
  }

  /// Polls this flow's session until it ends, then follows its nodes into
  /// DataElements.
  Future<void> _follow(int generation, AddNodesService service) async {
    final timings = ref.read(addNodesTimingsProvider);
    final giveUpAt = clock.now().add(timings.sessionLimit);
    int? ownSession;
    var isFirstRead = true;

    while (_current(generation)) {
      if (!isFirstRead) {
        if (!clock.now().isBefore(giveUpAt)) {
          logger.w('$_tag the session ran past ${timings.sessionLimit}; '
              'stopping it');
          _publish(
              generation,
              state.copyWith(
                  phase: AddNodesPhase.failed, error: const TimeoutError()));
          await _stop(service);
          return;
        }
        await Future<void>.delayed(timings.pollInterval);
        if (!_current(generation)) return;
      }
      isFirstRead = false;

      final OnboardingSessionUIModel session;
      try {
        session = await service.fetchSession();
      } on ServiceError catch (e) {
        // The session goes on without us; one lost read is not its end. The
        // deadline above bounds a router that stays unreachable.
        logger.w('$_tag reading the session failed; reading again', error: e);
        continue;
      }
      if (!_current(generation)) return;

      // The read straight after Start() is this flow's session: the firmware
      // writes the counter before it answers Started.
      ownSession ??= session.session;
      if (session.session != ownSession) {
        logger.w('$_tag session ${session.session} replaced ours '
            '($ownSession); stopping following it');
        _publish(
            generation,
            state.copyWith(
                phase: AddNodesPhase.failed, clearSessionResult: true));
        return;
      }

      switch (session.status) {
        case OnboardingSessionStatus.idle:
          // Only a cancel elsewhere — another client's Stop() — puts a running
          // session back to idle.
          _publish(
              generation,
              state.copyWith(
                  phase: AddNodesPhase.cancelled, nodes: session.nodes));
          return;
        case OnboardingSessionStatus.scanning:
          _publish(
              generation,
              state.copyWith(
                  phase: AddNodesPhase.searching, nodes: session.nodes));
        case OnboardingSessionStatus.onboarding:
          _publish(
              generation,
              state.copyWith(
                  phase: AddNodesPhase.onboarding, nodes: session.nodes));
        case OnboardingSessionStatus.complete:
          await _finish(generation, service, session);
          return;
      }
    }
  }

  /// Reads where a finished session leaves its nodes.
  Future<void> _finish(
    int generation,
    AddNodesService service,
    OnboardingSessionUIModel session,
  ) async {
    final result = session.result;
    final ended = state.copyWith(nodes: session.nodes, sessionResult: result);

    // The nodes worth waiting for: the ones the session onboarded, and the ones
    // it gave up on that may still join — the firmware upgrades those to
    // onboarded when they do, and DataElements can list them first.
    final awaited = [
      for (final node in session.nodes)
        if ((node.isOnboarded || node.mayStillJoin) &&
            node.alMacAddress != null)
          node.alMacAddress!,
    ];

    switch (result) {
      case OnboardingSessionResult.cancelled:
        _publish(generation, ended.copyWith(phase: AddNodesPhase.cancelled));
        return;
      case OnboardingSessionResult.noDevicesFound:
        _publish(generation, ended.copyWith(phase: AddNodesPhase.noNodesFound));
        return;
      default:
        break;
    }

    if (awaited.isNotEmpty) {
      await _awaitJoin(generation, service, ended, awaited);
      return;
    }
    if (result == OnboardingSessionResult.success ||
        result == OnboardingSessionResult.partial) {
      // Onboarded, but with no AL MAC to find the node by — an agent that did
      // not send one over BLE. The session's own verdict is all there is to go
      // on, so it is taken, and the topology is read again to draw the node.
      logger.w('$_tag the session reports a node onboarded but no AL MAC to '
          'confirm it by; taking the session at its word');
      _publish(generation, ended.copyWith(phase: AddNodesPhase.joined));
      unawaited(ref.read(devicesDataProvider.notifier).refetch());
      return;
    }
    // Nothing joined and nothing may: Failed, TimedOut with no node that got
    // far enough to report an AL MAC, or a value outside the documented set.
    _publish(generation, ended.copyWith(phase: AddNodesPhase.failed));
  }

  /// Waits for [awaited] to appear in DataElements, publishing each one as it
  /// does, and refreshes the topology once any has.
  Future<void> _awaitJoin(
    int generation,
    AddNodesService service,
    AddNodesState ended,
    List<String> awaited,
  ) async {
    final timings = ref.read(addNodesTimingsProvider);
    final giveUpAt = clock.now().add(timings.joinLimit);
    final wanted = meshNodeMacSet(awaited);
    var joined = <String>{};
    var isFirstRead = true;

    _publish(generation, ended.copyWith(phase: AddNodesPhase.joining));

    while (_current(generation)) {
      if (!isFirstRead) {
        if (!clock.now().isBefore(giveUpAt)) break;
        await Future<void>.delayed(timings.pollInterval);
        if (!_current(generation)) return;
      }
      isFirstRead = false;

      final Set<String> listed;
      try {
        listed = await service.fetchJoinedNodes(awaited);
      } on ServiceError catch (e) {
        logger.w('$_tag reading DataElements failed; reading again', error: e);
        continue;
      }
      if (!_current(generation)) return;

      // A union, not the latest read: a node seen once has joined, and dropping
      // out of one read — re-associating — does not undo that.
      final seen = joined.union(listed);
      if (seen.length > joined.length) {
        joined = seen;
        _publish(
            generation,
            state.copyWith(
                joinedNodeKeys: joined,
                // A node is a mesh node now, so the page can say so while it
                // waits for the rest.
                phase: AddNodesPhase.joined));
      }
      if (joined.containsAll(wanted)) break;
    }
    if (!_current(generation)) return;

    if (joined.isEmpty) {
      logger.w('$_tag no node of the session appeared in DataElements within '
          '${timings.joinLimit}');
      _publish(generation, state.copyWith(phase: AddNodesPhase.failed));
      return;
    }
    // The devices provider keeps the topology it has across a device refresh and
    // re-reads DataElements behind it — but only on a Hosts push, which can come
    // before the node is in DataElements and so leave it drawn as a client.
    unawaited(ref.read(devicesDataProvider.notifier).refetch());
  }

  // ---------------------------------------------------------------------------
  // Stop
  // ---------------------------------------------------------------------------

  /// Stops the session this flow started. Safe to call when nothing runs.
  Future<void> cancel() async {
    if (!state.isRunning) return;
    final generation = ++_generation;
    final AddNodesService service =
        _service ?? ref.read(addNodesServiceProvider);
    _publish(generation, state.copyWith(phase: AddNodesPhase.cancelled));
    await _stop(service);
  }

  /// `Stop()` under the lock, logged rather than thrown: the user asked to stop
  /// following the session, and a failed stop leaves it to end on its own.
  Future<void> _stop(AddNodesService service) async {
    final UspMutationLock lock = _lock ?? ref.read(uspMutationLockProvider);
    try {
      await lock.withLock(service.stop);
    } on ServiceError catch (e) {
      logger.w('$_tag Stop() failed', error: e);
    } on TimeoutException catch (e) {
      logger.w('$_tag Stop() waited too long for the mutation lock: $e');
    }
  }

  /// The page went away with a session running. Uses what the run captured:
  /// `ref` cannot be read once the provider is disposed.
  void _stopOnLeave() {
    final service = _service;
    final lock = _lock;
    if (service == null || lock == null) return;
    logger.i('$_tag the page closed with a session running; stopping it');
    unawaited(lock.withLock(service.stop).catchError((Object e) {
      logger.w('$_tag Stop() on leave failed: $e');
    }));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _current(int generation) => !_disposed && generation == _generation;

  /// Publishes [next] if [generation] is still the run in charge.
  void _publish(int generation, AddNodesState next) {
    if (!_current(generation)) return;
    if (state.phase != next.phase) {
      logger.i('$_tag phase: ${state.phase.name} → ${next.phase.name}');
    }
    state = next;
  }
}
