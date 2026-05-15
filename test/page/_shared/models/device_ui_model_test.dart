import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // DeviceInterfaceInfo
  // ---------------------------------------------------------------------------

  group('DeviceInterfaceInfo', () {
    test('equality based on all fields', () {
      const iface1 = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        isWifi: true,
        isActive: true,
        layer1Interface: 'Device.WiFi.Radio.1',
        band: '5GHz',
        ssidName: 'MyNetwork',
        signalStrength: -55,
      );
      const iface2 = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        isWifi: true,
        isActive: true,
        layer1Interface: 'Device.WiFi.Radio.1',
        band: '5GHz',
        ssidName: 'MyNetwork',
        signalStrength: -55,
      );
      const iface3 = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:02', // Different MAC
        ip: '192.168.1.100',
        isWifi: true,
        isActive: true,
        layer1Interface: 'Device.WiFi.Radio.1',
      );

      expect(iface1, equals(iface2));
      expect(iface1, isNot(equals(iface3)));
    });

    test('props includes all fields', () {
      const iface = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        isWifi: true,
        isActive: false,
        layer1Interface: 'Device.Ethernet.Interface.1',
        band: null,
        ssidName: null,
        signalStrength: null,
      );

      expect(iface.props, hasLength(8));
      expect(iface.props, contains('AA:BB:CC:DD:EE:01'));
      expect(iface.props, contains('192.168.1.100'));
      expect(iface.props, contains(true)); // isWifi
      expect(iface.props, contains(false)); // isActive
    });
  });

  // ---------------------------------------------------------------------------
  // DeviceUIModel — Multi-Interface Getters
  // ---------------------------------------------------------------------------

  group('DeviceUIModel — multi-interface getters', () {
    const baseDevice = DeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01',
      ip: '192.168.1.100',
      hostName: 'MacBook',
      isActive: true,
      isWifi: true,
      signalStrength: -55,
    );

    const additionalInterface = DeviceInterfaceInfo(
      mac: 'AA:BB:CC:DD:EE:02',
      ip: '192.168.1.101',
      isWifi: false,
      isActive: true,
      layer1Interface: 'Device.Ethernet.Interface.1',
    );

    test('hasMultipleInterfaces is false when no additional interfaces', () {
      expect(baseDevice.hasMultipleInterfaces, isFalse);
    });

    test('hasMultipleInterfaces is true when additional interfaces exist', () {
      final multiDevice =
          baseDevice.copyWith(additionalInterfaces: [additionalInterface]);
      expect(multiDevice.hasMultipleInterfaces, isTrue);
    });

    test('allMacAddresses returns only primary MAC when no additional', () {
      expect(baseDevice.allMacAddresses, ['AA:BB:CC:DD:EE:01']);
    });

    test('allMacAddresses returns primary + additional MACs', () {
      const secondInterface = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:03',
        ip: '192.168.1.102',
        isWifi: true,
        isActive: true,
        layer1Interface: 'Device.WiFi.Radio.2',
      );
      final multiDevice = baseDevice.copyWith(
        additionalInterfaces: [additionalInterface, secondInterface],
      );

      expect(multiDevice.allMacAddresses, [
        'AA:BB:CC:DD:EE:01',
        'AA:BB:CC:DD:EE:02',
        'AA:BB:CC:DD:EE:03',
      ]);
    });

    test('interfaceCount is 1 when no additional interfaces', () {
      expect(baseDevice.interfaceCount, 1);
    });

    test('interfaceCount is 1 + additionalInterfaces.length', () {
      final multiDevice =
          baseDevice.copyWith(additionalInterfaces: [additionalInterface]);
      expect(multiDevice.interfaceCount, 2);
    });

    test('hasAnyActiveInterface is true when primary is active', () {
      expect(baseDevice.hasAnyActiveInterface, isTrue);
    });

    test('hasAnyActiveInterface is true when only additional is active', () {
      const inactiveDevice = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'MacBook',
        isActive: false,
        isWifi: true,
      );
      final multiDevice = inactiveDevice.copyWith(
        additionalInterfaces: [additionalInterface], // isActive: true
      );
      expect(multiDevice.hasAnyActiveInterface, isTrue);
    });

    test('hasAnyActiveInterface is false when all interfaces inactive', () {
      const inactiveDevice = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'MacBook',
        isActive: false,
        isWifi: true,
      );
      const inactiveInterface = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:02',
        ip: '192.168.1.101',
        isWifi: false,
        isActive: false,
        layer1Interface: 'Device.Ethernet.Interface.1',
      );
      final multiDevice = inactiveDevice.copyWith(
        additionalInterfaces: [inactiveInterface],
      );
      expect(multiDevice.hasAnyActiveInterface, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // DeviceUIModel — copyWith
  // ---------------------------------------------------------------------------

  group('DeviceUIModel — copyWith', () {
    const baseDevice = DeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01',
      ip: '192.168.1.100',
      hostName: 'MacBook',
      isActive: true,
      isWifi: true,
    );

    test('copyWith preserves unchanged fields', () {
      final copied = baseDevice.copyWith(ip: '192.168.1.200');
      expect(copied.mac, 'AA:BB:CC:DD:EE:01');
      expect(copied.hostName, 'MacBook');
      expect(copied.isActive, isTrue);
      expect(copied.isWifi, isTrue);
      expect(copied.ip, '192.168.1.200');
    });

    test('copyWith additionalInterfaces replaces list', () {
      const iface = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:02',
        ip: '192.168.1.101',
        isWifi: false,
        isActive: true,
        layer1Interface: 'Device.Ethernet.Interface.1',
      );
      final copied = baseDevice.copyWith(additionalInterfaces: [iface]);
      expect(copied.additionalInterfaces, [iface]);
      expect(copied.hasMultipleInterfaces, isTrue);
    });

    test('copyWith returns equal object when no changes', () {
      final copied = baseDevice.copyWith();
      expect(copied, equals(baseDevice));
    });
  });

  // ---------------------------------------------------------------------------
  // DeviceUIModel — Equatable
  // ---------------------------------------------------------------------------

  group('DeviceUIModel — Equatable', () {
    test('equality includes additionalInterfaces', () {
      const device1 = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'MacBook',
        isActive: true,
        isWifi: true,
      );
      const device2 = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'MacBook',
        isActive: true,
        isWifi: true,
      );
      const iface = DeviceInterfaceInfo(
        mac: 'AA:BB:CC:DD:EE:02',
        ip: '192.168.1.101',
        isWifi: false,
        isActive: true,
        layer1Interface: 'Device.Ethernet.Interface.1',
      );
      const device3 = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'MacBook',
        isActive: true,
        isWifi: true,
        additionalInterfaces: [iface],
      );

      expect(device1, equals(device2));
      expect(device1, isNot(equals(device3)));
    });
  });

  // ---------------------------------------------------------------------------
  // DeviceUIModel — Other Getters
  // ---------------------------------------------------------------------------

  group('DeviceUIModel — displayName', () {
    test('displayName prefers friendlyName over hostName', () {
      const device = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'macbook-pro',
        friendlyName: "Austin's MacBook",
        isActive: true,
        isWifi: true,
      );
      expect(device.displayName, "Austin's MacBook");
    });

    test('displayName uses hostName when friendlyName is empty', () {
      const device = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'macbook-pro',
        friendlyName: '',
        isActive: true,
        isWifi: true,
      );
      expect(device.displayName, 'macbook-pro');
    });

    test('displayName falls back to MAC when hostName is empty', () {
      const device = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: '',
        isActive: true,
        isWifi: true,
      );
      expect(device.displayName, 'AA:BB:CC:DD:EE:01');
    });
  });

  group('DeviceUIModel — isClientDevice', () {
    test('isClientDevice is true for null deviceRole', () {
      const device = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'iPhone',
        isActive: true,
        isWifi: true,
        deviceRole: null,
      );
      expect(device.isClientDevice, isTrue);
    });

    test('isClientDevice is false for master role', () {
      const device = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'MR7500',
        isActive: true,
        isWifi: false,
        deviceRole: 'master',
      );
      expect(device.isClientDevice, isFalse);
    });

    test('isClientDevice is false for slave role', () {
      const device = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.100',
        hostName: 'MX5500',
        isActive: true,
        isWifi: false,
        deviceRole: 'slave',
      );
      expect(device.isClientDevice, isFalse);
    });
  });
}
