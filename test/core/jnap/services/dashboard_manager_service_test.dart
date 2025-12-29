import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/services/dashboard_manager_service.dart';

import '../../../mocks/test_data/dashboard_manager_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late DashboardManagerService service;
  late MockRouterRepository mockRouterRepository;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getDeviceInfo);
  });

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    service = DashboardManagerService(mockRouterRepository);
  });

  group('DashboardManagerService - transformPollingData', () {
    // T018: transformPollingData returns default state when pollingResult is null
    test('returns default state when pollingResult is null', () {
      // Arrange
      const CoreTransactionData? pollingData = null;

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result, isA<DashboardManagerState>());
      expect(result.deviceInfo, isNull);
      expect(result.mainRadios, isEmpty);
      expect(result.guestRadios, isEmpty);
      expect(result.isGuestNetworkEnabled, isFalse);
      expect(result.uptimes, equals(0));
      expect(result.wanConnection, isNull);
      expect(result.lanConnections, isEmpty);
      expect(result.skuModelNumber, isNull);
      expect(result.cpuLoad, isNull);
      expect(result.memoryLoad, isNull);
    });

    // T019: transformPollingData returns complete state when all actions succeed
    test('returns complete state when all actions succeed', () {
      // Arrange
      final pollingData =
          DashboardManagerTestData.createSuccessfulPollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result, isA<DashboardManagerState>());
      expect(result.deviceInfo, isNotNull);
      expect(result.deviceInfo?.serialNumber, equals('TEST123456'));
      expect(result.deviceInfo?.modelNumber, equals('MX5300'));
      expect(result.mainRadios, isNotEmpty);
      expect(result.mainRadios.length, equals(2)); // 2.4GHz and 5GHz
      expect(result.guestRadios, isNotEmpty);
      expect(result.guestRadios.length, equals(2));
      expect(result.isGuestNetworkEnabled, isFalse);
      expect(result.uptimes, equals(86400));
      expect(result.wanConnection, equals('Linked-1000Mbps'));
      expect(result.lanConnections, isNotEmpty);
      expect(result.skuModelNumber, equals('MX5300-SKU'));
      expect(result.localTime, isNotNull);
      expect(result.localTime, isNot(equals(0)));
    });

    // T020: transformPollingData returns partial state when some actions fail
    test('returns partial state when some actions fail', () {
      // Arrange
      final pollingData =
          DashboardManagerTestData.createPartialErrorPollingData(
        failedActions: {
          JNAPAction.getRadioInfo,
          JNAPAction.getGuestRadioSettings
        },
      );

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result, isA<DashboardManagerState>());
      // Device info should still be present
      expect(result.deviceInfo, isNotNull);
      // Radio info should be empty due to failure
      expect(result.mainRadios, isEmpty);
      expect(result.guestRadios, isEmpty);
      // System stats should still be present
      expect(result.uptimes, equals(86400));
      // Ethernet ports should still be present
      expect(result.wanConnection, isNotNull);
    });

    // T021: transformPollingData correctly parses each JNAP action response
    test('correctly parses each JNAP action response', () {
      // Arrange
      final pollingData = DashboardManagerTestData.createSuccessfulPollingData(
        deviceInfo: DashboardManagerTestData.createDeviceInfoSuccess(
          serialNumber: 'CUSTOM_SN',
          modelNumber: 'CUSTOM_MODEL',
          firmwareVersion: '2.0.0',
        ),
        systemStats: DashboardManagerTestData.createSystemStatsSuccess(
          uptimeSeconds: 172800,
          cpuLoad: '45%',
          memoryLoad: '60%',
        ),
        ethernetPortConnections:
            DashboardManagerTestData.createEthernetPortConnectionsSuccess(
          lanPortConnections: ['Linked-100Mbps', 'None'],
          wanPortConnection: 'Linked-100Mbps',
        ),
      );

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result.deviceInfo?.serialNumber, equals('CUSTOM_SN'));
      expect(result.deviceInfo?.modelNumber, equals('CUSTOM_MODEL'));
      expect(result.deviceInfo?.firmwareVersion, equals('2.0.0'));
      expect(result.uptimes, equals(172800));
      expect(result.cpuLoad, equals('45%'));
      expect(result.memoryLoad, equals('60%'));
      expect(result.wanConnection, equals('Linked-100Mbps'));
      expect(result.lanConnections, equals(['Linked-100Mbps', 'None']));
    });

    // T022: transformPollingData uses default localTime when parsing fails
    test('uses current time when localTime parsing fails', () {
      // Arrange
      final pollingData =
          DashboardManagerTestData.createPollingDataWithInvalidTime();
      final beforeTest = DateTime.now().millisecondsSinceEpoch;

      // Act
      final result = service.transformPollingData(pollingData);
      final afterTest = DateTime.now().millisecondsSinceEpoch;

      // Assert
      expect(result.localTime, isNotNull);
      expect(result.localTime, greaterThanOrEqualTo(beforeTest));
      expect(result.localTime, lessThanOrEqualTo(afterTest));
    });

    test('correctly parses radio info with multiple bands', () {
      // Arrange
      final pollingData =
          DashboardManagerTestData.createSuccessfulPollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result.mainRadios.length, equals(2));
      expect(result.mainRadios.any((r) => r.band == '2.4GHz'), isTrue);
      expect(result.mainRadios.any((r) => r.band == '5GHz'), isTrue);
    });

    test('correctly parses guest radio settings', () {
      // Arrange
      final pollingData = DashboardManagerTestData.createSuccessfulPollingData(
        guestRadioSettings:
            DashboardManagerTestData.createGuestRadioSettingsSuccess(
          isGuestNetworkEnabled: true,
        ),
      );

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result.isGuestNetworkEnabled, isTrue);
      expect(result.guestRadios.length, equals(2));
    });
  });

  group('DashboardManagerService - checkRouterIsBack', () {
    // T034: checkRouterIsBack returns NodeDeviceInfo when SN matches
    test('returns NodeDeviceInfo when serial number matches', () async {
      // Arrange
      const expectedSN = 'TEST123456';
      final deviceInfoOutput = DashboardManagerTestData.createDeviceInfoSuccess(
              serialNumber: expectedSN)
          .output;

      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act
      final result = await service.checkRouterIsBack(expectedSN);

      // Assert
      expect(result, isA<NodeDeviceInfo>());
      expect(result.serialNumber, equals(expectedSN));
    });

    // T035: checkRouterIsBack throws SerialNumberMismatchError when SN doesn't match
    test('throws SerialNumberMismatchError when serial number does not match',
        () async {
      // Arrange
      const expectedSN = 'EXPECTED_SN';
      const actualSN = 'ACTUAL_SN';
      final deviceInfoOutput = DashboardManagerTestData.createDeviceInfoSuccess(
              serialNumber: actualSN)
          .output;

      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act & Assert
      expect(
        () => service.checkRouterIsBack(expectedSN),
        throwsA(isA<SerialNumberMismatchError>()),
      );
    });

    // T036: checkRouterIsBack throws ConnectivityError when router unreachable
    test('throws ConnectivityError when router is unreachable', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getDeviceInfo,
            fetchRemote: true,
            retries: 0,
          )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => service.checkRouterIsBack('TEST123456'),
        throwsA(isA<ConnectivityError>()),
      );
    });

    // T037: checkRouterIsBack maps JNAPError to ServiceError correctly
    test('maps JNAPError to ServiceError correctly', () async {
      // Arrange
      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenThrow(const JNAPError(
              result: '_ErrorUnauthorized', error: 'Unauthorized'));

      // Act & Assert
      expect(
        () => service.checkRouterIsBack('TEST123456'),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('returns NodeDeviceInfo when expected serial number is empty',
        () async {
      // Arrange - empty SN should skip validation
      final deviceInfoOutput = DashboardManagerTestData.createDeviceInfoSuccess(
              serialNumber: 'ANY_SN')
          .output;

      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act
      final result = await service.checkRouterIsBack('');

      // Assert
      expect(result, isA<NodeDeviceInfo>());
      expect(result.serialNumber, equals('ANY_SN'));
    });
  });

  group('DashboardManagerService - checkDeviceInfo', () {
    // T044: checkDeviceInfo returns cached value immediately when available
    test('returns cached value immediately when available', () async {
      // Arrange
      final cachedDeviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess(
                serialNumber: 'CACHED_SN')
            .output,
      );

      // Act
      final result = await service.checkDeviceInfo(cachedDeviceInfo);

      // Assert
      expect(result, equals(cachedDeviceInfo));
      expect(result.serialNumber, equals('CACHED_SN'));
      // No API call should be made when cached value exists
      verifyZeroInteractions(mockRouterRepository);
    });

    // T045: checkDeviceInfo makes API call when cached value is null
    test('makes API call when cached value is null', () async {
      // Arrange
      final deviceInfoOutput = DashboardManagerTestData.createDeviceInfoSuccess(
              serialNumber: 'FRESH_SN')
          .output;

      when(() => mockRouterRepository.send(
                any(),
                retries: any(named: 'retries'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act
      final result = await service.checkDeviceInfo(null);

      // Assert
      expect(result, isA<NodeDeviceInfo>());
      expect(result.serialNumber, equals('FRESH_SN'));
      verify(() => mockRouterRepository.send(
            JNAPAction.getDeviceInfo,
            retries: 0,
            timeoutMs: 3000,
          )).called(1);
    });

    // T046: checkDeviceInfo throws ServiceError on API failure
    test('throws ServiceError on API failure', () async {
      // Arrange
      when(() => mockRouterRepository.send(
                any(),
                retries: any(named: 'retries'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenThrow(const JNAPError(
              result: 'ErrorDeviceNotFound', error: 'Device not found'));

      // Act & Assert
      expect(
        () => service.checkDeviceInfo(null),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });
  });
}
