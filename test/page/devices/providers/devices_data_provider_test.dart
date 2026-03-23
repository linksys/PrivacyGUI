import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/_shared/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

class MockUspService extends Mock implements UspService {}

class MockUspDeviceService extends Mock implements UspDeviceService {}

void main() {
  late MockUspService mockUsp;
  late MockUspDeviceService mockDeviceSvc;

  /// ConnectedDevices codegen response.
  final connectedDevicesResponse = <String, dynamic>{
    'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
    'Device.Hosts.Host.1.IPAddress': '192.168.1.101',
    'Device.Hosts.Host.1.HostName': 'MyLaptop',
    'Device.Hosts.Host.1.Active': true,
    'Device.Hosts.Host.1.Layer1Interface': 'Device.WiFi.SSID.1.',
    'Device.Hosts.Host.1.AddressSource': 'DHCP',
    'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:02',
    'Device.Hosts.Host.2.IPAddress': '192.168.1.102',
    'Device.Hosts.Host.2.HostName': '',
    'Device.Hosts.Host.2.Active': true,
    'Device.Hosts.Host.2.Layer1Interface': 'Device.Ethernet.Interface.1.',
    'Device.Hosts.Host.2.AddressSource': 'Static',
  };

  /// DataElements response for mesh topology (empty = non-mesh).
  final dataElementsResponse = <String, dynamic>{};

  final sampleDeviceModels = [
    DeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01',
      ip: '192.168.1.101',
      hostName: 'MyLaptop',
      isActive: true,
      isWifi: true,
    ),
    DeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:02',
      ip: '192.168.1.102',
      hostName: '',
      isActive: true,
      isWifi: false,
    ),
  ];

  final sampleNodeModels = [
    NodeUIModel(
      deviceId: 'gateway',
      model: 'M60TB',
      isMaster: true,
    ),
  ];

  setUp(() {
    mockUsp = MockUspService();
    mockDeviceSvc = MockUspDeviceService();

    // ConnectedDevices.fetch + DataElements.fetch both call usp.get()
    when(() => mockUsp.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Hosts.Host'))) {
        return connectedDevicesResponse;
      }
      // DataElements or any other get() call
      return dataElementsResponse;
    });

    when(() => mockDeviceSvc.buildDeviceUIModels(
          connectedDevices: any(named: 'connectedDevices'),
          wifiClientMap: any(named: 'wifiClientMap'),
          connectionDetailMap: any(named: 'connectionDetailMap'),
          meshTopology: any(named: 'meshTopology'),
          gatewayName: any(named: 'gatewayName'),
        )).thenReturn(sampleDeviceModels);

    when(() => mockDeviceSvc.buildNodeUIModels(
          meshTopology: any(named: 'meshTopology'),
          deviceModels: any(named: 'deviceModels'),
          systemInfo: any(named: 'systemInfo'),
        )).thenReturn(sampleNodeModels);
  });

  setUpAll(() {
    registerFallbackValue(const ConnectedDevices(items: []));
    registerFallbackValue(const MeshTopologyInfo(
      nodes: [],
      clientToNodeMap: {},
    ));
    registerFallbackValue(const SystemInfoUIModel(
      manufacturer: '',
      modelName: '',
      serialNumber: '',
      hardwareVersion: '',
      softwareVersion: '',
      uptime: 0,
      totalMemory: 0,
      freeMemory: 0,
      cpuUsage: 0,
    ));
    registerFallbackValue(<String, WifiClientUIModel>{});
    registerFallbackValue(<String, ClientConnectionDetail>{});
    registerFallbackValue(<DeviceUIModel>[]);
  });

  ProviderContainer createContainer({
    SystemInfoData? sysInfoData,
  }) {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
        uspDeviceServiceProvider.overrideWithValue(mockDeviceSvc),
        wifiDataProvider.overrideWith(() => _TestWifiDataNotifier()),
        systemInfoDataProvider.overrideWith(
          () => _TestSystemInfoDataNotifier(sysInfoData),
        ),
      ],
    );
  }

  group('DevicesDataNotifier', () {
    test('build fetches devices and builds UI models', () async {
      final container = createContainer();
      final data = await container.read(devicesDataProvider.future);

      expect(data.deviceModels, hasLength(2));
      // No sysInfoData → nodeModels is empty (guard in _fetch).
      expect(data.nodeModels, isEmpty);
      verify(() => mockDeviceSvc.buildDeviceUIModels(
            connectedDevices: any(named: 'connectedDevices'),
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            meshTopology: any(named: 'meshTopology'),
            gatewayName: any(named: 'gatewayName'),
          )).called(1);
      container.dispose();
    });

    test('hostNameByMac is populated from connected devices', () async {
      final container = createContainer();
      final data = await container.read(devicesDataProvider.future);

      // Only device with non-empty hostname should be in the map
      expect(data.hostNameByMac, contains('AA:BB:CC:DD:EE:01'));
      expect(data.hostNameByMac['AA:BB:CC:DD:EE:01'], 'MyLaptop');
      // Device 2 has empty hostname — should NOT be in map
      expect(data.hostNameByMac, isNot(contains('AA:BB:CC:DD:EE:02')));
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
          uspDeviceServiceProvider.overrideWithValue(mockDeviceSvc),
          wifiDataProvider.overrideWith(() => _TestWifiDataNotifier()),
          systemInfoDataProvider.overrideWith(
            () => _TestSystemInfoDataNotifier(null),
          ),
        ],
      );

      expect(
        container.read(devicesDataProvider.future),
        throwsA(isA<StateError>()),
      );
      container.dispose();
    });

    test('wifi data timeout falls back to empty WifiData', () async {
      // WiFi provider that throws
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(mockUsp),
          uspDeviceServiceProvider.overrideWithValue(mockDeviceSvc),
          wifiDataProvider
              .overrideWith(() => _TestWifiDataNotifier(shouldThrow: true)),
          systemInfoDataProvider.overrideWith(
            () => _TestSystemInfoDataNotifier(null),
          ),
        ],
      );

      // Should still complete — fallback to empty wifi data
      final data = await container.read(devicesDataProvider.future);
      expect(data.deviceModels, isNotEmpty);

      // buildDeviceUIModels should be called with empty wifi maps
      verify(() => mockDeviceSvc.buildDeviceUIModels(
            connectedDevices: any(named: 'connectedDevices'),
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            meshTopology: any(named: 'meshTopology'),
            gatewayName: any(named: 'gatewayName'),
          )).called(1);
      container.dispose();
    });

    test('no system info data skips node model building', () async {
      // systemInfoDataProvider is overridden with null → nodeModels empty
      when(() => mockDeviceSvc.buildNodeUIModels(
            meshTopology: any(named: 'meshTopology'),
            deviceModels: any(named: 'deviceModels'),
            systemInfo: any(named: 'systemInfo'),
          )).thenReturn([]);

      final container = createContainer(sysInfoData: null);
      final data = await container.read(devicesDataProvider.future);

      // Without sysData, nodeModels should be empty (the if-guard in _fetch)
      verifyNever(() => mockDeviceSvc.buildNodeUIModels(
            meshTopology: any(named: 'meshTopology'),
            deviceModels: any(named: 'deviceModels'),
            systemInfo: any(named: 'systemInfo'),
          ));
      expect(data.nodeModels, isEmpty);
      container.dispose();
    });

    test('DevicesData copyWith works', () {
      const data = DevicesData();
      final updated = data.copyWith(
        hostNameByMac: {'AA:BB': 'Test'},
      );
      expect(updated.hostNameByMac, {'AA:BB': 'Test'});
      expect(updated.deviceModels, isEmpty);
    });

    test('gatewayName uses modelName from sysData', () async {
      final sysData = SystemInfoData(
        model: SystemInfoUIModel(
          manufacturer: 'Linksys',
          modelName: 'M60TB',
          serialNumber: 'SN',
          hardwareVersion: '1.0',
          softwareVersion: '1.0.16',
          uptime: 0,
          totalMemory: 0,
          freeMemory: 0,
          cpuUsage: 0,
        ),
      );
      final container = createContainer(sysInfoData: sysData);
      // Ensure systemInfoDataProvider resolves before devicesDataProvider reads it.
      await container.read(systemInfoDataProvider.future);
      await container.read(devicesDataProvider.future);

      // Verify gatewayName was passed to buildDeviceUIModels
      final captured = verify(() => mockDeviceSvc.buildDeviceUIModels(
            connectedDevices: any(named: 'connectedDevices'),
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            meshTopology: any(named: 'meshTopology'),
            gatewayName: captureAny(named: 'gatewayName'),
          )).captured;
      expect(captured.first, 'M60TB');
      container.dispose();
    });
  });
}

/// Test override for WifiDataNotifier.
class _TestWifiDataNotifier extends WifiDataNotifier {
  final bool shouldThrow;

  _TestWifiDataNotifier({this.shouldThrow = false});

  @override
  Future<WifiData> build() async {
    if (shouldThrow) throw Exception('wifi fetch failed');
    return const WifiData.empty();
  }
}

/// Test override for SystemInfoDataNotifier.
class _TestSystemInfoDataNotifier extends SystemInfoDataNotifier {
  final SystemInfoData? _data;

  _TestSystemInfoDataNotifier(this._data);

  @override
  Future<SystemInfoData> build() async {
    if (_data == null) throw Exception('no system info');
    return _data;
  }
}
