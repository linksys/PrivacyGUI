import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';

import '../../../mocks/test_data/devices_test_data.dart';

void main() {
  group('ClientDevice', () {
    // =========================================================================
    // NetworkEntity Implementation
    // =========================================================================

    group('NetworkEntity implementation', () {
      test('id returns mac', () {
        final device = DevicesTestData.createWifiClient(
          mac: DevicesTestData.clientMac1,
        );

        expect(device.id, DevicesTestData.clientMac1);
      });

      test('isOnline returns isActive', () {
        final online = DevicesTestData.createWifiClient(isActive: true);
        final offline = DevicesTestData.createWifiClient(isActive: false);

        expect(online.isOnline, isTrue);
        expect(offline.isOnline, isFalse);
      });

      test('ipAddress returns ip if not empty', () {
        final withIp = DevicesTestData.createWifiClient(ip: '192.168.1.100');
        final noIp = ClientDevice(
          mac: DevicesTestData.clientMac1,
          hostName: 'test',
          isActive: true,
          ip: '',
          connectionType: ConnectionType.wifi,
        );

        expect(withIp.ipAddress, '192.168.1.100');
        expect(noIp.ipAddress, isNull);
      });
    });

    // =========================================================================
    // displayName Priority
    // =========================================================================

    group('displayName', () {
      test('returns friendlyName when set', () {
        final device = DevicesTestData.createWifiClient(
          friendlyName: 'My MacBook',
          hostName: 'MacBook-Pro',
          mac: DevicesTestData.clientMac1,
        );

        expect(device.displayName, 'My MacBook');
      });

      test('returns hostName when friendlyName is null', () {
        final device = DevicesTestData.createWifiClient(
          friendlyName: null,
          hostName: 'MacBook-Pro',
          mac: DevicesTestData.clientMac1,
        );

        expect(device.displayName, 'MacBook-Pro');
      });

      test('returns hostName when friendlyName is empty', () {
        final device = ClientDevice(
          mac: DevicesTestData.clientMac1,
          hostName: 'MacBook-Pro',
          friendlyName: '',
          isActive: true,
          ip: '192.168.1.100',
          connectionType: ConnectionType.wifi,
        );

        expect(device.displayName, 'MacBook-Pro');
      });

      test('returns mac when both friendlyName and hostName are empty', () {
        final device = ClientDevice(
          mac: DevicesTestData.clientMac1,
          hostName: '',
          friendlyName: '',
          isActive: true,
          ip: '192.168.1.100',
          connectionType: ConnectionType.wifi,
        );

        expect(device.displayName, DevicesTestData.clientMac1);
      });
    });

    // =========================================================================
    // WiFi Properties
    // =========================================================================

    group('WiFi properties', () {
      test('isWifi returns true for WiFi connection', () {
        final wifi = DevicesTestData.createWifiClient();
        final wired = DevicesTestData.createWiredClient();

        expect(wifi.isWifi, isTrue);
        expect(wired.isWifi, isFalse);
      });

      test('signalStrength delegates to wifi', () {
        final withSignal = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(signalStrength: -50),
        );
        final noWifi = DevicesTestData.createWiredClient();

        expect(withSignal.signalStrength, -50);
        expect(noWifi.signalStrength, isNull);
      });

      test('signalQuality delegates to wifi with default 0', () {
        final withWifi = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(signalStrength: -50),
        );
        final noWifi = DevicesTestData.createWiredClient();

        expect(withWifi.signalQuality, greaterThan(0));
        expect(noWifi.signalQuality, 0);
      });

      test('signalLevel delegates to wifi with default 0', () {
        final excellent = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createExcellentSignal(),
        );
        final poor = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createPoorSignal(),
        );
        final wired = DevicesTestData.createWiredClient();

        expect(excellent.signalLevel, 3);
        expect(poor.signalLevel, 0);
        expect(wired.signalLevel, 0);
      });

      test('band delegates to wifi', () {
        final wifi5g = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(band: '5GHz'),
        );
        final wifi24g = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(band: '2.4GHz'),
        );
        final wired = DevicesTestData.createWiredClient();

        expect(wifi5g.band, '5GHz');
        expect(wifi24g.band, '2.4GHz');
        expect(wired.band, isNull);
      });

      test('ssidName delegates to wifi', () {
        final withSsid = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(ssidName: 'MyNetwork'),
        );
        final wired = DevicesTestData.createWiredClient();

        expect(withSsid.ssidName, 'MyNetwork');
        expect(wired.ssidName, isNull);
      });

      test('hasWifiData returns false when wifi is null', () {
        final wired = DevicesTestData.createWiredClient();
        expect(wired.hasWifiData, isFalse);
      });

      test('hasWifiData returns true when wifi has data', () {
        final wifi = DevicesTestData.createWifiClient();
        expect(wifi.hasWifiData, isTrue);
      });
    });

    // =========================================================================
    // Throughput
    // =========================================================================

    group('throughput', () {
      test('downlinkRate delegates to wifi', () {
        final wifi = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(downlinkRate: 866000),
        );
        expect(wifi.downlinkRate, 866000);
      });

      test('uplinkRate delegates to wifi', () {
        final wifi = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(uplinkRate: 433000),
        );
        expect(wifi.uplinkRate, 433000);
      });

      test('totalThroughput sums uplink and downlink', () {
        final wifi = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createWifiInfo(
            downlinkRate: 866000,
            uplinkRate: 433000,
          ),
        );
        expect(wifi.totalThroughput, 866000 + 433000);
      });

      test('totalThroughput handles null rates', () {
        final wifi = DevicesTestData.createWifiClient(
          wifi: const WifiConnectionInfo(),
        );
        expect(wifi.totalThroughput, 0);
      });
    });

    // =========================================================================
    // Multi-Interface
    // =========================================================================

    group('multi-interface', () {
      test('hasMultipleInterfaces returns false when no additional interfaces',
          () {
        final device = DevicesTestData.createWifiClient();
        expect(device.hasMultipleInterfaces, isFalse);
      });

      test('hasMultipleInterfaces returns true when has additional interfaces',
          () {
        final device = DevicesTestData.createMultiInterfaceClient();
        expect(device.hasMultipleInterfaces, isTrue);
      });

      test('allMacAddresses includes primary and additional MACs', () {
        final device = DevicesTestData.createMultiInterfaceClient(
          mac: DevicesTestData.clientMac1,
          additionalInterfaces: [
            DevicesTestData.createWiredInterface(mac: 'FF:FF:FF:FF:FF:01'),
            DevicesTestData.createWifiInterface(mac: 'FF:FF:FF:FF:FF:02'),
          ],
        );

        expect(device.allMacAddresses, hasLength(3));
        expect(device.allMacAddresses, contains(DevicesTestData.clientMac1));
        expect(device.allMacAddresses, contains('FF:FF:FF:FF:FF:01'));
        expect(device.allMacAddresses, contains('FF:FF:FF:FF:FF:02'));
      });

      test('interfaceCount returns correct count', () {
        final single = DevicesTestData.createWifiClient();
        final multi = DevicesTestData.createMultiInterfaceClient(
          additionalInterfaces: [
            DevicesTestData.createWiredInterface(),
            DevicesTestData.createWifiInterface(),
          ],
        );

        expect(single.interfaceCount, 1);
        expect(multi.interfaceCount, 3);
      });

      test('hasAnyActiveInterface checks primary and additional', () {
        final allInactive = ClientDevice(
          mac: DevicesTestData.clientMac1,
          hostName: 'test',
          isActive: false,
          ip: '',
          connectionType: ConnectionType.wifi,
          additionalInterfaces: [
            DevicesTestData.createWiredInterface(isActive: false),
          ],
        );
        final oneActive = ClientDevice(
          mac: DevicesTestData.clientMac1,
          hostName: 'test',
          isActive: false,
          ip: '',
          connectionType: ConnectionType.wifi,
          additionalInterfaces: [
            DevicesTestData.createWiredInterface(isActive: true),
          ],
        );

        expect(allInactive.hasAnyActiveInterface, isFalse);
        expect(oneActive.hasAnyActiveInterface, isTrue);
      });
    });

    // =========================================================================
    // Display Logic
    // =========================================================================

    group('display logic', () {
      test('hasSignalDisplay requires WiFi + online + signalStrength', () {
        final valid = DevicesTestData.createWifiClient(
          isActive: true,
          wifi: DevicesTestData.createWifiInfo(signalStrength: -50),
        );
        final offline = DevicesTestData.createWifiClient(
          isActive: false,
          wifi: DevicesTestData.createWifiInfo(signalStrength: -50),
        );
        final noSignal = DevicesTestData.createWifiClient(
          isActive: true,
          wifi: const WifiConnectionInfo(),
        );
        final wired = DevicesTestData.createWiredClient(isActive: true);

        expect(valid.hasSignalDisplay, isTrue);
        expect(offline.hasSignalDisplay, isFalse);
        expect(noSignal.hasSignalDisplay, isFalse);
        expect(wired.hasSignalDisplay, isFalse);
      });

      test('shouldShowWifiDetails requires WiFi + online + (data OR signal)',
          () {
        final withData = DevicesTestData.createWifiClient(isActive: true);
        final offline = DevicesTestData.createWifiClient(isActive: false);
        final wired = DevicesTestData.createWiredClient(isActive: true);

        expect(withData.shouldShowWifiDetails, isTrue);
        expect(offline.shouldShowWifiDetails, isFalse);
        expect(wired.shouldShowWifiDetails, isFalse);
      });

      test('isInteractive returns isActive', () {
        final active = DevicesTestData.createWifiClient(isActive: true);
        final inactive = DevicesTestData.createWifiClient(isActive: false);

        expect(active.isInteractive, isTrue);
        expect(inactive.isInteractive, isFalse);
      });

      test('displayOpacity returns 1.0 for online, 0.5 for offline', () {
        final online = DevicesTestData.createWifiClient(isActive: true);
        final offline = DevicesTestData.createWifiClient(isActive: false);

        expect(online.displayOpacity, 1.0);
        expect(offline.displayOpacity, 0.5);
      });
    });

    // =========================================================================
    // List Extensions
    // =========================================================================

    group('List<ClientDevice> extensions', () {
      late List<ClientDevice> devices;

      setUp(() {
        devices = DevicesTestData.createMixedClientList();
      });

      test('online filters active devices', () {
        final online = devices.online;

        expect(online, hasLength(2));
        expect(online.every((d) => d.isOnline), isTrue);
      });

      test('offline filters inactive devices', () {
        final offline = devices.offline;

        expect(offline, hasLength(2));
        expect(offline.every((d) => !d.isOnline), isTrue);
      });

      test('wifiDevices filters WiFi devices', () {
        final wifi = devices.wifiDevices;

        expect(wifi, hasLength(3));
        expect(wifi.every((d) => d.isWifi), isTrue);
      });

      test('wiredDevices filters wired devices', () {
        final wired = devices.wiredDevices;

        expect(wired, hasLength(1));
        expect(wired.every((d) => !d.isWifi), isTrue);
      });
    });

    // =========================================================================
    // Equatable
    // =========================================================================

    group('Equatable', () {
      test('equal devices are equal', () {
        final device1 = DevicesTestData.createWifiClient(
          mac: DevicesTestData.clientMac1,
          hostName: 'Test',
        );
        final device2 = DevicesTestData.createWifiClient(
          mac: DevicesTestData.clientMac1,
          hostName: 'Test',
        );

        expect(device1, equals(device2));
      });

      test('different mac are not equal', () {
        final device1 =
            DevicesTestData.createWifiClient(mac: '11:11:11:11:11:11');
        final device2 =
            DevicesTestData.createWifiClient(mac: '22:22:22:22:22:22');

        expect(device1, isNot(equals(device2)));
      });

      test('different isActive are not equal', () {
        final device1 = DevicesTestData.createWifiClient(isActive: true);
        final device2 = DevicesTestData.createWifiClient(isActive: false);

        expect(device1, isNot(equals(device2)));
      });
    });

    // =========================================================================
    // copyWith
    // =========================================================================

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final original = DevicesTestData.createWifiClient();
        final copied = original.copyWith();

        expect(copied, equals(original));
      });

      test('updates specified fields', () {
        final original = DevicesTestData.createWifiClient(
          mac: DevicesTestData.clientMac1,
          isActive: true,
        );
        final copied = original.copyWith(
          mac: 'NEW:MAC:ADDR',
          isActive: false,
        );

        expect(copied.mac, 'NEW:MAC:ADDR');
        expect(copied.isActive, isFalse);
        expect(copied.hostName, original.hostName);
      });
    });
  });

  // ===========================================================================
  // WifiConnectionInfo
  // ===========================================================================

  group('WifiConnectionInfo', () {
    test('signalQuality normalizes to 0.0-1.0 range', () {
      final excellent = DevicesTestData.createWifiInfo(signalStrength: -30);
      final poor = DevicesTestData.createWifiInfo(signalStrength: -90);
      final veryPoor = DevicesTestData.createWifiInfo(signalStrength: -100);
      final noSignal = const WifiConnectionInfo();

      expect(excellent.signalQuality, 1.0);
      expect(poor.signalQuality, 0.0);
      expect(veryPoor.signalQuality, 0.0);
      expect(noSignal.signalQuality, 0.0);
    });

    test('signalLevel maps to 0-3 scale', () {
      final excellent = DevicesTestData.createExcellentSignal();
      final good = DevicesTestData.createGoodSignal();
      final fair = DevicesTestData.createFairSignal();
      final poor = DevicesTestData.createPoorSignal();

      expect(excellent.signalLevel, 3);
      expect(good.signalLevel, 2);
      expect(fair.signalLevel, 1);
      expect(poor.signalLevel, 0);
    });

    test('totalThroughput sums rates', () {
      final wifi = DevicesTestData.createWifiInfo(
        downlinkRate: 100,
        uplinkRate: 50,
      );
      expect(wifi.totalThroughput, 150);
    });

    test('hasData returns true when any field is set', () {
      final withSignal = DevicesTestData.createWifiInfo(
        signalStrength: -50,
        band: null,
        ssidName: null,
        downlinkRate: null,
        uplinkRate: null,
      );
      final empty = const WifiConnectionInfo();

      expect(withSignal.hasData, isTrue);
      expect(empty.hasData, isFalse);
    });
  });

  // ===========================================================================
  // ClientInterfaceInfo
  // ===========================================================================

  group('ClientInterfaceInfo', () {
    test('isWifi returns true for WiFi connection type', () {
      final wifi = DevicesTestData.createWifiInterface();
      final wired = DevicesTestData.createWiredInterface();

      expect(wifi.isWifi, isTrue);
      expect(wired.isWifi, isFalse);
    });

    test('signalStrength delegates to wifi', () {
      final wifi = DevicesTestData.createWifiInterface(
        wifi: DevicesTestData.createWifiInfo(signalStrength: -55),
      );
      expect(wifi.signalStrength, -55);
    });

    test('band delegates to wifi', () {
      final wifi = DevicesTestData.createWifiInterface(
        wifi: DevicesTestData.createWifiInfo(band: '6GHz'),
      );
      expect(wifi.band, '6GHz');
    });
  });
}
