import 'dart:async';

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
    Duration sessionLimit = const Duration(seconds: 2),
    Duration joinLimit = const Duration(milliseconds: 200),
  }) {
    final container = ProviderContainer(overrides: [
      addNodesServiceProvider.overrideWithValue(service),
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      addNodesTimingsProvider.overrideWithValue(AddNodesTimings(
        pollInterval: const Duration(milliseconds: 1),
        sessionLimit: sessionLimit,
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
      Duration sessionLimit = const Duration(seconds: 2),
      Duration joinLimit = const Duration(milliseconds: 200),
    }) async {
      feedSessions([_idle]);
      final container =
          createContainer(sessionLimit: sessionLimit, joinLimit: joinLimit);
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
      expect(phases, [
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
          await readyContainer(sessionLimit: const Duration(milliseconds: 30));
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
      expect(state.error, isA<TimeoutError>());
      verify(() => service.stop()).called(1);
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
