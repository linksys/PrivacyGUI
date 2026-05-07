import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

class MockUspClient extends Mock implements UspClient {}

class MockUspDevicesDataService extends Mock implements UspDevicesDataService {}

void main() {
  late MockUspClient mockUsp;
  late MockUspDevicesDataService mockDevicesSvc;

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

  final sampleFetchResult = DevicesDataFetchResult(
    codegenContext: DevicesCodegenContext.empty,
    deviceModels: sampleDeviceModels,
    nodeModels: [],
    hostNameByMac: {'AA:BB:CC:DD:EE:01': 'MyLaptop'},
  );

  setUp(() {
    mockUsp = MockUspClient();
    mockDevicesSvc = MockUspDevicesDataService();

    when(() => mockDevicesSvc.fetch(
          wifiClientMap: any(named: 'wifiClientMap'),
          connectionDetailMap: any(named: 'connectionDetailMap'),
          gatewayName: any(named: 'gatewayName'),
          systemInfo: any(named: 'systemInfo'),
        )).thenAnswer((_) async => sampleFetchResult);

    when(() => mockDevicesSvc.fetchMeshTopology())
        .thenAnswer((_) async => MeshTopologyInfo.empty);

    when(() => mockDevicesSvc.rebuildWithWifiData(
          context: any(named: 'context'),
          wifiClientMap: any(named: 'wifiClientMap'),
          connectionDetailMap: any(named: 'connectionDetailMap'),
          meshTopology: any(named: 'meshTopology'),
          gatewayName: any(named: 'gatewayName'),
          systemInfo: any(named: 'systemInfo'),
        )).thenReturn(
      (deviceModels: sampleDeviceModels, nodeModels: sampleNodeModels),
    );
  });

  setUpAll(() {
    registerFallbackValue(DevicesCodegenContext.empty);
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
        uspClientProvider.overrideWithValue(mockUsp),
        uspDevicesDataServiceProvider.overrideWithValue(mockDevicesSvc),
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
      expect(data.nodeModels, isEmpty);
      verify(() => mockDevicesSvc.fetch(
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            gatewayName: any(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
          )).called(1);
      container.dispose();
    });

    test('hostNameByMac is populated from fetch result', () async {
      final container = createContainer();
      final data = await container.read(devicesDataProvider.future);

      expect(data.hostNameByMac, contains('AA:BB:CC:DD:EE:01'));
      expect(data.hostNameByMac['AA:BB:CC:DD:EE:01'], 'MyLaptop');
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
          wifiDataProvider.overrideWith(() => _TestWifiDataNotifier()),
          systemInfoDataProvider.overrideWith(
            () => _TestSystemInfoDataNotifier(null),
          ),
        ],
      );

      expect(
        container.read(devicesDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    test('wifi data timeout falls back to empty WifiData', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          uspDevicesDataServiceProvider.overrideWithValue(mockDevicesSvc),
          wifiDataProvider
              .overrideWith(() => _TestWifiDataNotifier(shouldThrow: true)),
          systemInfoDataProvider.overrideWith(
            () => _TestSystemInfoDataNotifier(null),
          ),
        ],
      );

      final data = await container.read(devicesDataProvider.future);
      expect(data.deviceModels, isNotEmpty);

      verify(() => mockDevicesSvc.fetch(
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            gatewayName: any(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
          )).called(1);
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

    test('DevicesData props for equality', () {
      const a = DevicesData();
      const b = DevicesData();
      expect(a, equals(b));

      final c = DevicesData(hostNameByMac: {'AA:BB': 'Test'});
      expect(a, isNot(equals(c)));
    });

    test('SSE connectedDevices domain triggers debounced re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationDomain>.broadcast();

        final container = ProviderContainer(
          overrides: [
            uspClientProvider.overrideWithValue(mockUsp),
            uspDevicesDataServiceProvider.overrideWithValue(mockDevicesSvc),
            wifiDataProvider.overrideWith(() => _TestWifiDataNotifier()),
            systemInfoDataProvider.overrideWith(
              () => _TestSystemInfoDataNotifier(null),
            ),
            sseInvalidationProvider.overrideWith((ref) => sseController.stream),
          ],
        );

        container.listen(devicesDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockDevicesSvc);

        sseController.add(InvalidationDomain.connectedDevices);
        async.flushMicrotasks();

        // Timer pending — no re-fetch yet
        verifyNever(() => mockDevicesSvc.fetch(
              wifiClientMap: any(named: 'wifiClientMap'),
              connectionDetailMap: any(named: 'connectionDetailMap'),
              gatewayName: any(named: 'gatewayName'),
              systemInfo: any(named: 'systemInfo'),
            ));

        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => mockDevicesSvc.fetch(
              wifiClientMap: any(named: 'wifiClientMap'),
              connectionDetailMap: any(named: 'connectionDetailMap'),
              gatewayName: any(named: 'gatewayName'),
              systemInfo: any(named: 'systemInfo'),
            )).called(1);

        sseController.close();
        container.dispose();
      });
    });

    test('SSE unrelated domain does not trigger re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationDomain>.broadcast();

        final container = ProviderContainer(
          overrides: [
            uspClientProvider.overrideWithValue(mockUsp),
            uspDevicesDataServiceProvider.overrideWithValue(mockDevicesSvc),
            wifiDataProvider.overrideWith(() => _TestWifiDataNotifier()),
            systemInfoDataProvider.overrideWith(
              () => _TestSystemInfoDataNotifier(null),
            ),
            sseInvalidationProvider.overrideWith((ref) => sseController.stream),
          ],
        );

        container.listen(devicesDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockDevicesSvc);

        sseController.add(InvalidationDomain.dmz);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        verifyNever(() => mockDevicesSvc.fetch(
              wifiClientMap: any(named: 'wifiClientMap'),
              connectionDetailMap: any(named: 'connectionDetailMap'),
              gatewayName: any(named: 'gatewayName'),
              systemInfo: any(named: 'systemInfo'),
            ));

        sseController.close();
        container.dispose();
      });
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
      await container.read(systemInfoDataProvider.future);
      await container.read(devicesDataProvider.future);

      final captured = verify(() => mockDevicesSvc.fetch(
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            gatewayName: captureAny(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
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
