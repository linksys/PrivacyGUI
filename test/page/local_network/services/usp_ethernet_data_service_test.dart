import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/local_network/services/usp_ethernet_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

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

/// Ethernet interfaces response (2 interfaces).
Map<String, dynamic> _ethernetResponse({
  String iface1Path = 'Device.Ethernet.Interface.1.',
  String iface1Name = 'eth1',
  String iface1Status = 'Up',
  bool iface1Upstream = true,
  int iface1BitRate = 1000,
  String iface2Path = 'Device.Ethernet.Interface.2.',
  String iface2Name = 'eth0',
  String iface2Status = 'Up',
  bool iface2Upstream = false,
  int iface2BitRate = 100,
}) =>
    {
      '${iface1Path}Name': iface1Name,
      '${iface1Path}Status': iface1Status,
      '${iface1Path}Upstream': iface1Upstream,
      '${iface1Path}CurrentBitRate': iface1BitRate.toString(),
      '${iface2Path}Name': iface2Name,
      '${iface2Path}Status': iface2Status,
      '${iface2Path}Upstream': iface2Upstream,
      '${iface2Path}CurrentBitRate': iface2BitRate.toString(),
    };

/// Bridge port map response.
Map<String, dynamic> _bridgeResponse({
  String bridgePort = 'Device.Bridging.Bridge.1.Port.1.',
  String lowerLayers = 'Device.Ethernet.Interface.1.',
}) =>
    {
      '${bridgePort}LowerLayers': lowerLayers,
    };

