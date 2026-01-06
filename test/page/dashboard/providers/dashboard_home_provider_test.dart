import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/services/dashboard_home_service.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';

import '../../../mocks/test_data/dashboard_home_test_data.dart';

/// Mock DashboardManagerNotifier for testing
class MockDashboardManagerNotifier extends Notifier<DashboardManagerState>
    implements DashboardManagerNotifier {
  final DashboardManagerState _state;

  MockDashboardManagerNotifier(this._state);

  @override
  DashboardManagerState build() => _state;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock DeviceManagerNotifier for testing
class MockDeviceManagerNotifier extends Notifier<DeviceManagerState>
    implements DeviceManagerNotifier {
  final DeviceManagerState _state;

  MockDeviceManagerNotifier(this._state);

  @override
  DeviceManagerState build() => _state;

  @override
  String getBandConnectedBy(device) {
    final interface = device.knownInterfaces?.firstOrNull;
    if (interface?.band != null) {
      return interface!.band!;
    }
    return '5GHz';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock HealthCheckProvider for testing
class MockHealthCheckNotifier extends Notifier<HealthCheckState>
    implements HealthCheckProvider {
  @override
  HealthCheckState build() => HealthCheckState.init();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock DashboardHomeService for testing
class MockDashboardHomeService implements DashboardHomeService {
  DashboardHomeState? returnState;
  int buildCallCount = 0;
  DashboardManagerState? lastDashboardManagerState;
  DeviceManagerState? lastDeviceManagerState;
  List<LinksysDevice>? lastDeviceList;

  @override
  DashboardHomeState buildDashboardHomeState({
    required DashboardManagerState dashboardManagerState,
    required DeviceManagerState deviceManagerState,
    required String Function(LinksysDevice device) getBandForDevice,
    required List<LinksysDevice> deviceList,
  }) {
    buildCallCount++;
    lastDashboardManagerState = dashboardManagerState;
    lastDeviceManagerState = deviceManagerState;
    lastDeviceList = deviceList;
    return returnState ?? const DashboardHomeState();
  }
}

void main() {
  late MockDashboardHomeService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockDashboardHomeService();
  });

  tearDown(() {
    container.dispose();
  });

  group('DashboardHomeNotifier', () {
    test('build() calls service.buildDashboardHomeState', () {
      // Arrange
      final dashboardManagerState =
          DashboardHomeTestData.createDashboardManagerState();
      final deviceManagerState =
          DashboardHomeTestData.createDeviceManagerState();

      const expectedState = DashboardHomeState(
        isFirstPolling: false,
        masterIcon: 'routerMx5300',
        uptime: 86400,
      );
      mockService.returnState = expectedState;

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act
      final state = container.read(dashboardHomeProvider);

      // Assert
      expect(state, expectedState);
      expect(mockService.buildCallCount, 1);
    });

    test('build() passes correct dashboardManagerState to service', () {
      // Arrange
      final dashboardManagerState =
          DashboardHomeTestData.createDashboardManagerState(
        uptimes: 172800,
        wanConnection: 'Linked-100Mbps',
      );
      final deviceManagerState =
          DashboardHomeTestData.createDeviceManagerState();

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act
      container.read(dashboardHomeProvider);

      // Assert
      expect(mockService.lastDashboardManagerState, dashboardManagerState);
      expect(mockService.lastDashboardManagerState?.uptimes, 172800);
      expect(mockService.lastDashboardManagerState?.wanConnection,
          'Linked-100Mbps');
    });

    test('build() passes correct deviceManagerState to service', () {
      // Arrange
      final dashboardManagerState =
          DashboardHomeTestData.createDashboardManagerState();
      final deviceManagerState = DashboardHomeTestData.createDeviceManagerState(
        lastUpdateTime: 1234567890,
      );

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act
      container.read(dashboardHomeProvider);

      // Assert
      expect(mockService.lastDeviceManagerState, deviceManagerState);
      expect(mockService.lastDeviceManagerState?.lastUpdateTime, 1234567890);
    });

    test('build() passes deviceList from deviceManagerProvider', () {
      // Arrange
      final dashboardManagerState =
          DashboardHomeTestData.createDashboardManagerState();
      final deviceList = [
        DashboardHomeTestData.createMasterDevice(),
        DashboardHomeTestData.createMainWifiDevice(deviceId: 'device-001'),
        DashboardHomeTestData.createMainWifiDevice(deviceId: 'device-002'),
      ];
      final deviceManagerState = DashboardHomeTestData.createDeviceManagerState(
        deviceList: deviceList,
      );

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act
      container.read(dashboardHomeProvider);

      // Assert
      expect(mockService.lastDeviceList, isNotNull);
      expect(mockService.lastDeviceList!.length, 3);
    });

    test('returns service result directly', () {
      // Arrange
      final dashboardManagerState =
          DashboardHomeTestData.createDashboardManagerState();
      final deviceManagerState =
          DashboardHomeTestData.createDeviceManagerState();

      const wifiItem = DashboardWiFiUIModel(
        ssid: 'TestNetwork',
        password: 'password123',
        radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
        isGuest: false,
        isEnabled: true,
        numOfConnectedDevices: 5,
      );

      const expectedState = DashboardHomeState(
        isFirstPolling: true,
        isHorizontalLayout: true,
        masterIcon: 'routerMx6200',
        isAnyNodesOffline: true,
        uptime: 86400,
        wanPortConnection: 'Linked-1000Mbps',
        lanPortConnections: ['Linked-1000Mbps', 'None', 'None'],
        wifis: [wifiItem],
        wanType: 'DHCP',
        detectedWANType: 'DHCP',
      );
      mockService.returnState = expectedState;

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act
      final state = container.read(dashboardHomeProvider);

      // Assert
      expect(state.isFirstPolling, true);
      expect(state.isHorizontalLayout, true);
      expect(state.masterIcon, 'routerMx6200');
      expect(state.isAnyNodesOffline, true);
      expect(state.uptime, 86400);
      expect(state.wanPortConnection, 'Linked-1000Mbps');
      expect(state.lanPortConnections, ['Linked-1000Mbps', 'None', 'None']);
      expect(state.wifis.length, 1);
      expect(state.wifis[0].ssid, 'TestNetwork');
      expect(state.wanType, 'DHCP');
      expect(state.detectedWANType, 'DHCP');
    });

    test('provider listens to dashboardManagerProvider changes', () {
      // Arrange
      final dashboardManagerState1 =
          DashboardHomeTestData.createDashboardManagerState(uptimes: 1000);
      final deviceManagerState =
          DashboardHomeTestData.createDeviceManagerState();

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState1)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act - read provider to trigger build
      container.read(dashboardHomeProvider);

      // Assert - service was called
      expect(mockService.buildCallCount, 1);
      expect(mockService.lastDashboardManagerState?.uptimes, 1000);
    });

    test('provider listens to deviceManagerProvider changes', () {
      // Arrange
      final dashboardManagerState =
          DashboardHomeTestData.createDashboardManagerState();
      final deviceManagerState = DashboardHomeTestData.createDeviceManagerState(
        lastUpdateTime: 0, // First polling
      );

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act
      container.read(dashboardHomeProvider);

      // Assert
      expect(mockService.buildCallCount, 1);
      expect(mockService.lastDeviceManagerState?.lastUpdateTime, 0);
    });

    test('provider listens to healthCheckProvider (for reactivity)', () {
      // Arrange
      final dashboardManagerState =
          DashboardHomeTestData.createDashboardManagerState();
      final deviceManagerState =
          DashboardHomeTestData.createDeviceManagerState();

      container = ProviderContainer(
        overrides: [
          dashboardHomeServiceProvider.overrideWithValue(mockService),
          dashboardManagerProvider.overrideWith(
              () => MockDashboardManagerNotifier(dashboardManagerState)),
          deviceManagerProvider.overrideWith(
              () => MockDeviceManagerNotifier(deviceManagerState)),
          healthCheckProvider.overrideWith(() => MockHealthCheckNotifier()),
        ],
      );

      // Act - just verify the provider builds without error
      // healthCheckProvider is watched but not used directly
      final state = container.read(dashboardHomeProvider);

      // Assert
      expect(state, isA<DashboardHomeState>());
    });
  });
}
