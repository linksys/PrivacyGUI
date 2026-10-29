import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_notifier.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/add_nodes/services/add_nodes_service.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

class MockAddNodesService extends Mock implements AddNodesService {}

/// Records the refreshes the flow asks of the topology, and does nothing else.
class _RecordingDevicesDataNotifier extends DevicesDataNotifier {
  int refetches = 0;

  @override
  Future<DevicesData> build() async => DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(
            deviceId: 'GATEWAY',
            model: 'M60',
            manufacturer: 'Linksys',
            serialNumber: 'SN',
            softwareVersion: '2.0.3',
            connectedClients: [],
          ),
          slaves: [],
        ),
      );

  @override
  Future<void> refetch() async => refetches++;
}

const _alMac = 'aa:bb:cc:00:00:02';
const _alMacKey = 'AABBCC000002';

/// Sessions as the router reports them. Each is one read of the status object.
OnboardingSessionUIModel _session({
  OnboardingSessionStatus status = OnboardingSessionStatus.idle,
  OnboardingSessionResult result = OnboardingSessionResult.none,
  int session = 0,
  List<AddNodesNodeUIModel> nodes = const [],
}) =>
    OnboardingSessionUIModel(
      status: status,
      result: result,
      session: session,
      nodes: nodes,
    );

AddNodesNodeUIModel _node({
  OnboardingNodeStatus status = OnboardingNodeStatus.onboarded,
  String? alMac = _alMac,
}) =>
    AddNodesNodeUIModel(
      bleMacAddress: 'AA:BB:CC:00:00:01',
      status: status,
      modelNumber: 'M60',
      rssi: -40,
      alMacAddress: alMac,
    );

/// The [i]th of several distinct nodes, for sessions with more than one.
/// Its AL MAC's normalized key is [_keyN].
AddNodesNodeUIModel _nodeN(int i,
        {OnboardingNodeStatus status = OnboardingNodeStatus.onboarded}) =>
    AddNodesNodeUIModel(
      bleMacAddress: 'AA:BB:CC:00:01:0$i',
      status: status,
      modelNumber: 'M60',
      alMacAddress: 'aa:bb:cc:00:02:0$i',
    );

String _keyN(int i) => 'AABBCC00020$i';

const _idle = OnboardingSessionUIModel(
  status: OnboardingSessionStatus.idle,
  result: OnboardingSessionResult.none,
  session: 0,
);

