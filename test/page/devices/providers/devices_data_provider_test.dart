import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

class MockUspClient extends Mock implements UspClient {}

class MockUspDevicesDataService extends Mock implements UspDevicesDataService {}

void main() {
  late MockUspClient mockUsp;
  late MockUspDevicesDataService mockDevicesSvc;

  final sampleClients = [
    ClientDevice(
      mac: 'AA:BB:CC:DD:EE:01',
      ip: '192.168.1.101',
      hostName: 'MyLaptop',
      isActive: true,
      connectionType: ConnectionType.wifi,
    ),
    ClientDevice(
      mac: 'AA:BB:CC:DD:EE:02',
      ip: '192.168.1.102',
      hostName: '',
      isActive: true,
      connectionType: ConnectionType.wired,
    ),
  ];

  final sampleMeshNetwork = MeshNetwork(
    master: MasterNode(
      deviceId: 'GATEWAY',
      model: 'M60TB',
      connectedClients: sampleClients,
    ),
  );

  late DevicesDataFetchResult sampleFetchResult;

  setUp(() {
    mockUsp = MockUspClient();
    mockDevicesSvc = MockUspDevicesDataService();

    sampleFetchResult = DevicesDataFetchResult(
      codegenContext: DevicesCodegenContext.empty,
      hostNameByMac: {'AA:BB:CC:DD:EE:01': 'MyLaptop'},
      meshNetwork: sampleMeshNetwork,
    );

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
        )).thenReturn(sampleMeshNetwork);

    when(() => mockDevicesSvc.rebuildWithMesh(
          context: any(named: 'context'),
          wifiClientMap: any(named: 'wifiClientMap'),
          connectionDetailMap: any(named: 'connectionDetailMap'),
          meshTopology: any(named: 'meshTopology'),
          gatewayName: any(named: 'gatewayName'),
          systemInfo: any(named: 'systemInfo'),
        )).thenReturn(sampleMeshNetwork);
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
    registerFallbackValue(<ClientDevice>[]);
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

      expect(data.clientDevices, hasLength(2));
      expect(data.nodes, hasLength(1));
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
      expect(data.clientDevices, isNotEmpty);

      verify(() => mockDevicesSvc.fetch(
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            gatewayName: any(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
          )).called(1);
      container.dispose();
    });

    test('DevicesData copyWith works', () {
      final data = DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Test'),
        ),
      );
      final updated = data.copyWith(
        hostNameByMac: {'AA:BB': 'Test'},
      );
      expect(updated.hostNameByMac, {'AA:BB': 'Test'});
      expect(updated.clientDevices, isEmpty);
    });

    test('DevicesData props for equality', () {
      final a = DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Test'),
        ),
      );
      final b = DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Test'),
        ),
      );
      expect(a, equals(b));

      final c = DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Test'),
        ),
        hostNameByMac: {'AA:BB': 'Test'},
      );
      expect(a, isNot(equals(c)));
    });

    test('SSE connectedDevices domain triggers debounced re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();

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

        sseController
            .add((domain: InvalidationDomain.connectedDevices, seq: 0));
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
        final sseController = StreamController<InvalidationEvent>.broadcast();

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

        sseController.add((domain: InvalidationDomain.dmz, seq: 0));
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

    // The two tests above emit one event each, so neither can see a same-domain
    // repeat being collapsed. That collapse is what riverpod 3.x's `==`-based
    // updateShouldNotify would cause without the `seq` tag on
    // `InvalidationEvent` (#1501 AC-B1), and it is what this test pins.
    //
    // The two events are spaced past the 500ms debounce window on purpose:
    // inside it they are *meant* to merge into one refresh, so a repeat asserted
    // there could not tell a real collapse from the debouncer doing its job.
    test('two connectedDevices events past the debounce window re-fetch twice',
        () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();

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

        void expectOneFetch() {
          verify(() => mockDevicesSvc.fetch(
                wifiClientMap: any(named: 'wifiClientMap'),
                connectionDetailMap: any(named: 'connectionDetailMap'),
                gatewayName: any(named: 'gatewayName'),
                systemInfo: any(named: 'systemInfo'),
              )).called(1);
        }

        // A device joins.
        sseController
            .add((domain: InvalidationDomain.connectedDevices, seq: 0));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();
        expectOneFetch();

        // Another one joins, well after the first refresh settled. Same domain,
        // so `seq` is the only thing that differs between the two events — and
        // if the second is dropped the new device never appears in the list.
        sseController
            .add((domain: InvalidationDomain.connectedDevices, seq: 1));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();
        expectOneFetch();

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

  // -------------------------------------------------------------------------
  // The wifiDataProvider listener rebuilds the mesh once per upstream settle,
  // not once per notification.
  //
  // Re-running an AsyncNotifier that already holds a value emits
  // AsyncData(isLoading: true, value: prev) via copyWithPrevious before the
  // fresh value. Without the isLoading guard the listener rebuilt the mesh from
  // that stale WifiData and assigned an extra state — an emission this
  // provider's own downstream listeners then saw as well. See
  // doc/riverpod/listen_site_audit.md (#1502 AC-4).
  // -------------------------------------------------------------------------
  group('DevicesDataNotifier — wifi data re-notification', () {
    test('a wifi refetch rebuilds the mesh exactly once', () async {
      // The listener early-returns on DevicesCodegenContext.empty, so the fetch
      // result must carry a non-empty context.
      sampleFetchResult = DevicesDataFetchResult(
        codegenContext: DevicesCodegenContext(ConnectedDevices(items: [
          ConnectedDevice(
            instancePath: 'Device.Hosts.Host.1.',
            macAddress: 'AA:BB:CC:DD:EE:01',
            ipAddress: '192.168.1.101',
            hostName: 'MyLaptop',
            isActive: true,
            interface_: 'Device.WiFi.SSID.1.',
            ipv4Addresses: const [],
            ipv6Addresses: const [],
          ),
        ])),
        hostNameByMac: {'AA:BB:CC:DD:EE:01': 'MyLaptop'},
        meshNetwork: sampleMeshNetwork,
      );

      final container = createContainer();
      addTearDown(container.dispose);

      // A permanent subscription keeps the notifier — and therefore its
      // ref.listen on wifiDataProvider — alive, so the invalidate below
      // rebuilds eagerly instead of being deferred to the next read.
      container.listen(devicesDataProvider, (_, __) {});
      await container.read(devicesDataProvider.future);

      // Boot goes through fetch(), not the wifi listener: at the listener's
      // first firing the notifier has no state yet, so it early-returns. That
      // makes the count below attributable entirely to the refetch.
      verifyNever(() => mockDevicesSvc.rebuildWithWifiData(
            context: any(named: 'context'),
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            meshTopology: any(named: 'meshTopology'),
            gatewayName: any(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
          ));

      container.invalidate(wifiDataProvider);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Two listener firings (loading-with-previous, then the fresh value),
      // one mesh rebuild. Without the isLoading guard this is 2.
      verify(() => mockDevicesSvc.rebuildWithWifiData(
            context: any(named: 'context'),
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            meshTopology: any(named: 'meshTopology'),
            gatewayName: any(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
          )).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // linksys/PrivacyGUI#1631 — three publish sites, no ordering guard.
  //
  // This provider never used `invalidateSelf()`, so it never had riverpod's coalescing:
  // two overlapping refreshes have always resolved in COMPLETION order rather than in the
  // order the device was read. `connectedDevices` is the highest-frequency domain the app
  // subscribes to, and `_refetchPreservingMesh` awaits WifiData with a 5s timeout before
  // it even calls `fetch()`, so two events landing inside one window is the ordinary case
  // on a busy network — not a race that needs contriving.
  //
  // Both tests below make the OLDER read finish LAST, which is the case that used to
  // publish stale data with nothing to correct it.
  // -------------------------------------------------------------------------
  group('DevicesDataNotifier — #1631 ordering guard', () {
    test('an older refresh finishing last does not publish', () async {
      final sseController = StreamController<InvalidationEvent>.broadcast();
      addTearDown(sseController.close);

      // Three fetches: build()'s, then one per push. The two pushes are resolved OUT OF
      // ORDER by hand — the older one completes last, which is the case that used to win.
      final older = Completer<DevicesDataFetchResult>();
      final newer = Completer<DevicesDataFetchResult>();
      var calls = 0;
      when(() => mockDevicesSvc.fetch(
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            gatewayName: any(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
          )).thenAnswer((_) {
        calls++;
        if (calls == 1) return Future.value(_tagged('build'));
        if (calls == 2) return older.future;
        if (calls == 3) return newer.future;
        return Future.value(_tagged('unexpected'));
      });

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
      addTearDown(container.dispose);

      container.listen(devicesDataProvider, (_, __) {});
      await container.read(devicesDataProvider.future);

      // Two pushes, each past the debounce window, so both refreshes really start and
      // both are in flight together.
      sseController.add((domain: InvalidationDomain.connectedDevices, seq: 0));
      await Future.delayed(const Duration(milliseconds: 600));
      sseController.add((domain: InvalidationDomain.connectedDevices, seq: 1));
      await Future.delayed(const Duration(milliseconds: 600));

      expect(calls, 3, reason: 'both pushes must have started a fetch');

      // Newer completes first, then the older one — the inversion this pins.
      newer.complete(_tagged('newer'));
      await Future.delayed(Duration.zero);
      older.complete(_tagged('older'));
      await Future.delayed(Duration.zero);

      expect(container.read(devicesDataProvider).valueOrNull?.hostNameByMac,
          {'TAG': 'newer'},
          reason:
              'the newer read must survive the older one finishing after it');
    });

    test('a rebuild supersedes a refresh already in flight', () async {
      final sseController = StreamController<InvalidationEvent>.broadcast();
      addTearDown(sseController.close);

      final inFlight = Completer<DevicesDataFetchResult>();
      var call = 0;
      when(() => mockDevicesSvc.fetch(
            wifiClientMap: any(named: 'wifiClientMap'),
            connectionDetailMap: any(named: 'connectionDetailMap'),
            gatewayName: any(named: 'gatewayName'),
            systemInfo: any(named: 'systemInfo'),
          )).thenAnswer((_) {
        call++;
        // 1: build(). 2: the push refresh, held open. 3: the rebuild.
        if (call == 2) return inFlight.future;
        return Future.value(_tagged(call == 1 ? 'build' : 'rebuild'));
      });

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
      addTearDown(container.dispose);

      container.listen(devicesDataProvider, (_, __) {});
      await container.read(devicesDataProvider.future);

      // A push refresh starts and blocks inside `fetch()`.
      sseController.add((domain: InvalidationDomain.connectedDevices, seq: 0));
      await Future.delayed(const Duration(milliseconds: 600));

      // THE CASE THIS PINS: a pull-to-refresh or a post-save invalidate while that push
      // is still awaiting. `build()` bumps the generation, so the push must not publish
      // when it finally returns — otherwise the user pulls to refresh and gets the value
      // from before the pull.
      final rebuilt = await container.refresh(devicesDataProvider.future);
      expect(rebuilt.hostNameByMac, {'TAG': 'rebuild'});

      inFlight.complete(_tagged('older'));
      await Future.delayed(Duration.zero);

      expect(container.read(devicesDataProvider).valueOrNull?.hostNameByMac,
          {'TAG': 'rebuild'},
          reason: 'the rebuild wins; the superseded push must not republish');
    });
  });
}

/// A fetch result carrying nothing but a label, so a test can say WHICH read a published
/// value came from. Counting clients would need a whole `MeshNetwork` per variant and
/// would still only distinguish them by size.
DevicesDataFetchResult _tagged(String tag) => DevicesDataFetchResult(
      codegenContext: DevicesCodegenContext.empty,
      hostNameByMac: {'TAG': tag},
      meshNetwork: MeshNetwork(
        master: MasterNode(deviceId: 'GATEWAY', model: 'M60TB'),
      ),
    );

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
