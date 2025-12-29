import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/services/device_manager_service.dart';

import '../../../mocks/test_data/device_manager_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late DeviceManagerService service;
  late MockRouterRepository mockRouterRepository;

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    service = DeviceManagerService(mockRouterRepository);
  });

  group('DeviceManagerService - transformPollingData', () {
    test('returns empty default state when polling data is null', () {
      // Arrange
      final pollingData = DeviceManagerTestData.createNullPollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result, isA<DeviceManagerState>());
      expect(result.deviceList, isEmpty);
      expect(result.wirelessConnections, isEmpty);
      expect(result.radioInfos, isEmpty);
      expect(result.backhaulInfoData, isEmpty);
      expect(result.wanStatus, isNull);
      expect(result.guestRadioSettings, isNull);
    });

    test(
        'returns complete state with all device data when valid polling data provided',
        () {
      // Arrange
      final pollingData = DeviceManagerTestData.createCompletePollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result, isA<DeviceManagerState>());
      expect(result.deviceList, isNotEmpty);
      expect(result.deviceList.length,
          greaterThanOrEqualTo(3)); // master, slave, 2 external
      expect(result.wirelessConnections, isNotEmpty);
      expect(result.radioInfos, isNotEmpty);
      expect(result.wanStatus, isNotNull);
      expect(result.lastUpdateTime, equals(1234567890));
    });

    test('returns partial state when some JNAP actions failed', () {
      // Arrange
      final pollingData = DeviceManagerTestData.createPartialErrorPollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result, isA<DeviceManagerState>());
      // Should still have devices even though backhaul info failed
      expect(result.deviceList, isNotEmpty);
      expect(result.wanStatus, isNotNull);
    });

    test('correctly categorizes node devices and external devices', () {
      // Arrange
      final pollingData = DeviceManagerTestData.createCompletePollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      final nodeDevices = result.nodeDevices;
      final externalDevices = result.externalDevices;

      expect(nodeDevices, isNotEmpty);
      expect(externalDevices, isNotEmpty);

      // Master device should be a node
      expect(nodeDevices.any((d) => d.isAuthority), isTrue);

      // External devices should not have nodeType
      for (final device in externalDevices) {
        expect(device.nodeType, isNull);
      }
    });

    test('correctly populates wireless connections map', () {
      // Arrange
      final pollingData = DeviceManagerTestData.createCompletePollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result.wirelessConnections, isNotEmpty);
      // Check that wireless connection contains expected data
      final wirelessConnection = result.wirelessConnections.values.first;
      expect(wirelessConnection.radioID, isNotNull);
      expect(wirelessConnection.band, isNotNull);
    });

    test('correctly populates radio info map', () {
      // Arrange
      final pollingData = DeviceManagerTestData.createCompletePollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result.radioInfos, isNotEmpty);
      expect(result.radioInfos.keys.any((k) => k.contains('5GHz')), isTrue);
    });

    test('returns empty state when polling data has empty device list', () {
      // Arrange
      final pollingData = DeviceManagerTestData.createEmptyPollingData();

      // Act
      final result = service.transformPollingData(pollingData);

      // Assert
      expect(result, isA<DeviceManagerState>());
      expect(result.deviceList, isEmpty);
      expect(result.wanStatus, isNotNull); // WAN status should still be present
    });
  });
}