void main() {
  late MockAddNodesService service;
  late _RecordingDevicesDataNotifier devices;

  setUp(() {
    service = MockAddNodesService();
    devices = _RecordingDevicesDataNotifier();
    when(() => service.stop()).thenAnswer((_) async {});
  });

  /// A container whose waits are a millisecond, so a test runs the real loops
  /// without sitting through them.
  ProviderContainer createContainer({
    Duration perNodeLimit = const Duration(seconds: 2),
    Duration joinLimit = const Duration(milliseconds: 200),
  }) {
    final container = ProviderContainer(overrides: [
      addNodesServiceProvider.overrideWithValue(service),
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      addNodesTimingsProvider.overrideWithValue(AddNodesTimings(
        pollInterval: const Duration(milliseconds: 1),
        perNodeLimit: perNodeLimit,
        joinLimit: joinLimit,
      )),
      devicesDataProvider.overrideWith(() => devices),
    ]);
    // Keep the autoDispose notifier alive across awaits.
    container.listen(addNodesProvider, (_, __) {});
    addTearDown(container.dispose);
    return container;
  }

  /// The session reads, one per call, the last one repeating.
  void feedSessions(List<OnboardingSessionUIModel> reads) {
    var i = 0;
    when(() => service.fetchSession()).thenAnswer((_) async {
      final read = reads[i < reads.length ? i : reads.length - 1];
      i++;
      return read;
    });
  }

  /// Waits until the flow reaches [phase] or the wait runs out.
  Future<AddNodesState> settleOn(
    ProviderContainer container,
    AddNodesPhase phase, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (container.read(addNodesProvider).phase != phase) {
      if (DateTime.now().isAfter(deadline)) {
        fail('the flow never reached ${phase.name}; it is '
            '${container.read(addNodesProvider).phase.name}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    return container.read(addNodesProvider);
  }

  group('AddNodesNotifier - entry', () {
    test('an idle router that never ran a session is ready', () async {
      feedSessions([_idle]);
      final container = createContainer();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.checking);
      await settleOn(container, AddNodesPhase.ready);
    });

    test('a finished session from earlier is ready, not busy', () async {
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 900),
      ]);
      final container = createContainer();

      await settleOn(container, AddNodesPhase.ready);
    });

    test('a session someone else started is busy before anything is offered',
        () async {
      // The pairing button pressed on the controller.
      feedSessions([
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 900),
      ]);
      final container = createContainer();

      final state = await settleOn(container, AddNodesPhase.busy);
      expect(state.canStart, isFalse);
    });

    test('a router that cannot run a session is unavailable', () async {
      for (final result in [
        OnboardingSessionResult.backendUnavailable,
        OnboardingSessionResult.unsupportedRole,
      ]) {
        feedSessions([_session(result: result)]);
        final container = createContainer();

        await settleOn(container, AddNodesPhase.unavailable);
        container.dispose();
      }
    });

    test('a failed read on entry keeps the error to show', () async {
      when(() => service.fetchSession()).thenThrow(const ConnectivityError());
      final container = createContainer();

      final state = await settleOn(container, AddNodesPhase.loadFailed);
      expect(state.error, isA<ConnectivityError>());
    });

    test('recheck reads the router again', () async {
      feedSessions([
        _session(
            status: OnboardingSessionStatus.onboarding,
            result: OnboardingSessionResult.started,
            session: 900),
        _idle,
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.busy);

      await container.read(addNodesProvider.notifier).recheck();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.ready);
    });
  });

  group('AddNodesNotifier - start', () {
    Future<ProviderContainer> readyContainer({
      Duration perNodeLimit = const Duration(seconds: 2),
      Duration joinLimit = const Duration(milliseconds: 200),
    }) async {
      feedSessions([_idle]);
      final container =
          createContainer(perNodeLimit: perNodeLimit, joinLimit: joinLimit);
      await settleOn(container, AddNodesPhase.ready);
      return container;
    }

    test('busy on Start() means another session got there first', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.busy);

      await container.read(addNodesProvider.notifier).start();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.busy);
    });

    test('a router that refuses Start() is unavailable', () async {
      for (final refusal in [
        OnboardingStartResult.unsupportedRole,
        OnboardingStartResult.backendUnavailable,
      ]) {
        final container = await readyContainer();
        when(() => service.start()).thenAnswer((_) async => refusal);

        await container.read(addNodesProvider.notifier).start();

        expect(
            container.read(addNodesProvider).phase, AddNodesPhase.unavailable,
            reason: refusal.name);
        container.dispose();
      }
    });

    test('a failed Start() keeps the error and lets the user try again',
        () async {
      final container = await readyContainer();
      when(() => service.start()).thenThrow(const UnexpectedError());

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.error, isA<UnexpectedError>());
      expect(state.canStart, isTrue);
    });

    test('a session is followed through its phases to a joined node', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      final phases = <AddNodesPhase>[];
      container.listen(addNodesProvider, (_, next) => phases.add(next.phase));
      feedSessions([
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
        _session(
            status: OnboardingSessionStatus.onboarding,
            result: OnboardingSessionResult.started,
            session: 1450,
            nodes: [_node(status: OnboardingNodeStatus.onboarding)]),
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [_node()]),
      ]);
      // Listed with its parent on the second read, as a node is a few seconds
      // after the session ends.
      var joinReads = 0;
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => ++joinReads < 2 ? <String>{} : {_alMacKey});

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.joined);
      expect(state.joinedNodeKeys, {_alMacKey});
      expect(state.sessionResult, OnboardingSessionResult.success);
      // The phases walked, in order. A join publishes new joinedNodeKeys in the
      // same joining phase (#1738), which the listener sees as a second entry.
      final walked = [
        for (var i = 0; i < phases.length; i++)
          if (i == 0 || phases[i] != phases[i - 1]) phases[i],
      ];
      expect(walked, [
        AddNodesPhase.starting,
        AddNodesPhase.searching,
        AddNodesPhase.onboarding,
        AddNodesPhase.joining,
        AddNodesPhase.joined,
      ]);
      verify(() => service.fetchJoinedNodes([_alMac])).called(2);
      expect(devices.refetches, 1,
          reason: 'a Hosts push can draw the new node as a client before it '
              'is in DataElements; the flow reads the topology again');
    });

    test('a session that found nothing says so', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.noDevicesFound,
            session: 1450),
      ]);

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.noNodesFound);
      expect(state.canStart, isTrue);
      verifyNever(() => service.fetchJoinedNodes(any()));
    });

    test('a session that failed with no node to wait for is failed', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.failed,
            session: 1450,
            nodes: [
              _node(status: OnboardingNodeStatus.failedConnect, alMac: null)
            ]),
      ]);

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.sessionResult, OnboardingSessionResult.failed);
      expect(state.error, isNull);
      verifyNever(() => service.fetchJoinedNodes(any()));
    });

    test('a node the session timed out on is still waited for', () async {
      // The firmware corrects a late joiner to onboarded, and DataElements can
      // list it first.
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.timedOut,
            session: 1450,
            nodes: [_node(status: OnboardingNodeStatus.failedWps)]),
      ]);
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => {_alMacKey});

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.joined);
      expect(state.sessionResult, OnboardingSessionResult.timedOut);
    });

    test('a node that never appears is failed once the wait runs out',
        () async {
      final container =
          await readyContainer(joinLimit: const Duration(milliseconds: 30));
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [_node()]),
      ]);
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => <String>{});

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.sessionResult, OnboardingSessionResult.success,
          reason: 'the page can then say the node may still come online, '
              'rather than that adding it failed');
      expect(devices.refetches, 0);
    });

    test('onboarded with no AL MAC takes the session at its word', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [_node(alMac: null)]),
      ]);

      await container.read(addNodesProvider.notifier).start();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.joined);
      verifyNever(() => service.fetchJoinedNodes(any()));
      expect(devices.refetches, 1);
    });

    test('a node seen once stays joined when a later read misses it', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      const second = 'aa:bb:cc:00:00:04';
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [
              _node(),
              const AddNodesNodeUIModel(
                bleMacAddress: 'AA:BB:CC:00:00:03',
                status: OnboardingNodeStatus.onboarded,
                alMacAddress: second,
              ),
            ]),
      ]);
      // The first node shows, drops out while re-associating, and the second
      // shows after it.
      final reads = <Set<String>>[
        {_alMacKey},
        <String>{},
        {'AABBCC000004'},
      ];
      var i = 0;
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => reads[i < reads.length ? i++ : 2]);

      await container.read(addNodesProvider.notifier).start();

      expect(container.read(addNodesProvider).joinedNodeKeys,
          {_alMacKey, 'AABBCC000004'});
    });

    test('a read that fails mid-session is read again', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      var reads = 0;
      when(() => service.fetchSession()).thenAnswer((_) async {
        reads++;
        if (reads == 1) throw const NetworkError();
        return _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.noDevicesFound,
            session: 1450);
      });

      await container.read(addNodesProvider.notifier).start();

      expect(
          container.read(addNodesProvider).phase, AddNodesPhase.noNodesFound);
    });

    // usp-codegen 0.19.0: a row missing a required leaf fails the whole read
    // with 9998, which the service maps to InvalidInputError. Firmware that
    // drops a leaf drops it on every read, so these pin what a *persistent* one
    // does to each of the three reads. The notifier never looks inside the
    // error, so one value stands for either model's: BleOnboarding's node rows
    // or DataElementsNetwork's child rows.
    const missingLeaf = InvalidInputError(
        code: 9998, detail: 'Required fields missing from response');

    test('a missing leaf on entry shows the read as failed', () async {
      // The same path as any failed entry read (see "a failed read on entry
      // keeps the error to show"): the entry read handles every ServiceError
      // alike. Kept to record that a 9998 lands there too, with its code.
      when(() => service.fetchSession()).thenThrow(missingLeaf);
      final container = createContainer();

      final state = await settleOn(container, AddNodesPhase.loadFailed);

      expect(state.error, missingLeaf);
    });

    test('a missing leaf while following keeps reading until the limit',
        () async {
      final container =
          await readyContainer(perNodeLimit: const Duration(milliseconds: 30));
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      when(() => service.fetchSession()).thenThrow(missingLeaf);
      // Count only the reads that follow the session, not the one on entry.
      clearInteractions(service);

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.error, isNull,
          reason:
              'the read error is retried as transient, and the page ends on '
              'the session limit with each node\'s outcome, not on an error '
              '(#1738)');
      expect(verify(() => service.fetchSession()).callCount, greaterThan(1),
          reason: 'it read again rather than failing on the first error');
      verify(() => service.stop()).called(1);
    });

    test(
        'a missing leaf while waiting for the node keeps reading until the '
        'join limit', () async {
      final container =
          await readyContainer(joinLimit: const Duration(milliseconds: 30));
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [_node()]),
      ]);
      when(() => service.fetchJoinedNodes(any())).thenThrow(missingLeaf);

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.error, isNull,
          reason: 'the page shows troubleshooting steps, not the read error');
      // Without this the test cannot tell "read again until the limit" from
      // "gave up on the first error": both end failed, with no error.
      expect(verify(() => service.fetchJoinedNodes(any())).callCount,
          greaterThan(1),
          reason: 'it read again rather than failing on the first error');
    });

    test('a session that partly succeeded waits for its onboarded node',
        () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.partial,
            session: 1450,
            nodes: [
              _node(),
              _node(status: OnboardingNodeStatus.failedConnect, alMac: null),
            ]),
      ]);
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => {_alMacKey});

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      // One joined and one failed to connect: some, not all (#1738).
      expect(state.phase, AddNodesPhase.partial);
      expect(state.sessionResult, OnboardingSessionResult.partial);
      // Only the node that reached the backhaul is waited for; the one the
      // controller never connected to has no AL MAC to look for.
      verify(() => service.fetchJoinedNodes([_alMac])).called(1);
    });

    test('a session that partly succeeded with no AL MAC takes its word',
        () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.partial,
            session: 1450,
            nodes: [
              _node(alMac: null),
              _node(status: OnboardingNodeStatus.failedConnect, alMac: null),
            ]),
      ]);

      await container.read(addNodesProvider.notifier).start();

      // Onboarded on the session's word, the other failed to connect.
      expect(container.read(addNodesProvider).phase, AddNodesPhase.partial);
      verifyNever(() => service.fetchJoinedNodes(any()));
      expect(devices.refetches, 1);
    });

    test('each node that joins refreshes the topology, not the last one only',
        () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      const second = 'aa:bb:cc:00:00:04';
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [
              _node(),
              const AddNodesNodeUIModel(
                bleMacAddress: 'AA:BB:CC:00:00:03',
                status: OnboardingNodeStatus.onboarded,
                alMacAddress: second,
              ),
            ]),
      ]);
      // The first node is listed straight away, the second never within the
      // wait. The phase stays joining throughout (#1738), and leaving disposes
      // the flow before the second can arrive.
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => {_alMacKey});

      unawaited(container.read(addNodesProvider.notifier).start());
      await settleOn(container, AddNodesPhase.joining);
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (container.read(addNodesProvider).joinedNodeKeys.isEmpty) {
        if (DateTime.now().isAfter(deadline)) fail('no node ever joined');
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      expect(container.read(addNodesProvider).phase, AddNodesPhase.joining);
      expect(devices.refetches, 1,
          reason: 'refreshed on the first join, while the page still waits');
    });

    test('a second node that joins later refreshes the topology again',
        () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      const second = 'aa:bb:cc:00:00:04';
      feedSessions([
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [
              _node(),
              const AddNodesNodeUIModel(
                bleMacAddress: 'AA:BB:CC:00:00:03',
                status: OnboardingNodeStatus.onboarded,
                alMacAddress: second,
              ),
            ]),
      ]);
      final reads = <Set<String>>[
        {_alMacKey},
        {_alMacKey},
        {_alMacKey, 'AABBCC000004'},
      ];
      var i = 0;
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => reads[i < reads.length ? i++ : 2]);

      await container.read(addNodesProvider.notifier).start();

      expect(container.read(addNodesProvider).joinedNodeKeys,
          {_alMacKey, 'AABBCC000004'});
      expect(devices.refetches, 2,
          reason: 'one per join; a read that adds nobody refreshes nothing');
    });

    test('a session counter that moves means someone else took over', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
        // The pairing button, pressed after ours ended and a new one began.
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1600),
      ]);

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.sessionResult, isNull);
      verifyNever(() => service.stop());
    });

    test('a session stopped elsewhere is cancelled', () async {
      final container = await readyContainer();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.cancelled,
            session: 1450),
      ]);

      await container.read(addNodesProvider.notifier).start();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.cancelled);
    });

    test('a session that never ends is stopped at the limit', () async {
      final container =
          await readyContainer(perNodeLimit: const Duration(milliseconds: 30));
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      feedSessions([
        _session(
            status: OnboardingSessionStatus.onboarding,
            result: OnboardingSessionResult.started,
            session: 1450),
      ]);

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.error, isNull,
          reason: 'the outcomes say what happened; "timed out" no longer does '
              '(#1738)');
      verify(() => service.stop()).called(1);
    });

    group('the session limit, per node found (#1738)', () {
      test(
          'grows with the nodes found, so three nodes are not cut off at one '
          'node\'s limit', () async {
        // 40 ms per node: three found makes 120 ms. The session ends at about
        // 60 ms, past one node's limit and inside three's.
        final container = await readyContainer(
            perNodeLimit: const Duration(milliseconds: 40));
        when(() => service.start())
            .thenAnswer((_) async => OnboardingStartResult.started);
        final onboarding = _session(
            status: OnboardingSessionStatus.onboarding,
            result: OnboardingSessionResult.started,
            session: 1450,
            nodes: [
              _nodeN(1, status: OnboardingNodeStatus.onboarding),
              _nodeN(2, status: OnboardingNodeStatus.pending),
              _nodeN(3, status: OnboardingNodeStatus.pending),
            ]);
        final ended = clock.now().add(const Duration(milliseconds: 60));
        when(() => service.fetchSession()).thenAnswer((_) async =>
            clock.now().isBefore(ended)
                ? onboarding
                : _session(
                    status: OnboardingSessionStatus.complete,
                    result: OnboardingSessionResult.success,
                    session: 1450,
                    nodes: [_nodeN(1), _nodeN(2), _nodeN(3)]));
        when(() => service.fetchJoinedNodes(any()))
            .thenAnswer((_) async => {_keyN(1), _keyN(2), _keyN(3)});

        await container.read(addNodesProvider.notifier).start();

        expect(container.read(addNodesProvider).phase, AddNodesPhase.joined);
        verifyNever(() => service.stop());
      });

      test(
          'at the limit, stops the session and waits for the nodes that may '
          'still join, rather than failing them all', () async {
        final container = await readyContainer(
            perNodeLimit: const Duration(milliseconds: 30));
        when(() => service.start())
            .thenAnswer((_) async => OnboardingStartResult.started);
        // Never ends on its own: one onboarded, one still onboarding, one not
        // reached.
        feedSessions([
          _session(
              status: OnboardingSessionStatus.onboarding,
              result: OnboardingSessionResult.started,
              session: 1450,
              nodes: [
                _nodeN(1),
                _nodeN(2, status: OnboardingNodeStatus.onboarding),
                _nodeN(3, status: OnboardingNodeStatus.pending),
              ]),
        ]);
        when(() => service.fetchJoinedNodes(any()))
            .thenAnswer((_) async => {_keyN(1)});

        await container.read(addNodesProvider.notifier).start();

        final state = container.read(addNodesProvider);
        verify(() => service.stop()).called(1);
        expect(state.phase, AddNodesPhase.partial,
            reason: 'the onboarded node joined, so not all of them failed');
        expect(state.nodes.map(state.outcomeFor).toList(), [
          AddNodesNodeOutcome.added,
          AddNodesNodeOutcome.failed,
          AddNodesNodeOutcome.notTried,
        ]);
        expect(state.interruptedNodes, {_nodeN(2).bleMacAddress});
      });

      test(
          'a node stopped at the limit stays failed, whatever the router '
          'writes after Stop()', () async {
        final container = await readyContainer(
            perNodeLimit: const Duration(milliseconds: 30));
        when(() => service.start())
            .thenAnswer((_) async => OnboardingStartResult.started);
        feedSessions([
          _session(
              status: OnboardingSessionStatus.onboarding,
              result: OnboardingSessionResult.started,
              session: 1450,
              nodes: [_nodeN(1, status: OnboardingNodeStatus.onboarding)]),
        ]);
        when(() => service.fetchJoinedNodes(any()))
            .thenAnswer((_) async => <String>{});

        await container.read(addNodesProvider.notifier).start();

        final state = container.read(addNodesProvider);
        expect(state.phase, AddNodesPhase.failed);
        expect(
            state.outcomeFor(state.nodes.single), AddNodesNodeOutcome.failed);
        verifyNever(() => service.fetchJoinedNodes(any()));
      });
    });

    group('the result, by every node\'s outcome (#1738)', () {
      Future<AddNodesState> endWith(List<AddNodesNodeUIModel> nodes,
          {Set<String> listed = const {},
          OnboardingSessionResult result =
              OnboardingSessionResult.partial}) async {
        final container = await readyContainer();
        when(() => service.start())
            .thenAnswer((_) async => OnboardingStartResult.started);
        feedSessions([
          _session(
              status: OnboardingSessionStatus.complete,
              result: result,
              session: 1450,
              nodes: nodes),
        ]);
        when(() => service.fetchJoinedNodes(any()))
            .thenAnswer((_) async => listed);
        await container.read(addNodesProvider.notifier).start();
        return container.read(addNodesProvider);
      }

      test('all added is joined', () async {
        final state = await endWith([_nodeN(1), _nodeN(2)],
            listed: {_keyN(1), _keyN(2)},
            result: OnboardingSessionResult.success);
        expect(state.phase, AddNodesPhase.joined);
      });

      test('some added and one never reached is partial: it can be tried again',
          () async {
        final state = await endWith(
            [_nodeN(1), _nodeN(2, status: OnboardingNodeStatus.pending)],
            listed: {_keyN(1)});
        expect(state.phase, AddNodesPhase.partial);
        expect(state.canStart, isTrue);
      });

      test('none added is failed, with each node\'s reason on it', () async {
        final state = await endWith([
          _nodeN(1, status: OnboardingNodeStatus.failedConnect),
          _nodeN(2, status: OnboardingNodeStatus.failedWps),
        ], result: OnboardingSessionResult.failed);
        expect(state.phase, AddNodesPhase.failed);
        expect(state.error, isNull);
        expect(state.nodes.map(state.outcomeFor),
            everyElement(AddNodesNodeOutcome.failed));
      });

      test('stays joining through the wait, so the result is shown once',
          () async {
        final container =
            await readyContainer(joinLimit: const Duration(milliseconds: 200));
        when(() => service.start())
            .thenAnswer((_) async => OnboardingStartResult.started);
        feedSessions([
          _session(
              status: OnboardingSessionStatus.complete,
              result: OnboardingSessionResult.success,
              session: 1450,
              nodes: [_nodeN(1), _nodeN(2)]),
        ]);
        // The first appears at once, the second only on the fourth read.
        var reads = 0;
        when(() => service.fetchJoinedNodes(any())).thenAnswer(
            (_) async => ++reads < 4 ? {_keyN(1)} : {_keyN(1), _keyN(2)});
        final phases = <AddNodesPhase>[];
        container.listen(addNodesProvider, (_, next) => phases.add(next.phase));

        await container.read(addNodesProvider.notifier).start();

        expect(phases.where((p) => p == AddNodesPhase.joined), hasLength(1),
            reason: 'one result, published once at the end');
        expect(phases.last, AddNodesPhase.joined);
        expect(phases.indexOf(AddNodesPhase.joined),
            greaterThan(phases.lastIndexOf(AddNodesPhase.joining)),
            reason: 'never joined before the wait was over');
      });
    });

    test('start does nothing while a session is running', () async {
      final container = await readyContainer();
      final gate = Completer<OnboardingStartResult>();
      when(() => service.start()).thenAnswer((_) => gate.future);

      unawaited(container.read(addNodesProvider.notifier).start());
      await Future<void>.delayed(Duration.zero);
      await container.read(addNodesProvider.notifier).start();

      verify(() => service.start()).called(1);
      gate.complete(OnboardingStartResult.busy);
    });

    test('no service to start with is failed, not thrown', () async {
      feedSessions([_idle]);
      // Defensive, to match the entry read: in the app this does not happen.
      // The service provider reads the USP client once and keeps it, and the
      // entry read has already built it by the time Start can be pressed. The
      // override below rebuilds it on demand, which only a test can do.
      final available = StateProvider<bool>((ref) => true);
      final container = ProviderContainer(overrides: [
        addNodesServiceProvider.overrideWith((ref) {
          if (!ref.watch(available)) throw const ServiceNotInitializedError();
          return service;
        }),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ]);
      addTearDown(container.dispose);
      container.listen(addNodesProvider, (_, __) {});
      await settleOn(container, AddNodesPhase.ready);
      container.read(available.notifier).state = false;

      await container.read(addNodesProvider.notifier).start();

      final state = container.read(addNodesProvider);
      expect(state.phase, AddNodesPhase.failed);
      expect(state.error, isA<ServiceNotInitializedError>());
      verifyNever(() => service.start());
    });
  });

  group('AddNodesNotifier - stop', () {
    test('cancel stops the running session', () async {
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);

      unawaited(container.read(addNodesProvider.notifier).start());
      await settleOn(container, AddNodesPhase.searching);
      await container.read(addNodesProvider.notifier).cancel();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.cancelled);
      verify(() => service.stop()).called(1);
    });

    test('a stopped session can be started again', () async {
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      unawaited(container.read(addNodesProvider.notifier).start());
      await settleOn(container, AddNodesPhase.searching);
      await container.read(addNodesProvider.notifier).cancel();
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.busy);

      // The page's Try again after a stop.
      await container.read(addNodesProvider.notifier).start();

      verify(() => service.start()).called(2);
      expect(container.read(addNodesProvider).phase, AddNodesPhase.busy);
    });

    group('before Start() has answered', () {
      /// A flow in [AddNodesPhase.starting], its `Start()` held until [answer].
      Future<(ProviderContainer, Completer<OnboardingStartResult>)>
          startingContainer() async {
        feedSessions([
          _idle,
          _session(
              status: OnboardingSessionStatus.scanning,
              result: OnboardingSessionResult.started,
              session: 1450),
        ]);
        final container = createContainer();
        await settleOn(container, AddNodesPhase.ready);
        final answer = Completer<OnboardingStartResult>();
        when(() => service.start()).thenAnswer((_) => answer.future);
        unawaited(container.read(addNodesProvider.notifier).start());
        await settleOn(container, AddNodesPhase.starting);
        return (container, answer);
      }

      test('a cancel then Busy stops nothing: the session is not ours',
          () async {
        final (container, answer) = await startingContainer();

        await container.read(addNodesProvider.notifier).cancel();
        answer.complete(OnboardingStartResult.busy);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(container.read(addNodesProvider).phase, AddNodesPhase.cancelled);
        verifyNever(() => service.stop());
      });

      test('a cancel then Started stops the session once, and follows nothing',
          () async {
        final (container, answer) = await startingContainer();

        await container.read(addNodesProvider.notifier).cancel();
        verifyNever(() => service.stop());
        answer.complete(OnboardingStartResult.started);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(container.read(addNodesProvider).phase, AddNodesPhase.cancelled);
        verify(() => service.stop()).called(1);
        // Entry read only: the cancelled run never polled its session.
        verify(() => service.fetchSession()).called(1);
      });

      test('leaving then Busy stops nothing', () async {
        final (container, answer) = await startingContainer();

        container.dispose();
        answer.complete(OnboardingStartResult.busy);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        verifyNever(() => service.stop());
      });

      test('leaving then Started stops the session', () async {
        final (container, answer) = await startingContainer();

        container.dispose();
        answer.complete(OnboardingStartResult.started);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        verify(() => service.stop()).called(1);
      });

      test('Try again after a cancel leaves the first answer its own cancel',
          () async {
        final (container, first) = await startingContainer();
        await container.read(addNodesProvider.notifier).cancel();
        final second = Completer<OnboardingStartResult>();
        when(() => service.start()).thenAnswer((_) => second.future);

        // Try again before the first Start() has answered. The page offers it
        // from cancelled.
        unawaited(container.read(addNodesProvider.notifier).start());
        await settleOn(container, AddNodesPhase.starting);
        first.complete(OnboardingStartResult.started);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        verify(() => service.stop()).called(1);
        expect(container.read(addNodesProvider).phase, AddNodesPhase.starting,
            reason: 'the first answer stopped its own session and published '
                'nothing over the run that replaced it');

        second.complete(OnboardingStartResult.busy);
        await settleOn(container, AddNodesPhase.busy);
        verifyNever(() => service.stop());
      });

      test('Try again that starts a session is followed, not stopped',
          () async {
        // The case the router produces: the first session is stopped by the
        // time the second Start() runs, so the second answers Started.
        final (container, first) = await startingContainer();
        await container.read(addNodesProvider.notifier).cancel();
        final second = Completer<OnboardingStartResult>();
        final sent = <String>[];
        when(() => service.start()).thenAnswer((_) {
          sent.add('start');
          return second.future;
        });
        when(() => service.stop()).thenAnswer((_) async => sent.add('stop'));
        unawaited(container.read(addNodesProvider.notifier).start());
        await settleOn(container, AddNodesPhase.starting);
        first.complete(OnboardingStartResult.started);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        second.complete(OnboardingStartResult.started);
        await settleOn(container, AddNodesPhase.searching);

        // The first run's held stop goes out before the second Start(), both
        // waiting on the one lock in the order they queued. Reversed, the second
        // Start() would answer Busy against a session about to be stopped, and
        // that stop would then end the second run's session.
        expect(sent, ['stop', 'start']);
        // And the session is the second run's to stop now.
        await container.read(addNodesProvider.notifier).cancel();
        expect(sent, ['stop', 'start', 'stop']);
      });

      test('a cancel while Start() waits for the lock sends nothing', () async {
        feedSessions([_idle]);
        final lock = UspMutationLock();
        final container = ProviderContainer(overrides: [
          addNodesServiceProvider.overrideWithValue(service),
          uspMutationLockProvider.overrideWithValue(lock),
          addNodesTimingsProvider.overrideWithValue(
              const AddNodesTimings(pollInterval: Duration(milliseconds: 1))),
          devicesDataProvider.overrideWith(() => devices),
        ]);
        addTearDown(container.dispose);
        container.listen(addNodesProvider, (_, __) {});
        await settleOn(container, AddNodesPhase.ready);
        when(() => service.start())
            .thenAnswer((_) async => OnboardingStartResult.started);
        // Another write holds the lock, so Start() queues behind it.
        final otherWrite = Completer<void>();
        unawaited(lock.withLock(() => otherWrite.future));

        unawaited(container.read(addNodesProvider.notifier).start());
        await settleOn(container, AddNodesPhase.starting);
        await container.read(addNodesProvider.notifier).cancel();
        otherWrite.complete();
        await Future<void>.delayed(const Duration(milliseconds: 5));

        verifyNever(() => service.start());
        verifyNever(() => service.stop());
        expect(container.read(addNodesProvider).phase, AddNodesPhase.cancelled);
      });
    });

    test('leaving while the new node joins sends no stop', () async {
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.complete,
            result: OnboardingSessionResult.success,
            session: 1450,
            nodes: [_node()]),
      ]);
      final container = createContainer(joinLimit: const Duration(seconds: 2));
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      when(() => service.fetchJoinedNodes(any()))
          .thenAnswer((_) async => <String>{});
      unawaited(container.read(addNodesProvider.notifier).start());
      await settleOn(container, AddNodesPhase.joining);

      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      verifyNever(() => service.stop());
    });

    test('leaving after another session took over ours sends no stop',
        () async {
      // The one that matters: the running session is the other one.
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1600),
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      await container.read(addNodesProvider.notifier).start();
      expect(container.read(addNodesProvider).phase, AddNodesPhase.failed);

      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      verifyNever(() => service.stop());
    });

    test('leaving after a session stopped elsewhere sends no stop', () async {
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
        _session(
            status: OnboardingSessionStatus.idle,
            result: OnboardingSessionResult.cancelled,
            session: 1450),
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      await container.read(addNodesProvider.notifier).start();
      expect(container.read(addNodesProvider).phase, AddNodesPhase.cancelled);

      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      verifyNever(() => service.stop());
    });

    test('leaving right after a cancel sends the one stop, not a second',
        () async {
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      unawaited(container.read(addNodesProvider.notifier).start());
      await settleOn(container, AddNodesPhase.searching);

      // The page's Cancel, then the back button before Stop() has answered.
      unawaited(container.read(addNodesProvider.notifier).cancel());
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      verify(() => service.stop()).called(1);
    });

    test('cancel does nothing when no session is running', () async {
      feedSessions([_idle]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);

      await container.read(addNodesProvider.notifier).cancel();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.ready);
      verifyNever(() => service.stop());
    });

    test('leaving the page mid-session stops it', () async {
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.onboarding,
            result: OnboardingSessionResult.started,
            session: 1450),
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      unawaited(container.read(addNodesProvider.notifier).start());
      await settleOn(container, AddNodesPhase.onboarding);

      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      verify(() => service.stop()).called(1);
    });

    test('leaving the page after the session ended sends no stop', () async {
      feedSessions([_idle]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);

      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      verifyNever(() => service.stop());
    });

    test('a failed stop is logged, not thrown', () async {
      feedSessions([
        _idle,
        _session(
            status: OnboardingSessionStatus.scanning,
            result: OnboardingSessionResult.started,
            session: 1450),
      ]);
      final container = createContainer();
      await settleOn(container, AddNodesPhase.ready);
      when(() => service.start())
          .thenAnswer((_) async => OnboardingStartResult.started);
      when(() => service.stop()).thenThrow(const UnexpectedError());
      unawaited(container.read(addNodesProvider.notifier).start());
      await settleOn(container, AddNodesPhase.searching);

      await container.read(addNodesProvider.notifier).cancel();

      expect(container.read(addNodesProvider).phase, AddNodesPhase.cancelled);
    });
  });
}
