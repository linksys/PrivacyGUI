import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
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

  // fetchMeshTopology reads DataElementsNetwork and, separately,
  // DataElementsInterfaces (#1688 item 2). The second read is separate so that
  // a controller without the Interface object loses wired attribution only,
  // never the topology (usp_framework data_elements_interfaces.yaml).
  group('UspDevicesDataService — fetchMeshTopology', () {
    const node = 'Device.WiFi.DataElements.Network.Device.1.';

    // The controller as measured on 2.0.3.26101482: no backhaul, and a wired
    // Mac seen on its Ethernet interface as a non-1905 neighbor.
    final networkResponse = <String, dynamic>{
      '${node}ID': '74:12:13:21:56:3a',
      '${node}MultiAPDevice.Backhaul.LinkType': 'None',
    };
    final interfacesResponse = <String, dynamic>{
      '${node}ID': '74:12:13:21:56:3a',
      '${node}Interface.4.MACAddress': '74:12:13:21:56:3a',
      '${node}Interface.4.MediaType': 'IEEE_802_3AB_GIGABIT_ETHERNET',
      '${node}Interface.4.Neighbor.1.ID': '00:e0:4c:68:08:2d',
      '${node}Interface.4.Neighbor.1.IsIEEE1905': false,
    };

    void stubDataElements({
      bool interfacesFail = false,
      Map<String, dynamic>? network,
      Map<String, dynamic> networkInfo = const {},
      bool networkInfoFails = false,
    }) {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((inv) async {
        final paths = inv.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('.Interface.'))) {
          if (interfacesFail) throw 'USP get failed: 7026 Invalid path';
          return interfacesResponse;
        }
        if (paths.any((p) => p.toString().endsWith('Network.ControllerID'))) {
          if (networkInfoFails) throw 'USP get failed: 7026 Invalid path';
          return networkInfo;
        }
        if (paths.any((p) => p.toString().contains('DataElements'))) {
          return network ?? networkResponse;
        }
        return <String, dynamic>{};
      });
    }

    test('attributes a wired client to the node that lists it', () async {
      stubDataElements();

      final topology = await svc.fetchMeshTopology();

      expect(topology.nodes, hasLength(1));
      expect(topology.wiredClientToNodeMap,
          {'00:E0:4C:68:08:2D': '74:12:13:21:56:3A'});
    });

    test('an Interface read that fails leaves the topology intact', () async {
      stubDataElements(interfacesFail: true);

      final topology = await svc.fetchMeshTopology();

      expect(topology.nodes, hasLength(1));
      expect(topology.wiredClientToNodeMap, isEmpty);
    });

    // #1688 review (W2): an agent still joining has no backhaul yet. The
    // ControllerID read is what keeps it a slave instead of a second master.
    test('reads ControllerID so a joining agent is a slave', () async {
      stubDataElements(network: {
        ...networkResponse,
        'Device.WiFi.DataElements.Network.Device.2.ID': 'aa:bb:cc:dd:ee:02',
      }, networkInfo: {
        'Device.WiFi.DataElements.Network.ControllerID': '74:12:13:21:56:3a',
      });

      final topology = await svc.fetchMeshTopology();

      expect(
          topology.nodes.slaves.map((s) => s.deviceId), ['AA:BB:CC:DD:EE:02']);
    });

    test('a ControllerID read that fails leaves the topology intact', () async {
      stubDataElements(networkInfoFails: true);

      final topology = await svc.fetchMeshTopology();

      expect(topology.nodes, hasLength(1));
      expect(topology.wiredClientToNodeMap,
          {'00:E0:4C:68:08:2D': '74:12:13:21:56:3A'});
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

    // Two agents of the same model share a host name. Their Hosts rows must
    // not be merged into one client the way two interfaces of one laptop are.
    //
    // FL-WRT 2.0 has no `DeviceRole`, so a row is a node's only once
    // DataElements has listed that node (#1688). `fetch()` builds before the
    // background DataElements read returns, with an empty topology, so the
    // exclusion is asserted where the topology arrives: `rebuildWithMesh()`.
    // Neither row carries a role leaf, and the controller has no Hosts row of
    // its own — the shape measured on 2.0.3.26101482.
    test('mesh nodes are not merged as clients once DataElements lists them',
        () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:02',
                'Device.Hosts.Host.1.IPAddress': '192.168.1.2',
                'Device.Hosts.Host.1.HostName': 'LinksysExtender',
                'Device.Hosts.Host.1.Active': true,
                'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
                'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:03',
                'Device.Hosts.Host.2.IPAddress': '192.168.1.3',
                'Device.Hosts.Host.2.HostName': 'LinksysExtender',
                'Device.Hosts.Host.2.Active': true,
                'Device.Hosts.Host.2.Layer1Interface':
                    'Device.Ethernet.Interface.1.',
              });

      final first = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final rebuilt = svc.rebuildWithMesh(
        context: first.codegenContext,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo(
          nodes: [
            MasterNode(deviceId: 'AA:BB:CC:DD:EE:01', model: 'M60'),
            SlaveNode(
              deviceId: 'AA:BB:CC:DD:EE:02',
              model: 'M60',
              backhaul: const BackhaulInfo(linkType: 'Wi-Fi'),
            ),
            SlaveNode(
              deviceId: 'AA:BB:CC:DD:EE:03',
              model: 'M60',
              backhaul: const BackhaulInfo(linkType: 'Ethernet'),
            ),
          ],
          clientToNodeMap: const {},
        ),
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      expect(rebuilt.allClients, isEmpty);
      expect(rebuilt.slaves.map((s) => s.deviceId),
          ['AA:BB:CC:DD:EE:02', 'AA:BB:CC:DD:EE:03']);
      expect(rebuilt.slaves.map((s) => s.ipAddress),
          ['192.168.1.2', '192.168.1.3']);
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

  // The detail page names a client and picks its icon (#1691): the name is
  // X_LINKSYS_UserDeviceLocation, the icon the app's own code in
  // X_LINKSYS_UserDeviceType, both on the client's Hosts.Host row.
  group('UspDevicesDataService — updateIdentity', () {
    Map<String, dynamic> setSuccess() => {
          'success': true,
          'result': {'data': <String, dynamic>{}},
        };

    test('a fetched client carries its Hosts.Host path', () async {
      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
      );

      final laptop = result.meshNetwork.allClients
          .firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:01');
      expect(laptop.hostInstancePath, 'Device.Hosts.Host.1.');
    });

    test('writes the name and the icon code in one Set', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => setSuccess());

      await svc.updateIdentity(
        hostInstancePath: 'Device.Hosts.Host.3.',
        name: 'Living room TV',
        userTypeCode: '4',
      );

      verify(() => mockUsp.set(
            {
              'Device.Hosts.Host.3.X_LINKSYS_UserDeviceLocation':
                  'Living room TV',
              'Device.Hosts.Host.3.X_LINKSYS_UserDeviceType': '4',
            },
            allowPartial: false,
          )).called(1);
    });

    test('an empty name and an empty code are written, which clears them',
        () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => setSuccess());

      await svc.updateIdentity(
        hostInstancePath: 'Device.Hosts.Host.3.',
        name: '',
        userTypeCode: '',
      );

      verify(() => mockUsp.set(
            {
              'Device.Hosts.Host.3.X_LINKSYS_UserDeviceLocation': '',
              'Device.Hosts.Host.3.X_LINKSYS_UserDeviceType': '',
            },
            allowPartial: false,
          )).called(1);
    });

    // A name-only edit leaves the stored type alone, so a type another client
    // wrote (a devregex string the app has no code for) is not erased.
    test('with no icon change, only the name is written', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => setSuccess());

      await svc.updateIdentity(
        hostInstancePath: 'Device.Hosts.Host.3.',
        name: 'Kitchen',
      );

      verify(() => mockUsp.set(
            {'Device.Hosts.Host.3.X_LINKSYS_UserDeviceLocation': 'Kitchen'},
            allowPartial: false,
          )).called(1);
    });

    test('a refused Set throws UspCompleteFailureError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    'Device.Hosts.Host.3.X_LINKSYS_UserDeviceLocation': {
                      'errorCode': 9007,
                      'errorMessage': 'Invalid parameter value',
                    },
                  },
                },
              });

      expect(
        () => svc.updateIdentity(
          hostInstancePath: 'Device.Hosts.Host.3.',
          name: 'x',
          userTypeCode: '1',
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('a transport error maps to ServiceError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(
        () => svc.updateIdentity(
          hostInstancePath: 'Device.Hosts.Host.3.',
          name: 'x',
          userTypeCode: '1',
        ),
        throwsA(isA<ConnectivityError>()),
      );
    });
  });
}
