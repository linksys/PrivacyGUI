import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  const wifiOnlineExcellent = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:01',
    ip: '192.168.1.101',
    hostName: 'iPhone',
    isActive: true,
    isWifi: true,
    band: '5GHz',
    ssidName: 'Home',
    signalStrength: -40, // excellent (>= -65)
    parentNodeId: 'NODE-01',
  );

  const wifiOfflineHome = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:02',
    ip: '192.168.1.102',
    hostName: 'iPad',
    isActive: false,
    isWifi: true,
    // Offline devices in practice have null WiFi/node fields; keep a few set
    // to prove filters pass them through even when leftover values linger.
    band: '2.4GHz',
    ssidName: 'Home',
    parentNodeId: 'NODE-01',
  );

  const ethernetOnline = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:03',
    ip: '192.168.1.103',
    hostName: 'Desktop',
    isActive: true,
    isWifi: false,
    parentNodeId: 'NODE-01',
  );

  const wifiGuestGood = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:04',
    ip: '192.168.1.104',
    hostName: 'GuestPhone',
    isActive: true,
    isWifi: true,
    band: '5GHz',
    ssidName: 'Guest',
    signalStrength: -68, // good (-65..-71)
    parentNodeId: 'NODE-02',
  );

  const wifiOnlineNullRssi = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:05',
    ip: '192.168.1.105',
    hostName: 'NewPhone',
    isActive: true,
    isWifi: true,
    band: '5GHz',
    ssidName: 'Home',
    // signalStrength intentionally null — firmware state where RSSI is absent.
    parentNodeId: 'NODE-01',
  );

  const allDevices = [
    wifiOnlineExcellent,
    wifiOfflineHome,
    ethernetOnline,
    wifiGuestGood,
    wifiOnlineNullRssi,
  ];

  const devicesData = DevicesData(
    deviceModels: allDevices,
    meshTopology: MeshTopologyInfo(
      nodes: [
        NodeUIModel(
            deviceId: 'NODE-01', model: 'MR7500'),
        NodeUIModel(
            deviceId: 'NODE-02', model: 'MX5500'),
      ],
      clientToNodeMap: {},
    ),
  );

  ProviderContainer createContainer({DevicesData? data}) {
    return ProviderContainer(
      overrides: [
        devicesDataProvider
            .overrideWith(() => _FakeDevicesNotifier(data ?? devicesData)),
      ],
    );
  }

  Future<ProviderContainer> createReadyContainer({DevicesData? data}) async {
    final container = createContainer(data: data);
    await container.read(devicesDataProvider.future);
    return container;
  }

  // ---------------------------------------------------------------------------
  // filteredDeviceListProvider — filter dimensions
  // ---------------------------------------------------------------------------

  group('filteredDeviceListProvider', () {
    test('returns all devices with default filter', () async {
      final container = await createReadyContainer();
      expect(container.read(filteredDeviceListProvider), hasLength(5));
      container.dispose();
    });

    group('Status', () {
      test('online filter excludes offline devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setStatus(DeviceStatusFilter.online);

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(4));
        expect(filtered.every((d) => d.isActive), isTrue);
        container.dispose();
      });

      test('offline filter shows only offline devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setStatus(DeviceStatusFilter.offline);

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(1));
        expect(filtered.first.mac, wifiOfflineHome.mac);
        container.dispose();
      });
    });

    group('Connection', () {
      test('WiFi filter excludes ethernet devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setConnection(DeviceConnectionFilter.wifi);

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.every((d) => d.isWifi), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isFalse);
        container.dispose();
      });

      test('Ethernet filter excludes WiFi devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setConnection(DeviceConnectionFilter.ethernet);

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(1));
        expect(filtered.first.mac, ethernetOnline.mac);
        container.dispose();
      });
    });

    group('Signal', () {
      test('excellent bucket matches RSSI >= -65', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSignal(DeviceSignalFilter.excellent);

        final filtered = container.read(filteredDeviceListProvider);

        // wifiOnlineExcellent (-40 excellent), ethernet passes through,
        // wifiOnlineNullRssi passes through (null RSSI WiFi),
        // wifiOfflineHome passes through (null RSSI WiFi).
        // wifiGuestGood (-68 good) is excluded.
        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isFalse);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiOnlineNullRssi.mac), isTrue);
        container.dispose();
      });

      test('unknown bucket matches only WiFi devices with null RSSI', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSignal(DeviceSignalFilter.unknown);

        final filtered = container.read(filteredDeviceListProvider);

        // wifiOnlineNullRssi and wifiOfflineHome are WiFi with null RSSI.
        expect(filtered, hasLength(2));
        expect(filtered.map((d) => d.mac),
            containsAll([wifiOnlineNullRssi.mac, wifiOfflineHome.mac]));
        container.dispose();
      });
    });

    group('Node', () {
      test('node filter excludes devices on other nodes', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setNodeId('NODE-02');

        final filtered = container.read(filteredDeviceListProvider);

        // wifiGuestGood is on NODE-02.
        // wifiOfflineHome is offline → passes through despite being on NODE-01.
        expect(filtered.map((d) => d.mac),
            containsAll([wifiGuestGood.mac, wifiOfflineHome.mac]));
        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isFalse);
        container.dispose();
      });

      test(
          'regression: Status=All + Node=X must not drop offline devices '
          '(they have null parentNodeId in reality)', () async {
        // Replace wifiOfflineHome with one that has a null parentNodeId — the
        // realistic offline state. Filter by NODE-01 must still include it.
        const offlineWithNullNode = DeviceUIModel(
          mac: 'AA:AA:AA:AA:AA:02',
          ip: '192.168.1.102',
          hostName: 'iPad',
          isActive: false,
          isWifi: true,
          // parentNodeId: null — realistic offline state.
        );

        final container = await createReadyContainer(
          data: const DevicesData(
            deviceModels: [wifiOnlineExcellent, offlineWithNullNode],
            meshTopology: MeshTopologyInfo(
              nodes: [
                NodeUIModel(deviceId: 'NODE-01', model: 'MR7500'),
                NodeUIModel(deviceId: 'NODE-02', model: 'MX5500'),
              ],
              clientToNodeMap: {},
            ),
          ),
        );
        container
            .read(deviceFilterConfigProvider.notifier)
            .setNodeId('NODE-01');

        final filtered = container.read(filteredDeviceListProvider);

        // wifiOnlineExcellent on NODE-01, offline passes through.
        expect(filtered, hasLength(2));
        container.dispose();
      });
    });

    group('SSID / Band', () {
      test('SSID filter shows matching WiFi devices and all ethernet devices',
          () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSsidName('Guest');

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isFalse);
        container.dispose();
      });

      test('band filter shows matching WiFi devices and all ethernet devices',
          () async {
        final container = await createReadyContainer();
        container.read(deviceFilterConfigProvider.notifier).setBand('2.4GHz');

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOfflineHome.mac), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isTrue);
        container.dispose();
      });
    });

    group('Search', () {
      test('hostName match is case-insensitive', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSearchQuery('iphone');

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(1));
        expect(filtered.first.mac, wifiOnlineExcellent.mac);
        container.dispose();
      });

      test('MAC match', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSearchQuery('aa:03');

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(1));
        expect(filtered.first.mac, ethernetOnline.mac);
        container.dispose();
      });

      test('no match returns empty list', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSearchQuery('nonexistent');

        expect(container.read(filteredDeviceListProvider), isEmpty);
        container.dispose();
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Dependency rules (auto-reset on status/connection change)
  // ---------------------------------------------------------------------------

  group('DeviceFilterNotifier dependency resets', () {
    test('selecting Offline clears every other dimension', () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setConnection(DeviceConnectionFilter.wifi);
      notifier.setSignal(DeviceSignalFilter.good);
      notifier.setSsidName('Home');
      notifier.setBand('5GHz');
      notifier.setNodeId('NODE-01');
      notifier.setStatus(DeviceStatusFilter.offline);

      final state = container.read(deviceFilterConfigProvider);
      expect(state.status, DeviceStatusFilter.offline);
      expect(state.connection, DeviceConnectionFilter.all);
      expect(state.signal, DeviceSignalFilter.all);
      expect(state.ssidName, isNull);
      expect(state.band, isNull);
      expect(state.nodeId, isNull);
      container.dispose();
    });

    test('selecting Ethernet clears WiFi-only dimensions but keeps Node',
        () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setSignal(DeviceSignalFilter.good);
      notifier.setSsidName('Home');
      notifier.setBand('5GHz');
      notifier.setNodeId('NODE-01');
      notifier.setConnection(DeviceConnectionFilter.ethernet);

      final state = container.read(deviceFilterConfigProvider);
      expect(state.connection, DeviceConnectionFilter.ethernet);
      expect(state.signal, DeviceSignalFilter.all);
      expect(state.ssidName, isNull);
      expect(state.band, isNull);
      expect(state.nodeId, 'NODE-01');
      container.dispose();
    });

    test('switching back from Ethernet to All does not restore WiFi filters',
        () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setSsidName('Home');
      notifier.setConnection(DeviceConnectionFilter.ethernet);
      notifier.setConnection(DeviceConnectionFilter.all);

      expect(container.read(deviceFilterConfigProvider).ssidName, isNull);
      container.dispose();
    });

    test('clearAll resets every dimension and search', () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setStatus(DeviceStatusFilter.online);
      notifier.setSearchQuery('iphone');
      notifier.setSsidName('Home');
      notifier.clearAll();

      final state = container.read(deviceFilterConfigProvider);
      expect(state.isActive, isFalse);
      expect(state.searchQuery, '');
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Orphan reconciliation (SSE refresh invalidates selected option)
  // ---------------------------------------------------------------------------

  group('DeviceFilterNotifier orphan reconciliation', () {
    test('nulls SSID when it disappears from options after data refresh',
        () async {
      final container = await createReadyContainer();
      container.read(deviceFilterConfigProvider.notifier).setSsidName('Guest');

      // Push a new dataset without any Guest device.
      final notifier =
          container.read(devicesDataProvider.notifier) as _FakeDevicesNotifier;
      notifier.emit(const DevicesData(
        deviceModels: [wifiOnlineExcellent],
        meshTopology: MeshTopologyInfo(
          nodes: [NodeUIModel(deviceId: 'NODE-01', model: 'MR7500')],
          clientToNodeMap: {},
        ),
      ));
      await Future<void>.value();

      expect(container.read(deviceFilterConfigProvider).ssidName, isNull);
      container.dispose();
    });

    test('nulls nodeId when selected node disappears', () async {
      final container = await createReadyContainer();
      container.read(deviceFilterConfigProvider.notifier).setNodeId('NODE-02');

      final notifier =
          container.read(devicesDataProvider.notifier) as _FakeDevicesNotifier;
      notifier.emit(const DevicesData(
        deviceModels: [wifiOnlineExcellent],
        meshTopology: MeshTopologyInfo(
          nodes: [NodeUIModel(deviceId: 'NODE-01', model: 'MR7500')],
          clientToNodeMap: {},
        ),
      ));
      await Future<void>.value();

      expect(container.read(deviceFilterConfigProvider).nodeId, isNull);
      container.dispose();
    });

    test('resets Signal=unknown when no null-RSSI devices remain', () async {
      final container = await createReadyContainer();
      container
          .read(deviceFilterConfigProvider.notifier)
          .setSignal(DeviceSignalFilter.unknown);

      final notifier =
          container.read(devicesDataProvider.notifier) as _FakeDevicesNotifier;
      notifier.emit(const DevicesData(
        deviceModels: [wifiOnlineExcellent, ethernetOnline],
        meshTopology: MeshTopologyInfo(
          nodes: [NodeUIModel(deviceId: 'NODE-01', model: 'MR7500')],
          clientToNodeMap: {},
        ),
      ));
      await Future<void>.value();

      expect(container.read(deviceFilterConfigProvider).signal,
          DeviceSignalFilter.all);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // deviceFilterOptionsProvider
  // ---------------------------------------------------------------------------

  group('deviceFilterOptionsProvider', () {
    test('derives nodes / SSIDs / bands / hasUnknownSignalDevices', () async {
      final container = await createReadyContainer();

      final options = container.read(deviceFilterOptionsProvider);

      expect(options.nodes, hasLength(2));
      expect(options.ssids, containsAll(['Guest', 'Home']));
      expect(options.bands, containsAll(['2.4GHz', '5GHz']));
      // wifiOnlineNullRssi + wifiOfflineHome both have null RSSI.
      expect(options.hasUnknownSignalDevices, isTrue);
      container.dispose();
    });

    test('hasUnknownSignalDevices false when every WiFi device has RSSI',
        () async {
      final container = await createReadyContainer(
        data: const DevicesData(
          deviceModels: [wifiOnlineExcellent, wifiGuestGood, ethernetOnline],
          meshTopology: MeshTopologyInfo(nodes: [], clientToNodeMap: {}),
        ),
      );

      expect(
        container.read(deviceFilterOptionsProvider).hasUnknownSignalDevices,
        isFalse,
      );
      container.dispose();
    });

    test('returns empty options when data is unavailable', () {
      final container = ProviderContainer(
        overrides: [
          devicesDataProvider.overrideWith(() => _FakeDevicesNotifier(null)),
        ],
      );

      final options = container.read(deviceFilterOptionsProvider);

      expect(options.nodes, isEmpty);
      expect(options.ssids, isEmpty);
      expect(options.bands, isEmpty);
      expect(options.hasUnknownSignalDevices, isFalse);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // signalBucketOf
  // ---------------------------------------------------------------------------

  group('signalBucketOf', () {
    test('matches project-wide RSSI thresholds (-65 / -71 / -78)', () {
      expect(signalBucketOf(null), DeviceSignalFilter.unknown);
      expect(signalBucketOf(-30), DeviceSignalFilter.excellent);
      expect(signalBucketOf(-65), DeviceSignalFilter.excellent);
      expect(signalBucketOf(-66), DeviceSignalFilter.good);
      expect(signalBucketOf(-71), DeviceSignalFilter.good);
      expect(signalBucketOf(-72), DeviceSignalFilter.fair);
      expect(signalBucketOf(-78), DeviceSignalFilter.fair);
      expect(signalBucketOf(-79), DeviceSignalFilter.poor);
    });
  });
}

// ---------------------------------------------------------------------------
// Fake DevicesDataNotifier
// ---------------------------------------------------------------------------

class _FakeDevicesNotifier extends AsyncNotifier<DevicesData>
    implements DevicesDataNotifier {
  _FakeDevicesNotifier(this._data);

  DevicesData? _data;

  @override
  Future<DevicesData> build() async => _data ?? const DevicesData();

  /// Push a new dataset so that `ref.listen(deviceFilterOptionsProvider)`
  /// in the notifier fires reconciliation.
  void emit(DevicesData next) {
    _data = next;
    state = AsyncData(next);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
