import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

/// Raw USP response for 2 connected devices.
final _connectedDevicesResponse = <String, dynamic>{
  'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
  'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
  'Device.Hosts.Host.1.HostName': 'MyLaptop',
  'Device.Hosts.Host.1.Active': true,
  'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
  'Device.Hosts.Host.1.AddressSource': 'DHCP',
  'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
  'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
  'Device.Hosts.Host.2.HostName': 'Desktop',
  'Device.Hosts.Host.2.Active': true,
  'Device.Hosts.Host.2.Layer1Interface': 'Device.Ethernet.Interface.1.',
  'Device.Hosts.Host.2.AddressSource': 'Static',
};

const _sysInfo = SystemInfoUIModel(
  manufacturer: 'Linksys',
  modelName: 'M60TB',
  serialNumber: 'SN123',
  hardwareVersion: '1.0',
  softwareVersion: '2.0.0',
  uptime: 3600,
  totalMemory: 512000,
  freeMemory: 256000,
  cpuUsage: 25,
);

void main() {
  late MockUspClient mockUsp;
  late UspDevicesDataService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspDevicesDataService(mockUsp);

    // Default: ConnectedDevices fetch succeeds, DataElements returns empty
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Hosts.Host'))) {
        return _connectedDevicesResponse;
      }
      // DataElements or other calls → empty
      return <String, dynamic>{};
    });
  });

  group('UspDevicesDataService — fetch', () {
    test('returns device models with correct count', () async {
      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      expect(result.meshNetwork.allClients, hasLength(2));
      expect(result.codegenContext, isNot(DevicesCodegenContext.empty));
    });

    test('builds hostname map from connected devices', () async {
      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
      );

      expect(result.hostNameByMac['AA:BB:CC:DD:EE:01'], 'MyLaptop');
      expect(result.hostNameByMac['AA:BB:CC:DD:EE:02'], 'Desktop');
    });

    test('detects WiFi vs wired devices', () async {
      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
      );

      final wifi = result.meshNetwork.allClients
          .firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:01');
      final wired = result.meshNetwork.allClients
          .firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:02');
      expect(wifi.isWifi, isTrue);
      expect(wired.isWifi, isFalse);
    });

    test('builds node models when systemInfo provided', () async {
      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      // Empty mesh → synthetic gateway node
      expect(result.meshNetwork.allNodes, hasLength(1));
      expect(result.meshNetwork.master.deviceId, 'GATEWAY');
      expect(result.meshNetwork.master.model, 'M60TB');
    });

    test('skips node models when systemInfo is null', () async {
      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: null,
      );

      // Without systemInfo, still has a master node with default values
      expect(result.meshNetwork.allNodes, hasLength(1));
    });

    test('maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(
        () => svc.fetch(
          wifiClientMap: {},
          connectionDetailMap: {},
          gatewayName: 'Router',
        ),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  group('UspDevicesDataService — rebuildWithWifiData', () {
    test('enriches devices with WiFi signal data', () async {
      final fetchResult = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final wifiMap = {
        'AA:BB:CC:DD:EE:01': WifiClientUIModel(
          macAddress: 'AA:BB:CC:DD:EE:01',
          signalStrength: -50,
          noise: -90,
          lastDataDownlinkRate: 100,
          lastDataUplinkRate: 50,
          active: true,
        ),
      };

      final rebuilt = svc.rebuildWithWifiData(
        context: fetchResult.codegenContext,
        wifiClientMap: wifiMap,
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final wifi =
          rebuilt.allClients.firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:01');
      expect(wifi.signalStrength, -50);
      expect(wifi.downlinkRate, 100);
    });
  });

  group('UspDevicesDataService — rebuildWithMesh', () {
    test('assigns parent node to devices', () async {
      final fetchResult = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final mesh = MeshTopologyInfo(
        nodes: [
          MasterNode(deviceId: 'NODE-A', model: 'M60'),
        ],
        clientToNodeMap: const {'AA:BB:CC:DD:EE:01': 'NODE-A'},
      );

      final rebuilt = svc.rebuildWithMesh(
        context: fetchResult.codegenContext,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: mesh,
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final wifi =
          rebuilt.allClients.firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:01');
      expect(wifi.parentNodeId, 'NODE-A');

      // Node models should reflect mesh
      expect(rebuilt.allNodes, hasLength(1));
      expect(rebuilt.master.isMaster, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Hostname-based multi-interface grouping
  // ---------------------------------------------------------------------------

  group('UspDevicesDataService — hostname grouping', () {
    test('merges devices with same hostname into single entry', () async {
      // Setup: two devices with same hostname but different MACs/interfaces
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.1.HostName': 'MacBook-Pro',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.2.HostName': 'MacBook-Pro',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      // Should be merged into 1 device
      expect(result.meshNetwork.allClients, hasLength(1));
      expect(result.meshNetwork.allClients.first.hasMultipleInterfaces, isTrue);
      expect(result.meshNetwork.allClients.first.interfaceCount, 2);
    });

    test('merged device includes all MAC addresses', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.1.HostName': 'MacBook-Pro',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.2.HostName': 'MacBook-Pro',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final device = result.meshNetwork.allClients.first;
      expect(device.allMacAddresses, hasLength(2));
      expect(
        device.allMacAddresses,
        containsAll(['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']),
      );
    });

    test('devices with empty hostname are not merged', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.1.HostName': '',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.2.HostName': '',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      // Should remain as 2 separate devices
      expect(result.meshNetwork.allClients, hasLength(2));
      expect(
          result.meshNetwork.allClients.first.hasMultipleInterfaces, isFalse);
      expect(result.meshNetwork.allClients.last.hasMultipleInterfaces, isFalse);
    });

    test('mesh nodes (master/slave) are not merged', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.1',
                'Device.Hosts.Host.1.HostName': 'LinksysRouter',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
                'Device.Hosts.Host.1.DeviceRole': 'master',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.2',
                'Device.Hosts.Host.2.HostName': 'LinksysRouter',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.DeviceRole': 'slave',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      // Mesh nodes are separate from client devices in MeshNetwork
      // allClients contains only client devices, allNodes contains mesh nodes
      final clientDevices = result.meshNetwork.allClients;

      // Mesh nodes with DeviceRole are filtered out from clients
      // The test data has 2 devices both with mesh roles, so no client devices
      expect(clientDevices, isEmpty);
    });

    test('primary interface selection: active > WiFi > Ethernet', () async {
      // WiFi is active, Ethernet is also active — WiFi should be primary
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.1.HostName': 'MacBook',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.2.HostName': 'MacBook',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface': 'Device.WiFi.SSID.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final device = result.meshNetwork.allClients.first;
      // WiFi interface should be primary (isWifi=true)
      expect(device.isWifi, isTrue);
      expect(device.mac, 'AA:BB:CC:DD:EE:01'); // WiFi MAC
    });

    test('additionalInterfaces contains secondary interface data', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.1.HostName': 'MacBook',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.2.HostName': 'MacBook',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final device = result.meshNetwork.allClients.first;
      expect(device.additionalInterfaces, hasLength(1));

      final secondary = device.additionalInterfaces.first;
      expect(secondary.mac, 'AA:BB:CC:DD:EE:02');
      expect(secondary.ip, '192.168.1.102');
      expect(secondary.isWifi, isFalse);
    });

    test('hostname matching is case-insensitive', () async {
      // Setup: "MacBook-Pro" (WiFi) vs "macbook-pro" (Ethernet) — different case
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.1.HostName': 'MacBook-Pro',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.2.HostName': 'macbook-pro',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      // Should merge into 1 device despite different case
      expect(result.meshNetwork.allClients, hasLength(1));
      expect(result.meshNetwork.allClients.first.hasMultipleInterfaces, isTrue);
      expect(result.meshNetwork.allClients.first.interfaceCount, 2);
    });

    test('devices with mDNS suffix hostname merge correctly', () async {
      // Setup: "MacBook._tcp.local" (WiFi) + "MacBook" (Ethernet)
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.1.HostName': 'MacBook._tcp.local',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.2.HostName': 'MacBook',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      // Should merge: "MacBook._tcp.local" → "macbook", "MacBook" → "macbook"
      expect(result.meshNetwork.allClients, hasLength(1));
      expect(result.meshNetwork.allClients.first.hasMultipleInterfaces, isTrue);
      expect(result.meshNetwork.allClients.first.interfaceCount, 2);
    });

    test('inactive WiFi + active Ethernet selects Ethernet as primary',
        () async {
      // Setup: WiFi inactive, Ethernet active — Ethernet should be primary
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
                'Device.Hosts.Host.1.HostName': 'MacBook',
                'Device.Hosts.Host.1.Active': false, // WiFi is inactive
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
                'Device.Hosts.Host.2.HostName': 'MacBook',
                'Device.Hosts.Host.2.Active': true, // Ethernet is active
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final device = result.meshNetwork.allClients.first;
      // Ethernet should be primary because it's active (active > WiFi preference)
      expect(device.isWifi, isFalse);
      expect(device.mac, 'AA:BB:CC:DD:EE:02'); // Ethernet MAC
      expect(device.isActive, isTrue);

      // WiFi should be in additional interfaces
      expect(device.additionalInterfaces, hasLength(1));
      expect(device.additionalInterfaces.first.isWifi, isTrue);
      expect(device.additionalInterfaces.first.isActive, isFalse);
    });
  });
}
