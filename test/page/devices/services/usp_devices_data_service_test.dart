import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
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

      expect(result.deviceModels, hasLength(2));
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

      final wifi =
          result.deviceModels.firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:01');
      final wired =
          result.deviceModels.firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:02');
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
      expect(result.nodeModels, hasLength(1));
      expect(result.nodeModels.first.deviceId, 'gateway');
      expect(result.nodeModels.first.model, 'M60TB');
    });

    test('skips node models when systemInfo is null', () async {
      final result = await svc.fetch(
        wifiClientMap: {},
        connectionDetailMap: {},
        gatewayName: 'Router',
        systemInfo: null,
      );

      expect(result.nodeModels, isEmpty);
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

      final wifi = rebuilt.deviceModels
          .firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:01');
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
          MeshNodeInfo(
              instancePath: 'p.1.', deviceId: 'NODE-A', model: 'M60'),
        ],
        clientToNodeMap: {'AA:BB:CC:DD:EE:01': 'NODE-A'},
      );

      final rebuilt = svc.rebuildWithMesh(
        context: fetchResult.codegenContext,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: mesh,
        gatewayName: 'Router',
        systemInfo: _sysInfo,
      );

      final wifi = rebuilt.deviceModels
          .firstWhere((d) => d.mac == 'AA:BB:CC:DD:EE:01');
      expect(wifi.parentNodeId, 'NODE-A');

      // Node models should reflect mesh
      expect(rebuilt.nodeModels, hasLength(1));
      expect(rebuilt.nodeModels.first.isMaster, isTrue);
    });
  });
}
