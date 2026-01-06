import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/services/add_nodes_service.dart';

import '../../../mocks/test_data/add_nodes_test_data.dart';

class MockAddNodesService extends Mock implements AddNodesService {}

class MockPollingNotifier extends AsyncNotifier<CoreTransactionData>
    implements PollingNotifier {
  @override
  FutureOr<CoreTransactionData> build() =>
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});

  @override
  void stopPolling() {}

  @override
  Future<void> forcePolling() async {}

  @override
  void startPolling() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAddNodesService mockService;
  late MockPollingNotifier mockPollingNotifier;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(<LinksysDevice>[]);
    registerFallbackValue(<BackHaulInfoData>[]);
  });

  setUp(() {
    mockService = MockAddNodesService();
    mockPollingNotifier = MockPollingNotifier();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        addNodesServiceProvider.overrideWithValue(mockService),
        pollingProvider.overrideWith(() => mockPollingNotifier),
      ],
    );
  }

  group('AddNodesNotifier - setAutoOnboardingSettings', () {
    test('delegates to service', () async {
      when(() => mockService.setAutoOnboardingSettings())
          .thenAnswer((_) async {});

      container = createContainer();

      await container
          .read(addNodesProvider.notifier)
          .setAutoOnboardingSettings();

      verify(() => mockService.setAutoOnboardingSettings()).called(1);
    });
  });

  group('AddNodesNotifier - getAutoOnboardingSettings', () {
    test('delegates to service and returns result', () async {
      when(() => mockService.getAutoOnboardingSettings())
          .thenAnswer((_) async => true);

      container = createContainer();

      final result = await container
          .read(addNodesProvider.notifier)
          .getAutoOnboardingSettings();

      expect(result, true);
      verify(() => mockService.getAutoOnboardingSettings()).called(1);
    });

    test('returns false when disabled', () async {
      when(() => mockService.getAutoOnboardingSettings())
          .thenAnswer((_) async => false);

      container = createContainer();

      final result = await container
          .read(addNodesProvider.notifier)
          .getAutoOnboardingSettings();

      expect(result, false);
    });
  });

  group('AddNodesNotifier - getAutoOnboardingStatus', () {
    test('delegates to service pollAutoOnboardingStatus with oneTake',
        () async {
      final controller = StreamController<Map<String, dynamic>>();

      when(() => mockService.pollAutoOnboardingStatus(oneTake: true))
          .thenAnswer((_) => controller.stream);

      container = createContainer();

      final future =
          container.read(addNodesProvider.notifier).getAutoOnboardingStatus();

      // Emit single result
      controller.add({
        'status': 'Idle',
        'deviceOnboardingStatus': [],
      });
      await controller.close();

      final result = await future;

      expect(result['status'], 'Idle');
      verify(() => mockService.pollAutoOnboardingStatus(oneTake: true))
          .called(1);
    });
  });

  group('AddNodesNotifier - startAutoOnboarding', () {
    test('calls startAutoOnboarding on service', () async {
      // Setup mocks
      when(() => mockService.startAutoOnboarding()).thenAnswer((_) async {});

      final statusController = StreamController<Map<String, dynamic>>();
      when(() => mockService.pollAutoOnboardingStatus())
          .thenAnswer((_) => statusController.stream);

      when(() => mockService.collectChildNodeData(any(), any())).thenReturn([]);

      container = createContainer();

      final future =
          container.read(addNodesProvider.notifier).startAutoOnboarding();

      // Complete the stream
      statusController.add({'status': 'Idle', 'deviceOnboardingStatus': []});
      await statusController.close();

      await future;

      // Verify service was called
      verify(() => mockService.startAutoOnboarding()).called(1);
    });

    test('calls service methods in correct order', () async {
      // Setup mocks
      when(() => mockService.startAutoOnboarding()).thenAnswer((_) async {});

      final statusController = StreamController<Map<String, dynamic>>();
      when(() => mockService.pollAutoOnboardingStatus())
          .thenAnswer((_) => statusController.stream);

      when(() => mockService.collectChildNodeData(any(), any())).thenReturn([]);

      container = createContainer();

      final future =
          container.read(addNodesProvider.notifier).startAutoOnboarding();

      // Emit Idle status (no onboarding happened)
      statusController.add({'status': 'Idle', 'deviceOnboardingStatus': []});
      await statusController.close();

      await future;

      // Verify calls in order
      verifyInOrder([
        () => mockService.startAutoOnboarding(),
        () => mockService.pollAutoOnboardingStatus(),
      ]);
    });

    test('updates state with onboarding results when devices onboarded',
        () async {
      // Setup mocks
      when(() => mockService.startAutoOnboarding()).thenAnswer((_) async {});

      final statusController = StreamController<Map<String, dynamic>>();
      when(() => mockService.pollAutoOnboardingStatus())
          .thenAnswer((_) => statusController.stream);

      final nodesController = StreamController<List<LinksysDevice>>();
      when(() => mockService.pollForNodesOnline(any()))
          .thenAnswer((_) => nodesController.stream);

      final backhaulController = StreamController<List<BackHaulInfoData>>();
      when(() => mockService.pollNodesBackhaulInfo(any()))
          .thenAnswer((_) => backhaulController.stream);

      when(() => mockService.collectChildNodeData(any(), any())).thenReturn([]);

      container = createContainer();

      final future =
          container.read(addNodesProvider.notifier).startAutoOnboarding();

      // Emit onboarding status with onboarded device
      statusController.add({
        'status': 'Onboarding',
        'deviceOnboardingStatus': [
          {
            'btMACAddress': 'AA:BB:CC:DD:EE:FF',
            'onboardingStatus': 'Onboarded'
          },
        ],
      });
      statusController.add({
        'status': 'Complete',
        'deviceOnboardingStatus': [
          {
            'btMACAddress': 'AA:BB:CC:DD:EE:FF',
            'onboardingStatus': 'Onboarded'
          },
        ],
      });
      await statusController.close();

      // Emit nodes online
      final deviceMap = AddNodesTestData.createDeviceData(
        deviceID: 'new-node',
        nodeType: 'Slave',
        knownInterfaces: [
          AddNodesTestData.createKnownInterface(
              macAddress: 'AA:BB:CC:DD:EE:FF'),
        ],
      );
      final device = LinksysDevice.fromMap(deviceMap);
      nodesController.add([device]);
      await nodesController.close();

      // Emit backhaul info
      backhaulController.add([]);
      await backhaulController.close();

      await future;

      final state = container.read(addNodesProvider);
      expect(state.onboardingProceed, true);
      expect(state.anyOnboarded, true);
      expect(state.onboardedMACList, contains('AA:BB:CC:DD:EE:FF'));
      expect(state.isLoading, false);
    });
  });

  group('AddNodesNotifier - startRefresh', () {
    test('calls service with refreshing flag', () async {
      final nodesController = StreamController<List<LinksysDevice>>();
      when(() => mockService.pollForNodesOnline(any(), refreshing: true))
          .thenAnswer((_) => nodesController.stream);

      final backhaulController = StreamController<List<BackHaulInfoData>>();
      when(() => mockService.pollNodesBackhaulInfo(any(), refreshing: true))
          .thenAnswer((_) => backhaulController.stream);

      when(() => mockService.collectChildNodeData(any(), any())).thenReturn([]);

      container = createContainer();

      final future = container.read(addNodesProvider.notifier).startRefresh();

      nodesController.add([]);
      await nodesController.close();
      backhaulController.add([]);
      await backhaulController.close();

      await future;

      verify(() => mockService.pollForNodesOnline(any(), refreshing: true))
          .called(1);
      verify(() => mockService.pollNodesBackhaulInfo(any(), refreshing: true))
          .called(1);
    });

    test('updates state with refreshed child nodes', () async {
      final deviceMap = AddNodesTestData.createDeviceData(
        deviceID: 'child-node',
        nodeType: 'Slave',
      );
      final device = LinksysDevice.fromMap(deviceMap);

      final nodesController = StreamController<List<LinksysDevice>>();
      when(() => mockService.pollForNodesOnline(any(), refreshing: true))
          .thenAnswer((_) => nodesController.stream);

      final backhaulController = StreamController<List<BackHaulInfoData>>();
      when(() => mockService.pollNodesBackhaulInfo(any(), refreshing: true))
          .thenAnswer((_) => backhaulController.stream);

      when(() => mockService.collectChildNodeData(any(), any()))
          .thenReturn([device]);

      container = createContainer();

      final future = container.read(addNodesProvider.notifier).startRefresh();

      nodesController.add([device]);
      await nodesController.close();
      backhaulController.add([]);
      await backhaulController.close();

      await future;

      final state = container.read(addNodesProvider);
      expect(state.isLoading, false);
      expect(state.loadingMessage, '');
      expect(state.childNodes?.length, 1);
      expect(state.childNodes?.first.deviceID, 'child-node');
    });
  });

  group('AddNodesNotifier - initial state', () {
    test('returns default state on build', () {
      when(() => mockService.setAutoOnboardingSettings())
          .thenAnswer((_) async {});

      container = createContainer();

      final state = container.read(addNodesProvider);

      expect(state, const AddNodesState());
      expect(state.isLoading, false);
      expect(state.onboardingProceed, isNull);
      expect(state.anyOnboarded, isNull);
    });
  });
}
