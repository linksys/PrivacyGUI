import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/nodes/services/add_nodes_service.dart';

import '../../../mocks/test_data/add_nodes_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late AddNodesService service;
  late MockRouterRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getBluetoothAutoOnboardingSettings);
  });

  setUp(() {
    mockRepo = MockRouterRepository();
    service = AddNodesService(mockRepo);
  });

  group('AddNodesService - setAutoOnboardingSettings', () {
    test('sends correct JNAP action with auth', () async {
      when(() => mockRepo.send(
                any(),
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              AddNodesTestData.createAutoOnboardingSettingsSuccess());

      await service.setAutoOnboardingSettings();

      verify(() => mockRepo.send(
            JNAPAction.setBluetoothAutoOnboardingSettings,
            data: {'isAutoOnboardingEnabled': true},
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      when(() => mockRepo.send(
            any(),
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenThrow(AddNodesTestData.createJNAPError());

      expect(
        () => service.setAutoOnboardingSettings(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('throws UnauthorizedError on authentication failure', () async {
      when(() => mockRepo.send(
            any(),
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenThrow(AddNodesTestData.createUnauthorizedError());

      expect(
        () => service.setAutoOnboardingSettings(),
        throwsA(isA<UnauthorizedError>()),
      );
    });
  });

  group('AddNodesService - getAutoOnboardingSettings', () {
    test('returns true when auto-onboarding is enabled', () async {
      when(() => mockRepo.send(
                any(),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              AddNodesTestData.createAutoOnboardingSettingsSuccess(
                  isEnabled: true));

      final result = await service.getAutoOnboardingSettings();

      expect(result, isTrue);
      verify(() => mockRepo.send(
            JNAPAction.getBluetoothAutoOnboardingSettings,
            auth: true,
          )).called(1);
    });

    test('returns false when auto-onboarding is disabled', () async {
      when(() => mockRepo.send(
                any(),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              AddNodesTestData.createAutoOnboardingSettingsSuccess(
                  isEnabled: false));

      final result = await service.getAutoOnboardingSettings();

      expect(result, isFalse);
    });

    test('throws ServiceError on JNAP failure', () async {
      when(() => mockRepo.send(
            any(),
            auth: any(named: 'auth'),
          )).thenThrow(AddNodesTestData.createJNAPError());

      expect(
        () => service.getAutoOnboardingSettings(),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('AddNodesService - pollAutoOnboardingStatus', () {
    test('emits status map from JNAP result', () async {
      final controller = StreamController<JNAPResult>();

      when(() => mockRepo.scheduledCommand(
            action: any(named: 'action'),
            maxRetry: any(named: 'maxRetry'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => controller.stream);

      final stream = service.pollAutoOnboardingStatus();
      final results = <Map<String, dynamic>>[];
      final subscription = stream.listen(results.add);

      controller.add(AddNodesTestData.createAutoOnboardingStatusSuccess(
        status: 'Onboarding',
      ));

      await Future.delayed(Duration.zero);

      expect(results.length, equals(1));
      expect(results.first['status'], equals('Onboarding'));

      await subscription.cancel();
      await controller.close();
    });

    test('uses oneTake config when specified', () async {
      final controller = StreamController<JNAPResult>();

      when(() => mockRepo.scheduledCommand(
            action: any(named: 'action'),
            maxRetry: any(named: 'maxRetry'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => controller.stream);

      // Listen to the stream to trigger the scheduledCommand call
      final subscription =
          service.pollAutoOnboardingStatus(oneTake: true).listen((_) {});

      verify(() => mockRepo.scheduledCommand(
            action: JNAPAction.getBluetoothAutoOnboardingStatus,
            maxRetry: 1,
            retryDelayInMilliSec: 10000,
            firstDelayInMilliSec: 100,
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: true,
          )).called(1);

      await subscription.cancel();
      await controller.close();
    });
  });

  group('AddNodesService - startAutoOnboarding', () {
    test('sends correct JNAP action', () async {
      when(() => mockRepo.send(
            any(),
            auth: any(named: 'auth'),
          )).thenAnswer((_) async => JNAPSuccess(result: 'ok', output: {}));

      await service.startAutoOnboarding();

      verify(() => mockRepo.send(
            JNAPAction.startBlueboothAutoOnboarding,
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      when(() => mockRepo.send(
            any(),
            auth: any(named: 'auth'),
          )).thenThrow(AddNodesTestData.createJNAPError());

      expect(
        () => service.startAutoOnboarding(),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('AddNodesService - pollForNodesOnline', () {
    test('transforms JNAP devices to LinksysDevice list', () async {
      final controller = StreamController<JNAPResult>();

      when(() => mockRepo.scheduledCommand(
            action: any(named: 'action'),
            maxRetry: any(named: 'maxRetry'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => controller.stream);

      final stream = service.pollForNodesOnline(['AA:BB:CC:DD:EE:FF']);
      final results = <List<LinksysDevice>>[];
      final subscription = stream.listen(results.add);

      // Emit devices with proper structure
      controller.add(AddNodesTestData.createOnlineNodesResponse(
        macAddresses: ['AA:BB:CC:DD:EE:FF'],
      ));

      await Future.delayed(Duration.zero);

      expect(results.length, equals(1));
      expect(results.first, isA<List<LinksysDevice>>());
      expect(results.first.length, equals(1));
      expect(results.first.first.nodeType, equals('Slave'));

      await subscription.cancel();
      await controller.close();
    });

    test('uses refreshing config when specified', () async {
      final controller = StreamController<JNAPResult>();

      when(() => mockRepo.scheduledCommand(
            action: any(named: 'action'),
            maxRetry: any(named: 'maxRetry'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => controller.stream);

      // Listen to trigger the call
      final subscription =
          service.pollForNodesOnline(['MAC'], refreshing: true).listen((_) {});

      verify(() => mockRepo.scheduledCommand(
            action: JNAPAction.getDevices,
            maxRetry: 5,
            retryDelayInMilliSec: 3000,
            firstDelayInMilliSec: 1000,
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: true,
          )).called(1);

      await subscription.cancel();
      await controller.close();
    });
  });

  group('AddNodesService - pollNodesBackhaulInfo', () {
    test('returns stream of backhaul info', () async {
      final controller = StreamController<JNAPResult>();

      when(() => mockRepo.scheduledCommand(
            action: any(named: 'action'),
            maxRetry: any(named: 'maxRetry'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => controller.stream);

      // Pass empty list to test basic stream functionality
      final stream = service.pollNodesBackhaulInfo([]);
      final results = <List<BackHaulInfoData>>[];
      final subscription = stream.listen(results.add);

      controller.add(AddNodesTestData.createBackhaulInfoForDevices(
        deviceUUIDs: ['test-uuid'],
      ));

      await Future.delayed(Duration.zero);

      expect(results.length, equals(1));
      expect(results.first.length, equals(1));
      expect(results.first.first.deviceUUID, equals('test-uuid'));

      await subscription.cancel();
      await controller.close();
    });

    test('uses refreshing config when specified', () async {
      final controller = StreamController<JNAPResult>();

      when(() => mockRepo.scheduledCommand(
            action: any(named: 'action'),
            maxRetry: any(named: 'maxRetry'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => controller.stream);

      // Listen to trigger the call
      final subscription =
          service.pollNodesBackhaulInfo([], refreshing: true).listen((_) {});

      verify(() => mockRepo.scheduledCommand(
            action: JNAPAction.getBackhaulInfo,
            maxRetry: 1,
            retryDelayInMilliSec: 3000,
            firstDelayInMilliSec: 1000,
            condition: any(named: 'condition'),
            onCompleted: any(named: 'onCompleted'),
            auth: true,
          )).called(1);

      await subscription.cancel();
      await controller.close();
    });
  });

  group('AddNodesService - collectChildNodeData', () {
    test('merges backhaul info into child nodes', () {
      // Create devices with proper structure using test data
      final deviceMap = AddNodesTestData.createDeviceData(
        deviceID: 'device-1',
        nodeType: 'Slave',
        connections: [
          AddNodesTestData.createConnection(macAddress: 'AA:BB:CC:DD:EE:FF'),
        ],
      );
      final device = LinksysDevice.fromMap(deviceMap);

      final backhaulInfo = BackHaulInfoData(
        deviceUUID: 'device-1',
        ipAddress: '192.168.1.100',
        parentIPAddress: '192.168.1.1',
        connectionType: 'Wireless',
        wirelessConnectionInfo: null,
        speedMbps: '866',
        timestamp: '2024-01-01T00:00:00Z',
      );

      final result = service.collectChildNodeData([device], [backhaulInfo]);

      expect(result.length, equals(1));
      expect(result.first.connectionType, equals('Wireless'));
    });

    test('preserves device without matching backhaul info', () {
      final deviceMap = AddNodesTestData.createDeviceData(
        deviceID: 'device-1',
        nodeType: 'Slave',
      );
      final device = LinksysDevice.fromMap(deviceMap);

      final result = service.collectChildNodeData([device], []);

      expect(result.length, equals(1));
      expect(result.first.deviceID, equals('device-1'));
    });

    test('sorts devices with authority first', () {
      final masterMap = AddNodesTestData.createDeviceData(
        deviceID: 'master',
        nodeType: 'Master',
        isAuthority: true,
      );
      final slaveMap = AddNodesTestData.createDeviceData(
        deviceID: 'slave',
        nodeType: 'Slave',
        isAuthority: false,
      );

      final master = LinksysDevice.fromMap(masterMap);
      final slave = LinksysDevice.fromMap(slaveMap);

      // Pass slave first to verify sorting
      final result = service.collectChildNodeData([slave, master], []);

      expect(result.first.isAuthority, isTrue);
    });
  });
}
