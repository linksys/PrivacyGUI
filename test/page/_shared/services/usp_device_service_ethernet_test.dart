import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

EthernetInterface _iface({
  String path = 'Device.Ethernet.Interface.1.',
  String name = 'eth0',
  String status = 'Up',
  bool upstream = false,
  int bitRate = 1000,
}) =>
    EthernetInterface(
      instancePath: path,
      name: name,
      status: status,
      upstream: upstream,
      currentBitRate: bitRate,
    );

DeviceUIModel _device({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String ip = '192.168.1.10',
  String hostName = 'laptop',
  bool isActive = true,
  bool isWifi = false,
}) =>
    DeviceUIModel(
      mac: mac,
      ip: ip,
      hostName: hostName,
      isActive: isActive,
      isWifi: isWifi,
    );

void main() {
  late UspDeviceService svc;

  setUp(() {
    svc = UspDeviceService();
  });

  // -----------------------------------------------------------------------
  // WAN / LAN classification (bridge membership)
  // -----------------------------------------------------------------------
  group('WAN / LAN classification', () {
    test('interface not in bridge map is WAN', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.2.', name: 'eth0'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        bridgePortMap: {
          // Only Interface.1 is a bridge member — Interface.2 is NOT
          'Device.Bridging.Bridge.1.Port.1.': 'Device.Ethernet.Interface.1.',
        },
      );

      expect(result.length, 1);
      expect(result.first.isWan, isTrue);
      expect(result.first.label, 'WAN');
    });

    test('interface in bridge map is LAN', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.1.', name: 'eth1'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        bridgePortMap: {
          'Device.Bridging.Bridge.1.Port.1.': 'Device.Ethernet.Interface.1.',
        },
      );

      expect(result.length, 1);
      expect(result.first.isWan, isFalse);
      expect(result.first.label, 'LAN');
    });

    test('M60TB: upstream flag ignored, bridge membership used', () {
      // M60TB: Interface.1 (eth1) has Upstream=true but is LAN
      //        Interface.2 (eth0) has Upstream=false but is WAN
      final interfaces = EthernetInterfaces(items: [
        _iface(
            path: 'Device.Ethernet.Interface.1.', name: 'eth1', upstream: true),
        _iface(
            path: 'Device.Ethernet.Interface.2.',
            name: 'eth0',
            upstream: false),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        bridgePortMap: {
          'Device.Bridging.Bridge.1.Port.1.': 'Device.Ethernet.Interface.1.',
        },
      );

      final wan = result.where((p) => p.isWan).toList();
      final lan = result.where((p) => !p.isWan).toList();

      expect(wan.length, 1);
      expect(wan.first.name, 'eth0'); // Interface.2
      expect(lan.length, 1);
      expect(lan.first.name, 'eth1'); // Interface.1 (bridge member)
    });
  });

  // -----------------------------------------------------------------------
  // WAN port status
  // -----------------------------------------------------------------------
  group('WAN port status', () {
    test('isUp reflects status field', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(
            path: 'Device.Ethernet.Interface.2.', name: 'eth0', status: 'Up'),
        _iface(
            path: 'Device.Ethernet.Interface.3.', name: 'eth2', status: 'Down'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        // No bridge members — both are WAN
      );

      expect(result.length, 2);
      expect(result[0].isUp, isTrue);
      expect(result[1].isUp, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // LAN port entries
  // -----------------------------------------------------------------------
  group('LAN port entries', () {
    final bridgeMap = {
      'Device.Bridging.Bridge.1.Port.1.': 'Device.Ethernet.Interface.1.',
    };

    test('no wired devices — single LAN entry', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.1.', name: 'eth1'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        bridgePortMap: bridgeMap,
      );

      expect(result.length, 1);
      expect(result.first.label, 'LAN');
      expect(result.first.isWan, isFalse);
      expect(result.first.connectedDevices, isEmpty);
    });

    test('one wired device — LAN 1 with device info', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.1.', name: 'eth1'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [
          _device(mac: 'AA:BB:CC:DD:EE:FF', hostName: 'laptop'),
        ],
        bridgePortMap: bridgeMap,
      );

      expect(result.length, 1);
      expect(result.first.label, 'LAN 1');
      expect(result.first.connectedDevices.length, 1);
      expect(result.first.connectedDevices.first.hostName, 'laptop');
      expect(
          result.first.connectedDevices.first.macAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('multiple wired devices — LAN 1, LAN 2, LAN 3', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.1.', name: 'eth1'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [
          _device(mac: 'AA:00:00:00:00:01', hostName: 'pc1'),
          _device(mac: 'AA:00:00:00:00:02', hostName: 'pc2'),
          _device(mac: 'AA:00:00:00:00:03', hostName: 'pc3'),
        ],
        bridgePortMap: bridgeMap,
      );

      expect(result.length, 3);
      expect(result[0].label, 'LAN 1');
      expect(result[1].label, 'LAN 2');
      expect(result[2].label, 'LAN 3');
    });

    test('only active wired devices become ports', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.1.', name: 'eth1'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [
          _device(isActive: true, hostName: 'active-pc'),
          _device(
              isActive: false,
              hostName: 'inactive-pc',
              mac: 'BB:00:00:00:00:01'),
        ],
        bridgePortMap: bridgeMap,
      );

      expect(result.length, 1);
      expect(result.first.connectedDevices.first.hostName, 'active-pc');
    });

    test('WiFi devices excluded from LAN ports', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.1.', name: 'eth1'),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [
          _device(isWifi: true, hostName: 'phone'),
        ],
        bridgePortMap: bridgeMap,
      );

      // WiFi device excluded — falls to empty wired list → single LAN entry
      expect(result.length, 1);
      expect(result.first.label, 'LAN');
      expect(result.first.connectedDevices, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // Path normalization
  // -----------------------------------------------------------------------
  group('path normalization', () {
    test('trailing dot added to bridge map values for matching', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(path: 'Device.Ethernet.Interface.1.', name: 'eth1'),
      ]);

      // Bridge map value WITHOUT trailing dot — should still match
      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        bridgePortMap: {
          'Device.Bridging.Bridge.1.Port.1.': 'Device.Ethernet.Interface.1',
        },
      );

      expect(result.length, 1);
      expect(result.first.isWan, isFalse); // Matched as LAN
    });
  });

  // -----------------------------------------------------------------------
  // Edge cases
  // -----------------------------------------------------------------------
  group('edge cases', () {
    test('empty inputs return empty result', () {
      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: EthernetInterfaces(items: []),
        deviceModels: [],
      );

      expect(result, isEmpty);
    });

    test('multiple WAN interfaces create separate entries', () {
      final interfaces = EthernetInterfaces(items: [
        _iface(
            path: 'Device.Ethernet.Interface.2.', name: 'eth0', bitRate: 1000),
        _iface(
            path: 'Device.Ethernet.Interface.3.', name: 'eth2', bitRate: 2500),
      ]);

      final result = svc.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        // No bridge members — both are WAN
      );

      expect(result.length, 2);
      expect(result.every((p) => p.isWan), isTrue);
      expect(result[0].currentBitRate, 1000);
      expect(result[1].currentBitRate, 2500);
    });
  });
}
