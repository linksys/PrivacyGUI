import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/page/nodes/services/node_detail_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNodeDetailService extends Mock implements NodeDetailService {}

class MockDeviceListNotifier extends Notifier<DeviceListState>
    implements DeviceListNotifier {
  @override
  DeviceListState build() => const DeviceListState();

  @override
  DeviceListItem createItem(LinksysDevice device) {
    return DeviceListItem(
      deviceId: device.deviceID,
      name: 'Test Device',
      icon: '',
      isOnline: true,
      macAddress: '',
    );
  }

  @override
  DeviceListState createState(DeviceManagerState deviceManagerState) {
    return const DeviceListState();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeviceManagerNotifier extends Notifier<DeviceManagerState>
    implements DeviceManagerNotifier {
  final DeviceManagerState _state;

  MockDeviceManagerNotifier(this._state);

  @override
  DeviceManagerState build() => _state;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockNodeDetailService mockService;
  late MockDeviceListNotifier mockDeviceListNotifier;
  late ProviderContainer container;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(_createFallbackDevice());
    registerFallbackValue(<LinksysDevice>[]);
    registerFallbackValue(MockDeviceListNotifier());
  });

  setUp(() {
    mockService = MockNodeDetailService();
    mockDeviceListNotifier = MockDeviceListNotifier();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({
    DeviceManagerState? deviceManagerState,
    String targetId = 'test-device-id',
  }) {
    final dmState = deviceManagerState ?? const DeviceManagerState();
    return ProviderContainer(
      overrides: [
        nodeDetailServiceProvider.overrideWithValue(mockService),
        nodeDetailIdProvider.overrideWith((ref) => targetId),
        deviceManagerProvider
            .overrideWith(() => MockDeviceManagerNotifier(dmState)),
        deviceListProvider.overrideWith(() => mockDeviceListNotifier),
      ],
    );
  }

  group('NodeDetailNotifier - createState', () {
    test('returns empty state when targetId is empty', () {
      // Arrange
      container = createContainer(targetId: '');

      // Act
      final state = container.read(nodeDetailProvider);

      // Assert
      expect(state.deviceId, '');
      expect(state.location, '');
      verifyNever(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          ));
    });

    test('returns empty state when device not found', () {
      // Arrange
      final deviceManagerState = DeviceManagerState(
        deviceList: [
          _createTestDevice('other-device-id'),
        ],
      );
      container = createContainer(
        deviceManagerState: deviceManagerState,
        targetId: 'non-existent-device',
      );

      // Act
      final state = container.read(nodeDetailProvider);

      // Assert
      expect(state.deviceId, '');
      verifyNever(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          ));
    });

    test('uses service to transform device data when device found', () {
      // Arrange
      final testDevice = _createTestDevice('test-device-id');
      final masterDevice = _createTestDevice('master-id', isAuthority: true);
      final deviceManagerState = DeviceManagerState(
        deviceList: [testDevice, masterDevice],
      );

      when(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          )).thenReturn({
        'location': 'Living Room',
        'isMaster': false,
        'isOnline': true,
        'isWiredConnection': false,
        'signalStrength': -50,
        'serialNumber': 'SN123',
        'modelNumber': 'MR7500',
        'firmwareVersion': '1.0.0',
        'hardwareVersion': '1',
        'lanIpAddress': '192.168.1.100',
        'wanIpAddress': '100.0.0.1',
        'upstreamDevice': 'Router',
        'isMLO': false,
        'macAddress': 'AA:BB:CC:DD:EE:FF',
      });

      when(() => mockService.transformConnectedDevices(
            devices: any(named: 'devices'),
            deviceListNotifier: any(named: 'deviceListNotifier'),
          )).thenReturn([]);

      container = createContainer(
        deviceManagerState: deviceManagerState,
        targetId: 'test-device-id',
      );

      // Act
      final state = container.read(nodeDetailProvider);

      // Assert
      expect(state.deviceId, 'test-device-id');
      expect(state.location, 'Living Room');
      expect(state.isMaster, false);
      expect(state.isOnline, true);
      expect(state.signalStrength, -50);
      expect(state.modelNumber, 'MR7500');
      verify(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          )).called(1);
    });

    test('identifies master device correctly', () {
      // Arrange
      final masterDevice = _createTestDevice('master-id', isAuthority: true);
      final deviceManagerState = DeviceManagerState(
        deviceList: [masterDevice],
      );

      when(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          )).thenReturn({
        'location': 'Master Node',
        'isMaster': true,
        'isOnline': true,
        'isWiredConnection': true,
        'signalStrength': 0,
        'serialNumber': 'MASTER-SN',
        'modelNumber': 'MBE7000',
        'firmwareVersion': '2.0.0',
        'hardwareVersion': '2',
        'lanIpAddress': '192.168.1.1',
        'wanIpAddress': '100.0.0.1',
        'upstreamDevice': 'INTERNET',
        'isMLO': false,
        'macAddress': '11:22:33:44:55:66',
      });

      when(() => mockService.transformConnectedDevices(
            devices: any(named: 'devices'),
            deviceListNotifier: any(named: 'deviceListNotifier'),
          )).thenReturn([]);

      container = createContainer(
        deviceManagerState: deviceManagerState,
        targetId: 'master-id',
      );

      // Act
      final state = container.read(nodeDetailProvider);

      // Assert
      expect(state.isMaster, true);
      expect(state.upstreamDevice, 'INTERNET');
    });
  });

  group('NodeDetailNotifier - toggleBlinkNode', () {
    test('starts blinking when not currently blinking', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final testDevice = _createTestDevice('test-device-id');
      final deviceManagerState = DeviceManagerState(
        deviceList: [testDevice],
      );

      when(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          )).thenReturn(_defaultUIValues());

      when(() => mockService.transformConnectedDevices(
            devices: any(named: 'devices'),
            deviceListNotifier: any(named: 'deviceListNotifier'),
          )).thenReturn([]);

      when(() => mockService.startBlinkNodeLED(any()))
          .thenAnswer((_) async => {});

      container = createContainer(
        deviceManagerState: deviceManagerState,
        targetId: 'test-device-id',
      );

      // Act
      await container.read(nodeDetailProvider.notifier).toggleBlinkNode();

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockService.startBlinkNodeLED('test-device-id')).called(1);
    });

    test('stops blinking when stopOnly is true', () async {
      // Arrange
      SharedPreferences.setMockInitialValues(
          {blinkingDeviceId: 'test-device-id'});
      final testDevice = _createTestDevice('test-device-id');
      final deviceManagerState = DeviceManagerState(
        deviceList: [testDevice],
      );

      when(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          )).thenReturn(_defaultUIValues());

      when(() => mockService.transformConnectedDevices(
            devices: any(named: 'devices'),
            deviceListNotifier: any(named: 'deviceListNotifier'),
          )).thenReturn([]);

      when(() => mockService.stopBlinkNodeLED()).thenAnswer((_) async => {});

      container = createContainer(
        deviceManagerState: deviceManagerState,
        targetId: 'test-device-id',
      );

      // Act
      await container.read(nodeDetailProvider.notifier).toggleBlinkNode(true);

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockService.stopBlinkNodeLED()).called(1);
    });

    test('handles ServiceError during start blink', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final testDevice = _createTestDevice('test-device-id');
      final deviceManagerState = DeviceManagerState(
        deviceList: [testDevice],
      );

      when(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          )).thenReturn(_defaultUIValues());

      when(() => mockService.transformConnectedDevices(
            devices: any(named: 'devices'),
            deviceListNotifier: any(named: 'deviceListNotifier'),
          )).thenReturn([]);

      when(() => mockService.startBlinkNodeLED(any()))
          .thenThrow(const UnauthorizedError());

      container = createContainer(
        deviceManagerState: deviceManagerState,
        targetId: 'test-device-id',
      );

      // Act
      await container.read(nodeDetailProvider.notifier).toggleBlinkNode();

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - state should reset to blinkNode after error
      final state = container.read(nodeDetailProvider);
      expect(state.blinkingStatus, BlinkingStatus.blinkNode);
    });

    test('handles ServiceError during stop blink', () async {
      // Arrange
      SharedPreferences.setMockInitialValues(
          {blinkingDeviceId: 'test-device-id'});
      final testDevice = _createTestDevice('test-device-id');
      final deviceManagerState = DeviceManagerState(
        deviceList: [testDevice],
      );

      when(() => mockService.transformDeviceToUIValues(
            device: any(named: 'device'),
            masterDevice: any(named: 'masterDevice'),
            wanStatus: any(named: 'wanStatus'),
          )).thenReturn(_defaultUIValues());

      when(() => mockService.transformConnectedDevices(
            devices: any(named: 'devices'),
            deviceListNotifier: any(named: 'deviceListNotifier'),
          )).thenReturn([]);

      when(() => mockService.stopBlinkNodeLED())
          .thenThrow(const UnexpectedError(message: 'Network error'));

      container = createContainer(
        deviceManagerState: deviceManagerState,
        targetId: 'test-device-id',
      );

      // Act
      await container.read(nodeDetailProvider.notifier).toggleBlinkNode(true);

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - state should remain stopBlinking after error
      final state = container.read(nodeDetailProvider);
      expect(state.blinkingStatus, BlinkingStatus.stopBlinking);
    });
  });
}

LinksysDevice _createFallbackDevice() {
  return _createTestDevice('fallback-device');
}

LinksysDevice _createTestDevice(String deviceId, {bool isAuthority = false}) {
  return LinksysDevice(
    deviceID: deviceId,
    isAuthority: isAuthority,
    connections: const [],
    connectedDevices: const [],
    properties: const [],
    maxAllowedProperties: 100,
    lastChangeRevision: 0,
    model: const RawDeviceModel(deviceType: 'Infrastructure'),
    unit: const RawDeviceUnit(),
  );
}

Map<String, dynamic> _defaultUIValues() {
  return {
    'location': 'Test Location',
    'isMaster': false,
    'isOnline': true,
    'isWiredConnection': false,
    'signalStrength': -45,
    'serialNumber': 'TEST-SN',
    'modelNumber': 'TEST-MODEL',
    'firmwareVersion': '1.0.0',
    'hardwareVersion': '1',
    'lanIpAddress': '192.168.1.100',
    'wanIpAddress': '100.0.0.1',
    'upstreamDevice': 'Router',
    'isMLO': false,
    'macAddress': 'AA:BB:CC:DD:EE:FF',
  };
}
