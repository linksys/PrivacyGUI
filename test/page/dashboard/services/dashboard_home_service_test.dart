import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/services/dashboard_home_service.dart';

import '../../../mocks/test_data/dashboard_home_test_data.dart';

void main() {
  late DashboardHomeService service;

  setUp(() {
    service = const DashboardHomeService();
  });

  group('DashboardHomeService', () {
    group('buildDashboardHomeState', () {
      test('returns correct state with main WiFi networks grouped by band', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState(
          mainRadios: DashboardHomeTestData.createDefaultMainRadios(),
        );
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          deviceList: [
            DashboardHomeTestData.createMasterDevice(),
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-001',
              band: '2.4GHz',
            ),
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-002',
              band: '5GHz',
            ),
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-003',
              band: '5GHz',
            ),
          ],
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.wifis.length, 2); // Two bands: 2.4GHz and 5GHz
        expect(result.wifis.any((wifi) => wifi.ssid == 'TestNetwork'), true);
        expect(result.wifis.every((wifi) => !wifi.isGuest), true);

        // Verify WiFi items have correct structure
        for (final wifi in result.wifis) {
          expect(wifi.ssid.isNotEmpty, true);
          expect(wifi.radios.isNotEmpty, true);
        }
      });

      test('returns correct state with guest WiFi when guest radios exist', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState =
            DashboardHomeTestData.createWifiRadiosStateWithGuest();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          deviceList: [
            DashboardHomeTestData.createMasterDevice(),
            DashboardHomeTestData.createMainWifiDevice(deviceId: 'device-001'),
            DashboardHomeTestData.createGuestWifiDevice(
                deviceId: 'guest-device-001'),
          ],
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        final guestWifi =
            result.wifis.where((wifi) => wifi.isGuest).firstOrNull;
        expect(guestWifi, isNotNull);
        expect(guestWifi!.ssid, 'Guest-Network');
        expect(guestWifi.isGuest, true);
        expect(guestWifi.isEnabled, true);
      });

      test('returns empty WiFi list when no radios exist', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState(
          mainRadios: const [],
        );
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState(
          wanConnection: null,
          lanConnections: const [],
        );
        final systemStatsState =
            DashboardHomeTestData.createSystemStatsState(uptimes: 0);
        final deviceManagerState =
            DashboardHomeTestData.createEmptyDeviceManagerState();
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.wifis, isEmpty);
      });

      test('sets isAnyNodesOffline true when nodes are offline', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerStateWithOfflineNodes();
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.isAnyNodesOffline, true);
      });

      test('sets isAnyNodesOffline false when all nodes are online', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          deviceList: [
            DashboardHomeTestData.createMasterDevice(isOnline: true),
            DashboardHomeTestData.createSlaveDevice(isOnline: true),
          ],
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.isAnyNodesOffline, false);
      });

      test('sets isFirstPolling true when lastUpdateTime is zero', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createFirstPollingDeviceManagerState();
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.isFirstPolling, true);
      });

      test('sets isFirstPolling false when lastUpdateTime is non-zero', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          lastUpdateTime: 1234567890,
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.isFirstPolling, false);
      });

      test('handles null deviceInfo for port layout determination', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState(
          deviceInfo: null,
        );
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState();
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        // Should not throw and should return a valid state
        expect(result, isA<DashboardHomeState>());
        // isHorizontalLayout should have a default value (false) when deviceInfo is null
        expect(result.isHorizontalLayout, isA<bool>());
      });

      // ============================================
      // User Story 2 Tests (T020-T026)
      // ============================================

      test('correctly counts connected devices per band', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState(
          mainRadios: DashboardHomeTestData.createDefaultMainRadios(),
        );
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          deviceList: [
            DashboardHomeTestData.createMasterDevice(),
            // 2 devices on 2.4GHz
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-001',
              band: '2.4GHz',
            ),
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-002',
              band: '2.4GHz',
            ),
            // 3 devices on 5GHz
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-003',
              band: '5GHz',
            ),
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-004',
              band: '5GHz',
            ),
            DashboardHomeTestData.createMainWifiDevice(
              deviceId: 'device-005',
              band: '5GHz',
            ),
          ],
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        final wifi24 = result.wifis.firstWhere(
          (wifi) => wifi.radios.contains('RADIO_2.4GHz'),
        );
        final wifi5 = result.wifis.firstWhere(
          (wifi) => wifi.radios.contains('RADIO_5GHz'),
        );
        expect(wifi24.numOfConnectedDevices, 2);
        expect(wifi5.numOfConnectedDevices, 3);
      });

      test('does not add guest WiFi when guest radios are empty', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState(
          guestRadios: const [],
          isGuestNetworkEnabled:
              true, // Even if enabled, no radios = no guest WiFi
        );
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState();
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.wifis.any((wifi) => wifi.isGuest), false);
      });

      test('correctly extracts WAN type from wanStatus', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          wanStatus: DashboardHomeTestData.createWanStatus(wanType: 'PPPoE'),
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.wanType, 'PPPoE');
      });

      test('correctly extracts detectedWANType from wanStatus', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          wanStatus: DashboardHomeTestData.createWanStatus(
            detectedWANType: 'Bridge',
          ),
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.detectedWANType, 'Bridge');
      });

      test('correctly determines master icon from deviceList', () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceList = [
          DashboardHomeTestData.createMasterDevice(modelNumber: 'MX5300'),
        ];
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState(
          deviceList: deviceList,
        );
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceList,
        );

        // Assert
        // MX5300 should return a router icon (routerMx5300 -> routerMx5300)
        expect(result.masterIcon.isNotEmpty, true);
        expect(result.masterIcon, isNot('node'));
      });

      test('correctly determines horizontal port layout', () {
        // Arrange - LN11 has horizontal ports
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState(
          deviceInfo: DashboardHomeTestData.createNodeDeviceInfo(
            modelNumber: 'LN11',
            hardwareVersion: '1',
          ),
        );
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState();
        final systemStatsState = DashboardHomeTestData.createSystemStatsState();
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState();
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.isHorizontalLayout, true);
      });

      test('passes through uptime, wanConnection, lanConnections correctly',
          () {
        // Arrange
        final deviceInfoState = DashboardHomeTestData.createDeviceInfoState();
        final wifiRadiosState = DashboardHomeTestData.createWifiRadiosState();
        final ethernetPortsState =
            DashboardHomeTestData.createEthernetPortsState(
          wanConnection: 'Linked-100Mbps',
          lanConnections: ['Linked-1000Mbps', 'Linked-100Mbps', 'None', 'None'],
        );
        final systemStatsState = DashboardHomeTestData.createSystemStatsState(
          uptimes: 172800, // 2 days in seconds
        );
        final deviceManagerState =
            DashboardHomeTestData.createDeviceManagerState();
        final getBandForDevice =
            DashboardHomeTestData.createGetBandForDeviceCallback();

        // Act
        final result = service.buildDashboardHomeState(
          deviceInfoState: deviceInfoState,
          wifiRadiosState: wifiRadiosState,
          ethernetPortsState: ethernetPortsState,
          systemStatsState: systemStatsState,
          deviceManagerState: deviceManagerState,
          getBandForDevice: getBandForDevice,
          deviceList: deviceManagerState.deviceList,
        );

        // Assert
        expect(result.uptime, 172800);
        expect(result.wanPortConnection, 'Linked-100Mbps');
        expect(result.lanPortConnections.length, 4);
        expect(result.lanPortConnections[0], 'Linked-1000Mbps');
        expect(result.lanPortConnections[1], 'Linked-100Mbps');
      });
    });
  });
}
