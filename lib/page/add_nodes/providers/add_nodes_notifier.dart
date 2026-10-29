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

  /// How long a session may run per node it found, before the flow stops it
  /// (#1738). The limit is this times the nodes found, at least one, from the
  /// moment `Start()` answered, and it grows as the session reports more.
  ///
  /// Six minutes. Nodes are onboarded one after another, and on 2026-10-28 a
  /// node that failed took about four, measured from the controller's log: a
  /// BLE connect (~30 s), the previous node's WPS walk window (85–97 s, every
  /// node after the first) and WPS-PBC itself (120 s). The same log shows BLE
  /// connect and onboard-command retries that can add ~2.5 minutes more; those
  /// are read off the log, not measured. A fixed ten minutes, the figure before
  /// this, cut the third of three failing nodes off 65 s into its WPS window.
  ///
  /// No overall cap: the page is exempt from the idle logout, and Cancel is
  /// offered throughout. The firmware lets a new request override a session
  /// older than 300 s, which is a wedge-breaker, not a bound on a real one.
  final Duration perNodeLimit;

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
    this.perNodeLimit = const Duration(minutes: 6),
    this.joinLimit = const Duration(minutes: 3),
  });

  /// The session limit for a session that has found [nodesFound] nodes.
  Duration sessionLimitFor(int nodesFound) =>
      perNodeLimit * (nodesFound < 1 ? 1 : nodesFound);
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

  /// The last `Start()` this flow sent, or null before the first.
  _StartRun? _run;

  @override
  AddNodesState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
      final run = _run;
      if (run == null) return;
      // By ownership, not by phase: a session that has ended, or that another
      // one replaced, is not this flow's to stop whatever the page last showed.
      if (run.owns) {
        _stopOnLeave(run);
      } else if (state.phase == AddNodesPhase.starting) {
        // Left while Start() was on its way.
        run.stopWhenStarted = true;
      }
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

    final AddNodesService service;
    try {
      service = ref.read(addNodesServiceProvider);
    } on ServiceError catch (e) {
      logger.w('$_tag no service to start a session with', error: e);
      _publish(
          generation, AddNodesState(phase: AddNodesPhase.failed, error: e));
      return;
    }
    final run = _StartRun(service, ref.read(uspMutationLockProvider));
    _run = run;

    _publish(generation, const AddNodesState(phase: AddNodesPhase.starting));

    final OnboardingStartResult? started;
    try {
      // The lock is around the command only. A session runs for minutes, past
      // the lock's 30 s timeout, and holding it would block every other write in
      // the app; the reads below need no lock.
      //
      // Another write can hold the lock, so this can wait before Start() goes
      // out; a cancel in that wait sends nothing at all. Null: not sent.
      started = await run.lock
          .withLock(() async => run.stopWhenStarted ? null : service.start());
    } on ServiceError catch (e) {
      logger.w('$_tag Start() failed', error: e);
      _publish(
          generation, AddNodesState(phase: AddNodesPhase.failed, error: e));
      return;
    } on TimeoutException catch (e) {
      // Start() itself did not answer: the lock's timeout covers the command it
      // holds, and a wait for the lock that runs out force-releases it rather
      // than throwing. So the router may have started a session. No Stop() for
      // it: with no answer it cannot be told from a session the pairing button
      // started. One of ours that nobody follows is left to end on its own —
      // how long that takes on the firmware has not been measured.
      logger.w('$_tag Start() did not answer in time: $e');
      _publish(
          generation,
          const AddNodesState(
              phase: AddNodesPhase.failed, error: TimeoutError()));
      return;
    }

    if (started == OnboardingStartResult.started) {
      run.owns = true;
      if (run.stopWhenStarted) {
        // Cancelled or left while Start() was on its way. The session is ours
        // and nobody is following it.
        logger.i('$_tag Start() answered after a cancel; stopping the session');
        await _stop(run);
        return;
      }
    }

    switch (started) {
      case null:
        // Cancelled before it went out; cancel() has published already.
        logger.i('$_tag cancelled before Start() was sent; sent nothing');
      case OnboardingStartResult.started:
        await _follow(generation, run);
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
  Future<void> _follow(int generation, _StartRun run) async {
    final service = run.service;
    final timings = ref.read(addNodesTimingsProvider);
    // The limit grows with the nodes the session reports (#1738); found is read
    // as the larger of the counter and the table, which can disagree.
    final startedAt = clock.now();
    var nodesFound = 0;
    int? ownSession;
    var isFirstRead = true;

    while (_current(generation)) {
      if (!isFirstRead) {
        final limit = timings.sessionLimitFor(nodesFound);
        if (!clock.now().isBefore(startedAt.add(limit))) {
          logger.w('$_tag the session ran past $limit for $nodesFound '
              'node(s); stopping it');
          await _endAtLimit(generation, run);
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
        run.owns = false;
        _publish(
            generation,
            state.copyWith(
                phase: AddNodesPhase.failed, clearSessionResult: true));
        return;
      }
      final reported = session.devicesFound > session.nodes.length
          ? session.devicesFound
          : session.nodes.length;
      if (reported > nodesFound) nodesFound = reported;

      switch (session.status) {
        case OnboardingSessionStatus.idle:
          // Only a cancel elsewhere — another client's Stop() — puts a running
          // session back to idle.
          run.owns = false;
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
          // Over on the router; what is left is waiting on DataElements.
          run.owns = false;
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
    await _awaitJoin(generation, service, ended);
  }

  /// The session ran past its limit (#1738): stop it, call the nodes it was
  /// still working on failed, and wait for the rest like a session that ended.
  ///
  /// Stopped first, so the router's rows read afterwards cannot make the app
  /// wait on a node it has given up on: the interrupted ones are taken from the
  /// last read before `Stop()`, and [AddNodesState.interruptedNodes] keeps them
  /// failed whatever the router writes next.
  Future<void> _endAtLimit(int generation, _StartRun run) async {
    final interrupted = {
      for (final node in state.nodes)
        if (node.status == OnboardingNodeStatus.connecting ||
            node.status == OnboardingNodeStatus.onboarding)
          node.bleMacAddress,
    };
    await _stop(run);
    if (!_current(generation)) return;
    await _awaitJoin(
        generation, run.service, state.copyWith(interruptedNodes: interrupted));
  }

  /// Waits for the nodes that may still join to show in DataElements, then
  /// settles on a result screen chosen by every node's outcome (#1738).
  ///
  /// The phase stays [AddNodesPhase.joining] for the whole wait, with each
  /// node's outcome on the list, so the result is shown once rather than
  /// changing as nodes arrive. Each join still refreshes the topology as it
  /// happens: leaving mid-wait disposes this before the rest arrive.
  Future<void> _awaitJoin(
    int generation,
    AddNodesService service,
    AddNodesState ended,
  ) async {
    final timings = ref.read(addNodesTimingsProvider);
    final waiting = ended.copyWith(phase: AddNodesPhase.joining);
    _publish(generation, waiting);

    // The nodes worth looking for: joining through the wait, which needs an AL
    // MAC to be found by. outcomeOf decides which.
    final awaited = [
      for (final node in waiting.nodes)
        if (waiting.outcomeFor(node) == AddNodesNodeOutcome.joining &&
            node.alMacAddress != null)
          node.alMacAddress!,
    ];

    if (awaited.isNotEmpty) {
      final giveUpAt = clock.now().add(timings.joinLimit);
      final wanted = meshNodeMacSet(awaited);
      var joined = <String>{};
      var isFirstRead = true;

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
          logger.w('$_tag reading DataElements failed; reading again',
              error: e);
          continue;
        }
        if (!_current(generation)) return;

        // A union, not the latest read: a node seen once has joined, and
        // dropping out of one read — re-associating — does not undo that.
        final seen = joined.union(listed);
        if (seen.length > joined.length) {
          joined = seen;
          _publish(generation, state.copyWith(joinedNodeKeys: joined));
          // The devices provider keeps the topology it has across a device
          // refresh and re-reads DataElements behind it — but only on a Hosts
          // push, which can come before the node is in DataElements and so
          // leave it drawn as a client.
          unawaited(ref.read(devicesDataProvider.notifier).refetch());
        }
        if (joined.containsAll(wanted)) break;
      }
      if (!_current(generation)) return;
      if (!joined.containsAll(wanted)) {
        logger.w('$_tag ${wanted.difference(joined).length} node(s) did not '
            'appear in DataElements within ${timings.joinLimit}');
      }
    }

    final settled = state.copyWith(phase: AddNodesPhase.failed);
    final outcomes = settled.nodes.map(settled.outcomeFor).toList();
    final added = outcomes.where((o) => o == AddNodesNodeOutcome.added).length;
    // Taken at the session's word: onboarded with no AL MAC, so no read above
    // found it and none refreshed the topology to draw it.
    if (settled.nodes.any((n) =>
        n.alMacAddress == null &&
        settled.outcomeFor(n) == AddNodesNodeOutcome.added)) {
      unawaited(ref.read(devicesDataProvider.notifier).refetch());
    }
    _publish(
      generation,
      settled.copyWith(
        // No rows at all is no node added: a session that named none.
        phase: added == 0
            ? AddNodesPhase.failed
            : added == outcomes.length
                ? AddNodesPhase.joined
                : AddNodesPhase.partial,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stop
  // ---------------------------------------------------------------------------

  /// Stops the session this flow started. Safe to call when nothing runs.
  ///
  /// While `Start()` has not answered, nothing is sent yet. If it is still
  /// waiting for the mutation lock it is never sent at all. If it is on its way,
  /// the session is stopped once it answers `Started`, and left alone if it
  /// answers anything else, because then the running session — if any — is not
  /// this flow's.
  Future<void> cancel() async {
    final run = _run;
    if (!state.isRunning || run == null) return;
    final generation = ++_generation;
    _publish(generation, state.copyWith(phase: AddNodesPhase.cancelled));
    if (run.owns) {
      await _stop(run);
    } else {
      run.stopWhenStarted = true;
    }
  }

  /// `Stop()` under the lock, logged rather than thrown: the user asked to stop
  /// following the session, and a failed stop leaves it to end on its own.
  ///
  /// Uses what [run] captured, never `ref`: it also runs after the page has
  /// gone, for a `Start()` that answered after a cancel.
  Future<void> _stop(_StartRun run) async {
    run.owns = false;
    try {
      await run.lock.withLock(run.service.stop);
    } on ServiceError catch (e) {
      logger.w('$_tag Stop() failed', error: e);
    } on TimeoutException catch (e) {
      logger.w('$_tag Stop() did not answer in time: $e');
    }
  }

  /// The page went away with this flow's session running.
  void _stopOnLeave(_StartRun run) {
    logger.i('$_tag the page closed with a session running; stopping it');
    unawaited(_stop(run));
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

/// One `Start()` and what it leaves this flow responsible for.
///
/// Per call, not on the notifier: a Try again straight after a cancel sends a
/// second `Start()` while the first may not have answered, and each answer has to
/// find its own pending cancel.
///
/// Holds the service and lock as well, captured when the call is made, because a
/// `Stop()` can be sent after the page is gone — on leave, or for a `Start()`
/// that answered after a cancel — and reading a provider through `ref` once the
/// container is disposed throws.
class _StartRun {
  _StartRun(this.service, this.lock);

  final AddNodesService service;
  final UspMutationLock lock;

  /// Whether the router's running session is this run's: set when `Start()`
  /// answers `Started`, cleared once the session ends, another session replaces
  /// it, or this flow stops it.
  ///
  /// What gates every `Stop()`, rather than [AddNodesState.isRunning]. That
  /// counts [AddNodesPhase.starting] too, before `Start()` has answered — and if
  /// it answers `Busy`, the running session is someone else's, the pairing
  /// button's or another client's, which this flow must not stop.
  bool owns = false;

  /// The user cancelled, or left, before `Start()` answered. Read twice: in the
  /// lock, where a `Start()` not yet sent is not sent, and on the answer, where a
  /// `Started` is stopped at once. Any other answer started nothing.
  bool stopWhenStarted = false;
}
