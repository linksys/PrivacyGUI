import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
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
    parentNodeId: 'NODE-01',
  );

  const wifiOnlineFair = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:06',
    ip: '192.168.1.106',
    hostName: 'Laptop',
    isActive: true,
    isWifi: true,
    band: '2.4GHz',
    ssidName: 'Home',
    signalStrength: -75, // fair (-71..-78)
    parentNodeId: 'NODE-01',
  );

  const allDevices = [
    wifiOnlineExcellent,
    wifiOfflineHome,
    ethernetOnline,
    wifiGuestGood,
    wifiOnlineNullRssi,
    wifiOnlineFair,
  ];

  const devicesData = DevicesData(
    deviceModels: allDevices,
    meshTopology: MeshTopologyInfo(
      nodes: [
        NodeUIModel(deviceId: 'NODE-01', model: 'MR7500'),
        NodeUIModel(deviceId: 'NODE-02', model: 'MX5500'),
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
      expect(container.read(filteredDeviceListProvider), hasLength(6));
      container.dispose();
    });

    group('Status', () {
      test('online filter excludes offline devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setStatus(DeviceStatusFilter.online);

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(5));
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

    group('Connection (multi-select)', () {
      test('WiFi filter excludes ethernet devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setConnections({DeviceConnectionType.wifi});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.every((d) => d.isWifi), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isFalse);
        container.dispose();
      });

      test('Ethernet filter excludes WiFi devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setConnections({DeviceConnectionType.wired});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(1));
        expect(filtered.first.mac, ethernetOnline.mac);
        container.dispose();
      });

      test('selecting both WiFi and Ethernet is same as All', () async {
        final container = await createReadyContainer();
        container.read(deviceFilterConfigProvider.notifier).setConnections(
            {DeviceConnectionType.wifi, DeviceConnectionType.wired});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(6));
        container.dispose();
      });
    });

    group('Signal (multi-select OR)', () {
      test('excellent bucket matches RSSI >= -65', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSignals({DeviceSignalLevel.excellent});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isFalse);
        expect(filtered.any((d) => d.mac == wifiOnlineFair.mac), isFalse);
        container.dispose();
      });

      test('selecting excellent + good matches both buckets (OR)', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSignals({DeviceSignalLevel.excellent, DeviceSignalLevel.good});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiOnlineFair.mac), isFalse);
        container.dispose();
      });

      test('includeUnknownSignal matches only WiFi devices with null RSSI',
          () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setIncludeUnknownSignal(true);

        final filtered = container.read(filteredDeviceListProvider);

        // Should include null-RSSI WiFi devices
        expect(filtered.map((d) => d.mac), contains(wifiOnlineNullRssi.mac));
        // Should exclude WiFi devices with known RSSI (BUG FIX verification)
        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isFalse);
        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isFalse);
        expect(filtered.any((d) => d.mac == wifiOnlineFair.mac), isFalse);
        // Ethernet devices should also be excluded (WiFi-only filter)
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isFalse);
        container.dispose();
      });
    });

    group('Node (multi-select OR)', () {
      test('single node filter excludes devices on other nodes', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setNodeIds({'NODE-02'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.map((d) => d.mac), contains(wifiGuestGood.mac));
        expect(filtered.map((d) => d.mac), contains(wifiOfflineHome.mac));
        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isFalse);
        container.dispose();
      });

      test('multi-node filter shows devices on either node (OR)', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setNodeIds({'NODE-01', 'NODE-02'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(6));
        container.dispose();
      });

      test(
          'regression: Status=All + Node=X must not drop offline devices '
          '(they have null parentNodeId in reality)', () async {
        const offlineWithNullNode = DeviceUIModel(
          mac: 'AA:AA:AA:AA:AA:02',
          ip: '192.168.1.102',
          hostName: 'iPad',
          isActive: false,
          isWifi: true,
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
            .setNodeIds({'NODE-01'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered, hasLength(2));
        container.dispose();
      });
    });

    group('SSID / Band (multi-select OR)', () {
      test('single SSID filter shows matching WiFi devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSsidNames({'Guest'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isFalse);
        container.dispose();
      });

      test('multi-SSID filter shows devices on either SSID (OR)', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSsidNames({'Home', 'Guest'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isTrue);
        container.dispose();
      });

      test('band filter shows matching WiFi devices', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setBands({'2.4GHz'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOfflineHome.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiOnlineFair.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isFalse);
        container.dispose();
      });
    });

    group('Cross-dimension AND logic', () {
      test('Signal + Band combines with AND', () async {
        final container = await createReadyContainer();
        final notifier = container.read(deviceFilterConfigProvider.notifier);
        notifier.setSignals({DeviceSignalLevel.excellent});
        notifier.setBands({'5GHz'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiGuestGood.mac), isFalse);
        container.dispose();
      });

      test('SSID + Signal combines with AND', () async {
        final container = await createReadyContainer();
        final notifier = container.read(deviceFilterConfigProvider.notifier);
        notifier.setSsidNames({'Home'});
        notifier.setSignals({DeviceSignalLevel.excellent});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == wifiOnlineFair.mac), isFalse);
        container.dispose();
      });
    });

    group('Bug fix: WiFi-only filters exclude Ethernet', () {
      test('Signal filter excludes Ethernet when Connection is empty',
          () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSignals({DeviceSignalLevel.excellent});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isFalse);
        container.dispose();
      });

      test(
          'Signal filter includes Ethernet when Connection explicitly includes wired',
          () async {
        final container = await createReadyContainer();
        final notifier = container.read(deviceFilterConfigProvider.notifier);
        notifier.setSignals({DeviceSignalLevel.excellent});
        notifier.setConnections(
            {DeviceConnectionType.wifi, DeviceConnectionType.wired});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isTrue);
        container.dispose();
      });

      test('SSID filter excludes Ethernet when Connection is empty', () async {
        final container = await createReadyContainer();
        container
            .read(deviceFilterConfigProvider.notifier)
            .setSsidNames({'Home'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isFalse);
        container.dispose();
      });

      test('Band filter excludes Ethernet when Connection is empty', () async {
        final container = await createReadyContainer();
        container.read(deviceFilterConfigProvider.notifier).setBands({'5GHz'});

        final filtered = container.read(filteredDeviceListProvider);

        expect(filtered.any((d) => d.mac == wifiOnlineExcellent.mac), isTrue);
        expect(filtered.any((d) => d.mac == ethernetOnline.mac), isFalse);
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

      notifier.setConnections({DeviceConnectionType.wifi});
      notifier.setSignals({DeviceSignalLevel.good});
      notifier.setSsidNames({'Home'});
      notifier.setBands({'5GHz'});
      notifier.setNodeIds({'NODE-01'});
      notifier.setStatus(DeviceStatusFilter.offline);

      final state = container.read(deviceFilterConfigProvider);
      expect(state.status, DeviceStatusFilter.offline);
      expect(state.connections, isEmpty);
      expect(state.signals, isEmpty);
      expect(state.includeUnknownSignal, isFalse);
      expect(state.ssidNames, isEmpty);
      expect(state.bands, isEmpty);
      expect(state.nodeIds, isEmpty);
      container.dispose();
    });

    test('selecting Ethernet-only clears WiFi-only dimensions but keeps Node',
        () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setSignals({DeviceSignalLevel.good});
      notifier.setSsidNames({'Home'});
      notifier.setBands({'5GHz'});
      notifier.setNodeIds({'NODE-01'});
      notifier.setConnections({DeviceConnectionType.wired});

      final state = container.read(deviceFilterConfigProvider);
      expect(state.connections, {DeviceConnectionType.wired});
      expect(state.signals, isEmpty);
      expect(state.ssidNames, isEmpty);
      expect(state.bands, isEmpty);
      expect(state.nodeIds, {'NODE-01'});
      container.dispose();
    });

    test('selecting both WiFi and Ethernet does not clear WiFi filters',
        () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setSsidNames({'Home'});
      notifier.setConnections(
          {DeviceConnectionType.wifi, DeviceConnectionType.wired});

      expect(container.read(deviceFilterConfigProvider).ssidNames, {'Home'});
      container.dispose();
    });

    test('switching from Ethernet-only to All does not restore WiFi filters',
        () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setSsidNames({'Home'});
      notifier.setConnections({DeviceConnectionType.wired});
      notifier.setConnections({});

      expect(container.read(deviceFilterConfigProvider).ssidNames, isEmpty);
      container.dispose();
    });

    test('clearAll resets every dimension and search', () async {
      final container = await createReadyContainer();
      final notifier = container.read(deviceFilterConfigProvider.notifier);

      notifier.setStatus(DeviceStatusFilter.online);
      notifier.setSearchQuery('iphone');
      notifier.setSsidNames({'Home'});
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
    test('removes orphan SSIDs when they disappear from options', () async {
      final container = await createReadyContainer();
      container
          .read(deviceFilterConfigProvider.notifier)
          .setSsidNames({'Guest', 'Home'});

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

      expect(container.read(deviceFilterConfigProvider).ssidNames, {'Home'});
      container.dispose();
    });

    test('removes orphan nodeIds when selected node disappears', () async {
      final container = await createReadyContainer();
      container
          .read(deviceFilterConfigProvider.notifier)
          .setNodeIds({'NODE-01', 'NODE-02'});

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

      expect(container.read(deviceFilterConfigProvider).nodeIds, {'NODE-01'});
      container.dispose();
    });

    test('resets includeUnknownSignal when no null-RSSI devices remain',
        () async {
      final container = await createReadyContainer();
      container
          .read(deviceFilterConfigProvider.notifier)
          .setIncludeUnknownSignal(true);

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

      expect(container.read(deviceFilterConfigProvider).includeUnknownSignal,
          isFalse);
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
  // signalLevelOf
  // ---------------------------------------------------------------------------

  group('signalLevelOf', () {
    test('matches project-wide RSSI thresholds (-65 / -71 / -78)', () {
      expect(signalLevelOf(-30), DeviceSignalLevel.excellent);
      expect(signalLevelOf(-65), DeviceSignalLevel.excellent);
      expect(signalLevelOf(-66), DeviceSignalLevel.good);
      expect(signalLevelOf(-71), DeviceSignalLevel.good);
      expect(signalLevelOf(-72), DeviceSignalLevel.fair);
      expect(signalLevelOf(-78), DeviceSignalLevel.fair);
      expect(signalLevelOf(-79), DeviceSignalLevel.poor);
    });
  });

  // ---------------------------------------------------------------------------
  // DeviceFilterConfig state helpers
  // ---------------------------------------------------------------------------

  group('DeviceFilterConfig helpers', () {
    test('hasWifiOnlyFilter returns true when signal is set', () {
      final config = DeviceFilterConfig(signals: {DeviceSignalLevel.excellent});
      expect(config.hasWifiOnlyFilter, isTrue);
    });

    test('hasWifiOnlyFilter returns true when includeUnknownSignal is true',
        () {
      const config = DeviceFilterConfig(includeUnknownSignal: true);
      expect(config.hasWifiOnlyFilter, isTrue);
    });

    test('hasWifiOnlyFilter returns true when ssidNames is set', () {
      final config = DeviceFilterConfig(ssidNames: {'Home'});
      expect(config.hasWifiOnlyFilter, isTrue);
    });

    test('hasWifiOnlyFilter returns true when bands is set', () {
      final config = DeviceFilterConfig(bands: {'5GHz'});
      expect(config.hasWifiOnlyFilter, isTrue);
    });

    test('hasWifiOnlyFilter returns false when none are set', () {
      const config = DeviceFilterConfig();
      expect(config.hasWifiOnlyFilter, isFalse);
    });

    test('isEthernetOnly returns true only for single wired selection', () {
      expect(
        DeviceFilterConfig(connections: {DeviceConnectionType.wired})
            .isEthernetOnly,
        isTrue,
      );
      expect(
        DeviceFilterConfig(connections: {
          DeviceConnectionType.wifi,
          DeviceConnectionType.wired
        }).isEthernetOnly,
        isFalse,
      );
      expect(
        const DeviceFilterConfig().isEthernetOnly,
        isFalse,
      );
    });

    test('activeCount counts non-empty dimensions', () {
      expect(const DeviceFilterConfig().activeCount, 0);
      expect(
        DeviceFilterConfig(connections: {DeviceConnectionType.wifi})
            .activeCount,
        1,
      );
      expect(
        DeviceFilterConfig(
          connections: {DeviceConnectionType.wifi},
          signals: {DeviceSignalLevel.excellent},
        ).activeCount,
        2,
      );
    });

    test('activeCount includes deviceCategories and privateMac', () {
      expect(
        DeviceFilterConfig(deviceCategories: {DeviceCategory.phone})
            .activeCount,
        1,
      );
      expect(
        const DeviceFilterConfig(privateMac: PrivateMacFilter.privateOnly)
            .activeCount,
        1,
      );
      expect(
        DeviceFilterConfig(
          deviceCategories: {DeviceCategory.phone},
          privateMac: PrivateMacFilter.privateOnly,
        ).activeCount,
        2,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Device Category filter
  // ---------------------------------------------------------------------------

  group('filteredDeviceListProvider Device Category filter', () {
    test('filters by device category', () async {
      final container = await createReadyContainer();
      container
          .read(deviceFilterConfigProvider.notifier)
          .setDeviceCategories({DeviceCategory.phone});

      final filtered = container.read(filteredDeviceListProvider);

      // iPhone and GuestPhone should match phone category
      expect(filtered.any((d) => d.hostName == 'iPhone'), isTrue);
      expect(filtered.any((d) => d.hostName == 'GuestPhone'), isTrue);
      // Desktop should not match
      expect(filtered.any((d) => d.hostName == 'Desktop'), isFalse);
      container.dispose();
    });

    test('multi-select device categories uses OR logic', () async {
      final container = await createReadyContainer();
      container.read(deviceFilterConfigProvider.notifier).setDeviceCategories({
        DeviceCategory.phone,
        DeviceCategory.tablet,
      });

      final filtered = container.read(filteredDeviceListProvider);

      // iPhone, GuestPhone (phone), iPad (tablet) should match
      expect(filtered.any((d) => d.hostName == 'iPhone'), isTrue);
      expect(filtered.any((d) => d.hostName == 'iPad'), isTrue);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Private MAC filter
  // ---------------------------------------------------------------------------

  group('filteredDeviceListProvider Private MAC filter', () {
    // Private MAC: bit 1 of first byte = 1 (locally administered)
    // 0x02 = 00000010, bit 1 = 1 -> private
    const privateMacDevice = DeviceUIModel(
      mac: '02:00:00:AA:AA:01', // Locally administered (private)
      ip: '192.168.1.200',
      hostName: 'PrivatePhone',
      isActive: true,
      isWifi: true,
    );

    // Public MAC: bit 1 of first byte = 0 (OUI registered)
    // 0x00 = 00000000, bit 1 = 0 -> public
    const publicMacDevice = DeviceUIModel(
      mac: '00:11:22:33:44:55', // OUI registered (public)
      ip: '192.168.1.201',
      hostName: 'PublicPhone',
      isActive: true,
      isWifi: true,
    );

    test('privateOnly shows only private MAC devices', () async {
      final container = await createReadyContainer(
        data: const DevicesData(
          deviceModels: [privateMacDevice, publicMacDevice],
          meshTopology: MeshTopologyInfo(nodes: [], clientToNodeMap: {}),
        ),
      );
      container
          .read(deviceFilterConfigProvider.notifier)
          .setPrivateMac(PrivateMacFilter.privateOnly);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.hostName, 'PrivatePhone');
      container.dispose();
    });

    test('publicOnly shows only public MAC devices', () async {
      final container = await createReadyContainer(
        data: const DevicesData(
          deviceModels: [privateMacDevice, publicMacDevice],
          meshTopology: MeshTopologyInfo(nodes: [], clientToNodeMap: {}),
        ),
      );
      container
          .read(deviceFilterConfigProvider.notifier)
          .setPrivateMac(PrivateMacFilter.publicOnly);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.hostName, 'PublicPhone');
      container.dispose();
    });

    test('all shows both private and public MAC devices', () async {
      final container = await createReadyContainer(
        data: const DevicesData(
          deviceModels: [privateMacDevice, publicMacDevice],
          meshTopology: MeshTopologyInfo(nodes: [], clientToNodeMap: {}),
        ),
      );
      // Default is PrivateMacFilter.all, no need to set

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(2));
      container.dispose();
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

  void emit(DevicesData next) {
    _data = next;
    state = AsyncData(next);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