void main() {
  late MockUspClient mockUsp;
  late UspEthernetDataService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspEthernetDataService(mockUsp);
  });

  void stubResponses({
    Map<String, dynamic>? ethernet,
    Map<String, dynamic>? bridge,
  }) {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;
      if (paths.any((p) => p.contains('Bridging'))) {
        return bridge ?? <String, dynamic>{};
      }
      return ethernet ?? _ethernetResponse();
    });
  }

  // ---------------------------------------------------------------------------
  // WAN / LAN classification (bridge membership)
  // ---------------------------------------------------------------------------
  group('WAN / LAN classification', () {
    test('interface not in bridge map is WAN', () async {
      stubResponses(
        ethernet: _ethernetResponse(
          iface1Path: 'Device.Ethernet.Interface.2.',
          iface1Name: 'eth0',
        ),
        bridge: _bridgeResponse(
          // Only Interface.1 is a bridge member — Interface.2 is NOT
          lowerLayers: 'Device.Ethernet.Interface.1.',
        ),
      );

      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels.length, 1);
      expect(result.portModels.first.isWan, isTrue);
      expect(result.portModels.first.label, 'WAN');
    });

    test('interface in bridge map is LAN', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up',
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        },
        bridge: _bridgeResponse(
          lowerLayers: 'Device.Ethernet.Interface.1.',
        ),
      );

      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels.length, 1);
      expect(result.portModels.first.isWan, isFalse);
      expect(result.portModels.first.label, 'LAN');
    });

    test('M60TB: upstream flag ignored, bridge membership used', () async {
      // M60TB: Interface.1 (eth1) has Upstream=true but is LAN
      //        Interface.2 (eth0) has Upstream=false but is WAN
      stubResponses(
        ethernet: _ethernetResponse(
          iface1Upstream: true, // misleading — actually LAN
          iface2Upstream: false, // misleading — actually WAN
        ),
        bridge: _bridgeResponse(
          lowerLayers: 'Device.Ethernet.Interface.1.',
        ),
      );

      final result = await svc.fetch(deviceModels: []);

      final wan = result.portModels.where((p) => p.isWan).toList();
      final lan = result.portModels.where((p) => !p.isWan).toList();

      expect(wan.length, 1);
      expect(wan.first.name, 'eth0'); // Interface.2
      expect(lan.length, 1);
      expect(lan.first.name, 'eth1'); // Interface.1 (bridge member)
    });
  });

  // ---------------------------------------------------------------------------
  // WAN port status
  // ---------------------------------------------------------------------------
  group('WAN port status', () {
    test('isUp reflects status field', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.2.Name': 'eth0',
          'Device.Ethernet.Interface.2.Status': 'Up',
          'Device.Ethernet.Interface.2.Upstream': false,
          'Device.Ethernet.Interface.2.CurrentBitRate': '1000',
          'Device.Ethernet.Interface.3.Name': 'eth2',
          'Device.Ethernet.Interface.3.Status': 'Down',
          'Device.Ethernet.Interface.3.Upstream': false,
          'Device.Ethernet.Interface.3.CurrentBitRate': '0',
        },
        // No bridge members — both are WAN
        bridge: {},
      );

      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels.length, 2);
      expect(result.portModels[0].isUp, isTrue);
      expect(result.portModels[1].isUp, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // LAN port entries
  // ---------------------------------------------------------------------------
  group('LAN port entries', () {
    test('no wired devices — single LAN entry with isUp=false', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up', // interface reports Up
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        },
        bridge: _bridgeResponse(),
      );

      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels.length, 1);
      expect(result.portModels.first.label, 'LAN');
      expect(result.portModels.first.isWan, isFalse);
      expect(result.portModels.first.connectedDevices, isEmpty);
      // No wired devices = disconnected, regardless of interface status
      expect(result.portModels.first.isUp, isFalse);
    });

    test('one wired device — LAN 1 with device info', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up',
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        },
        bridge: _bridgeResponse(),
      );

      final result = await svc.fetch(deviceModels: [
        _device(mac: 'AA:BB:CC:DD:EE:FF', hostName: 'laptop'),
      ]);

      expect(result.portModels.length, 1);
      expect(result.portModels.first.label, 'LAN 1');
      expect(result.portModels.first.connectedDevices.length, 1);
      expect(result.portModels.first.connectedDevices.first.hostName, 'laptop');
      expect(result.portModels.first.connectedDevices.first.macAddress,
          'AA:BB:CC:DD:EE:FF');
    });

    test('multiple wired devices — LAN 1, LAN 2, LAN 3', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up',
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        },
        bridge: _bridgeResponse(),
      );

      final result = await svc.fetch(deviceModels: [
        _device(mac: 'AA:00:00:00:00:01', hostName: 'pc1'),
        _device(mac: 'AA:00:00:00:00:02', hostName: 'pc2'),
        _device(mac: 'AA:00:00:00:00:03', hostName: 'pc3'),
      ]);

      expect(result.portModels.length, 3);
      expect(result.portModels[0].label, 'LAN 1');
      expect(result.portModels[1].label, 'LAN 2');
      expect(result.portModels[2].label, 'LAN 3');
    });

    test('only active wired devices become ports', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up',
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        },
        bridge: _bridgeResponse(),
      );

      final result = await svc.fetch(deviceModels: [
        _device(isActive: true, hostName: 'active-pc'),
        _device(
          isActive: false,
          hostName: 'inactive-pc',
          mac: 'BB:00:00:00:00:01',
        ),
      ]);

      expect(result.portModels.length, 1);
      expect(
          result.portModels.first.connectedDevices.first.hostName, 'active-pc');
    });

    test('WiFi devices excluded from LAN ports', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up',
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        },
        bridge: _bridgeResponse(),
      );

      final result = await svc.fetch(deviceModels: [
        _device(isWifi: true, hostName: 'phone'),
      ]);

      // WiFi device excluded — falls to empty wired list → single LAN entry
      expect(result.portModels.length, 1);
      expect(result.portModels.first.label, 'LAN');
      expect(result.portModels.first.connectedDevices, isEmpty);
      expect(result.portModels.first.isUp, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Path normalization
  // ---------------------------------------------------------------------------
  group('path normalization', () {
    test('trailing dot added to bridge map values for matching', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up',
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        },
        // Bridge map value WITHOUT trailing dot — should still match
        bridge: _bridgeResponse(
          lowerLayers: 'Device.Ethernet.Interface.1', // no trailing dot
        ),
      );

      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels.length, 1);
      expect(result.portModels.first.isWan, isFalse); // Matched as LAN
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------
  group('edge cases', () {
    test('empty inputs return empty result', () async {
      stubResponses(
        ethernet: {},
        bridge: {},
      );

      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels, isEmpty);
    });

    test('multiple WAN interfaces create separate entries', () async {
      stubResponses(
        ethernet: {
          'Device.Ethernet.Interface.2.Name': 'eth0',
          'Device.Ethernet.Interface.2.Status': 'Up',
          'Device.Ethernet.Interface.2.Upstream': false,
          'Device.Ethernet.Interface.2.CurrentBitRate': '1000',
          'Device.Ethernet.Interface.3.Name': 'eth2',
          'Device.Ethernet.Interface.3.Status': 'Up',
          'Device.Ethernet.Interface.3.Upstream': false,
          'Device.Ethernet.Interface.3.CurrentBitRate': '2500',
        },
        // No bridge members — both are WAN
        bridge: {},
      );

      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels.length, 2);
      expect(result.portModels.every((p) => p.isWan), isTrue);
      expect(result.portModels[0].currentBitRate, 1000);
      expect(result.portModels[1].currentBitRate, 2500);
    });

    test('bridge port map fetch failure returns empty map gracefully',
        () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.any((p) => p.contains('Bridging'))) {
          throw Exception('bridge not supported');
        }
        return {
          'Device.Ethernet.Interface.1.Name': 'eth1',
          'Device.Ethernet.Interface.1.Status': 'Up',
          'Device.Ethernet.Interface.1.Upstream': false,
          'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
        };
      });

      // Should still succeed — interface becomes WAN (no bridge members)
      final result = await svc.fetch(deviceModels: []);

      expect(result.portModels.length, 1);
      expect(result.portModels.first.isWan, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------
  group('error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => svc.fetch(deviceModels: []), throwsA(isA<ServiceError>()));
    });
  });
}
