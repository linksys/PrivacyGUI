import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_action_notifier.dart';
import 'package:privacy_gui/page/topology/services/usp_node_action_service.dart';

import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/devices_test_data.dart';

class MockUspNodeActionService extends Mock implements UspNodeActionService {}

/// Counts every acquisition, so a test can tell one lock per node from one
/// lock around the whole sequence.
class CountingMutationLock extends UspMutationLock {
  int acquisitions = 0;

  @override
  Future<T> withLock<T>(
    Future<T> Function() action, {
    Duration timeout = UspMutationLock.defaultTimeout,
  }) {
    acquisitions++;
    return super.withLock(action, timeout: timeout);
  }
}

void main() {
  const near = 'AA:BB:CC:DD:EE:0A';
  const far = 'AA:BB:CC:DD:EE:0B';

  late MockUspNodeActionService mockService;
  late CountingMutationLock lock;

  SlaveNode slave(String mac, String parent) => DevicesTestData.createWifiSlave(
        deviceId: mac,
        dataElementsId: mac,
        backhaul: BackhaulInfo(linkType: 'Wi-Fi', parentNodeId: parent),
      );

  // The daisy chain #876's acceptance criteria name: controller → near → far.
  final chain = MeshNetwork(
    master: DevicesTestData.createMaster(),
    slaves: [slave(near, DevicesTestData.masterMac), slave(far, near)],
  );

  setUpAll(() => registerFallbackValue(NodeAction.reboot));

  setUp(() {
    mockService = MockUspNodeActionService();
    lock = CountingMutationLock();
    when(() => mockService.run(any(), any())).thenAnswer((_) async {});
  });

  Future<ProviderContainer> container({
    MeshNetwork? network,
    List<Override> extra = const [],
  }) async {
    final c = ProviderContainer(overrides: [
      uspNodeActionServiceProvider.overrideWithValue(mockService),
      uspMutationLockProvider.overrideWithValue(lock),
      devicesDataProvider.overrideWith(() =>
          FixedDevicesDataNotifierForTopology(
              DevicesData(meshNetwork: network ?? chain))),
      ...extra,
    ]);
    addTearDown(c.dispose);
    await c.read(devicesDataProvider.future);
    return c;
  }

  group('NodeActionNotifier - run', () {
    test('a node with nothing behind it gets one call', () async {
      final c = await container();

      final sent = await c.read(nodeActionProvider.notifier).run(
            NodeAction.reboot,
            far,
          );

      expect(sent, [far]);
      verify(() => mockService.run(NodeAction.reboot, far)).called(1);
    });

    test('the nodes behind the target go first, one lock each', () async {
      final c = await container();
      final order = <String>[];
      when(() => mockService.run(any(), any())).thenAnswer((inv) async {
        order.add(inv.positionalArguments[1] as String);
      });

      await c.read(nodeActionProvider.notifier).run(
            NodeAction.factoryReset,
            near,
          );

      expect(order, [far, near]);
      expect(lock.acquisitions, 2);
    });

    test('stops at the first refusal and says which nodes were sent', () async {
      final c = await container();
      const refusal = ResourceNotFoundError(code: 7016);
      when(() => mockService.run(any(), near)).thenThrow(refusal);

      await expectLater(
        c.read(nodeActionProvider.notifier).run(NodeAction.reboot, near),
        throwsA(isA<NodeActionError>()
            .having((e) => e.failedNodeId, 'failedNodeId', near)
            .having((e) => e.sentNodeIds, 'sentNodeIds', [far]).having(
                (e) => e.cause, 'cause', refusal)),
      );
    });

    test('the first refusal stops the nodes after it', () async {
      final c = await container();
      when(() => mockService.run(any(), far)).thenThrow(const TimeoutError());

      await expectLater(
        c.read(nodeActionProvider.notifier).run(NodeAction.reboot, near),
        throwsA(isA<NodeActionError>()
            .having((e) => e.failedNodeId, 'failedNodeId', far)
            .having((e) => e.sentNodeIds, 'sentNodeIds', isEmpty)),
      );
      verifyNever(() => mockService.run(any(), near));
    });

    // The lock throws a Dart TimeoutException, not a ServiceError; letting it
    // through would skip the page's error handling altogether.
    test('a lock timeout is reported like any other failure', () async {
      final c = await container();
      when(() => mockService.run(any(), far))
          .thenThrow(TimeoutException('USP mutation timed out after 30s'));

      await expectLater(
        c.read(nodeActionProvider.notifier).run(NodeAction.reboot, far),
        throwsA(isA<NodeActionError>()
            .having((e) => e.failedNodeId, 'failedNodeId', far)
            .having((e) => e.cause, 'cause', isA<TimeoutError>())),
      );
    });

    test('a node no longer in the network is not found', () async {
      final c = await container();

      await expectLater(
        c.read(nodeActionProvider.notifier).run(
              NodeAction.reboot,
              'AA:BB:CC:DD:EE:FF',
            ),
        throwsA(isA<ResourceNotFoundError>()),
      );
      verifyNever(() => mockService.run(any(), any()));
    });
  });

  // Decided 2026-10-20: a node's reboot and factory reset leave the
  // controller's admin credential alone, so the Remote Assistance session
  // survives both. The controller's own factory reset stays refused
  // (usp_admin_notifier_test.dart).
  group('NodeActionNotifier - Remote Assistance', () {
    Future<ProviderContainer> remote() => container(extra: [
          appModeProfileProvider.overrideWithValue(const RemoteModeProfile()),
        ]);

    test('a node reboot is not refused', () async {
      final c = await remote();

      await c.read(nodeActionProvider.notifier).run(NodeAction.reboot, far);

      verify(() => mockService.run(NodeAction.reboot, far)).called(1);
    });

    test('a node factory reset is not refused', () async {
      final c = await remote();

      await c
          .read(nodeActionProvider.notifier)
          .run(NodeAction.factoryReset, far);

      verify(() => mockService.run(NodeAction.factoryReset, far)).called(1);
    });
  });
}
