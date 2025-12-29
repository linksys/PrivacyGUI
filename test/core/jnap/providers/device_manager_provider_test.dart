import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/services/device_manager_service.dart';

import '../../../mocks/test_data/device_manager_test_data.dart';

class MockDeviceManagerService extends Mock implements DeviceManagerService {}

class MockPollingNotifier extends Mock implements PollingNotifier {}

void main() {
  late MockDeviceManagerService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockDeviceManagerService();
  });

  tearDown(() {
    container.dispose();
  });

  group('DeviceManagerNotifier - build', () {
    test('delegates to service.transformPollingData', () {
      // Arrange
      final pollingData = DeviceManagerTestData.createCompletePollingData();
      final expectedState = DeviceManagerState(
        deviceList: [
          LinksysDevice.fromMap(DeviceManagerTestData.createMasterDevice()),
        ],
        lastUpdateTime: pollingData.lastUpdate,
      );

      when(() => mockService.transformPollingData(pollingData))
          .thenReturn(expectedState);

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(pollingData)),
        ],
      );

      // Act
      final state = container.read(deviceManagerProvider);

      // Assert
      verify(() => mockService.transformPollingData(pollingData)).called(1);
      expect(state, equals(expectedState));
    });

    test('handles null polling data', () {
      // Arrange
      const expectedState = DeviceManagerState();

      // When polling data is not ready (null), service should return empty state
      when(() => mockService.transformPollingData(any()))
          .thenReturn(expectedState);

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final state = container.read(deviceManagerProvider);

      // Assert
      // The mock notifier returns a default CoreTransactionData when null is passed
      verify(() => mockService.transformPollingData(any())).called(1);
      expect(state.deviceList, isEmpty);
    });
  });

  group('DeviceManagerNotifier - updateDeviceNameAndIcon', () {
    test('delegates to service and updates state', () async {
      // Arrange
      final masterDevice =
          LinksysDevice.fromMap(DeviceManagerTestData.createMasterDevice());
      final initialState = DeviceManagerState(
        deviceList: [masterDevice],
      );
      final updatedProperties = [
        RawDeviceProperty(name: 'userDeviceName', value: 'New Name'),
      ];

      when(() => mockService.transformPollingData(any()))
          .thenReturn(initialState);
      when(() => mockService.updateDeviceNameAndIcon(
            targetId: masterDevice.deviceID,
            newName: 'New Name',
            isLocation: false,
            icon: null,
          )).thenAnswer((_) async => updatedProperties);

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      await container
          .read(deviceManagerProvider.notifier)
          .updateDeviceNameAndIcon(
            targetId: masterDevice.deviceID,
            newName: 'New Name',
            isLocation: false,
          );

      // Assert
      verify(() => mockService.updateDeviceNameAndIcon(
            targetId: masterDevice.deviceID,
            newName: 'New Name',
            isLocation: false,
            icon: null,
          )).called(1);
    });
  });

  group('DeviceManagerNotifier - deleteDevices', () {
    test('delegates to service with empty list returns immediately', () async {
      // Arrange
      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DeviceManagerState());
      when(() => mockService.deleteDevices([])).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifierWithForce()),
        ],
      );

      // Act
      await container
          .read(deviceManagerProvider.notifier)
          .deleteDevices(deviceIds: []);

      // Assert
      verify(() => mockService.deleteDevices([])).called(1);
    });

    test('delegates to service and removes deleted devices from state',
        () async {
      // Arrange
      final device1 =
          LinksysDevice.fromMap(DeviceManagerTestData.createExternalDevice(
        deviceId: 'device-1',
      ));
      final device2 =
          LinksysDevice.fromMap(DeviceManagerTestData.createExternalDevice(
        deviceId: 'device-2',
      ));
      final initialState = DeviceManagerState(
        deviceList: [device1, device2],
      );

      when(() => mockService.transformPollingData(any()))
          .thenReturn(initialState);
      when(() => mockService.deleteDevices(['device-1']))
          .thenAnswer((_) async => {'device-1': true});

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifierWithForce()),
        ],
      );

      // Act
      await container.read(deviceManagerProvider.notifier).deleteDevices(
        deviceIds: ['device-1'],
      );

      // Assert
      verify(() => mockService.deleteDevices(['device-1'])).called(1);
      final state = container.read(deviceManagerProvider);
      expect(state.deviceList.length, equals(1));
      expect(state.deviceList.first.deviceID, equals('device-2'));
    });
  });

  group('DeviceManagerNotifier - deauthClient', () {
    test('delegates to service', () async {
      // Arrange
      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DeviceManagerState());
      when(() => mockService.deauthClient('AA:BB:CC:DD:EE:FF'))
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifierWithForce()),
        ],
      );

      // Act
      await container
          .read(deviceManagerProvider.notifier)
          .deauthClient(macAddress: 'AA:BB:CC:DD:EE:FF');

      // Assert
      verify(() => mockService.deauthClient('AA:BB:CC:DD:EE:FF')).called(1);
    });
  });

  group('DeviceManagerNotifier - state query methods', () {
    test('isEmptyState returns true when deviceList is empty', () {
      // Arrange
      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DeviceManagerState());

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final isEmpty =
          container.read(deviceManagerProvider.notifier).isEmptyState();

      // Assert
      expect(isEmpty, isTrue);
    });

    test('isEmptyState returns false when deviceList has items', () {
      // Arrange
      final masterDevice =
          LinksysDevice.fromMap(DeviceManagerTestData.createMasterDevice());
      final initialState = DeviceManagerState(deviceList: [masterDevice]);

      when(() => mockService.transformPollingData(any()))
          .thenReturn(initialState);

      container = ProviderContainer(
        overrides: [
          deviceManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final isEmpty =
          container.read(deviceManagerProvider.notifier).isEmptyState();

      // Assert
      expect(isEmpty, isFalse);
    });
  });
}

/// Mock polling notifier that returns the given data
class _MockPollingNotifier extends PollingNotifier {
  final CoreTransactionData? _data;

  _MockPollingNotifier(this._data);

  @override
  CoreTransactionData build() =>
      _data ??
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});
}

/// Mock polling notifier with forcePolling support
class _MockPollingNotifierWithForce extends PollingNotifier {
  @override
  CoreTransactionData build() =>
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});

  @override
  Future<dynamic> forcePolling() async {
    // No-op for testing
  }
}
