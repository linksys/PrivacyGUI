import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  const wifiOnline = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:01',
    ip: '192.168.1.101',
    hostName: 'iPhone',
    isActive: true,
    isWifi: true,
    band: '5GHz',
    ssidName: 'Home',
    parentNodeId: 'NODE-01',
  );

  const wifiOffline = DeviceUIModel(
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

  const wifiGuest = DeviceUIModel(
    mac: 'AA:AA:AA:AA:AA:04',
    ip: '192.168.1.104',
    hostName: 'GuestPhone',
    isActive: true,
    isWifi: true,
    band: '5GHz',
    ssidName: 'Guest',
    parentNodeId: 'NODE-02',
  );

  const allDevices = [wifiOnline, wifiOffline, ethernetOnline, wifiGuest];

  const devicesData = DevicesData(
    deviceModels: allDevices,
    meshTopology: MeshTopologyInfo(
      nodes: [
        MeshNodeInfo(
            instancePath: 'Device.1.', deviceId: 'NODE-01', model: 'MR7500'),
        MeshNodeInfo(
            instancePath: 'Device.2.', deviceId: 'NODE-02', model: 'MX5500'),
      ],
      clientToNodeMap: {},
    ),
  );

  ProviderContainer createContainer({
    DeviceFilterConfig filter = const DeviceFilterConfig(),
  }) {
    return ProviderContainer(
      overrides: [
        devicesDataProvider
            .overrideWith(() => _FakeDevicesNotifier(devicesData)),
        deviceFilterConfigProvider.overrideWith((ref) => filter),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // filteredDeviceListProvider
  // ---------------------------------------------------------------------------

  group('filteredDeviceListProvider', () {
    test('returns all devices with default filter', () async {
      final container = createContainer();
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(4));
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Status filter
    // -----------------------------------------------------------------------

    test('online filter excludes offline devices', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(status: DeviceStatusFilter.online),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(3));
      expect(filtered.every((d) => d.isActive), isTrue);
      container.dispose();
    });

    test('offline filter shows only offline devices', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(status: DeviceStatusFilter.offline),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.mac, wifiOffline.mac);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Node filter
    // -----------------------------------------------------------------------

    test('node filter shows only devices on specified node', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(nodeId: 'NODE-02'),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.mac, wifiGuest.mac);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // SSID filter
    // -----------------------------------------------------------------------

    test('SSID filter shows matching WiFi devices and all ethernet devices',
        () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(ssidName: 'Guest'),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      // wifiGuest (Guest) + ethernetOnline (ethernet passes through)
      expect(filtered, hasLength(2));
      expect(filtered.any((d) => d.mac == wifiGuest.mac), isTrue);
      expect(filtered.any((d) => d.mac == ethernetOnline.mac), isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Band filter
    // -----------------------------------------------------------------------

    test('band filter shows matching WiFi devices and all ethernet devices',
        () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(band: '2.4GHz'),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      // wifiOffline (2.4GHz) + ethernetOnline (ethernet passes through)
      expect(filtered, hasLength(2));
      expect(filtered.any((d) => d.mac == wifiOffline.mac), isTrue);
      expect(filtered.any((d) => d.mac == ethernetOnline.mac), isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Search query
    // -----------------------------------------------------------------------

    test('search matches hostName case-insensitively', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(searchQuery: 'iphone'),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.mac, wifiOnline.mac);
      container.dispose();
    });

    test('search matches MAC address', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(searchQuery: 'aa:03'),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.mac, ethernetOnline.mac);
      container.dispose();
    });

    test('search matches IP address', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(searchQuery: '1.104'),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.mac, wifiGuest.mac);
      container.dispose();
    });

    test('search with no match returns empty list', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(searchQuery: 'nonexistent'),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, isEmpty);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Combined filters
    // -----------------------------------------------------------------------

    test('combined status + SSID filter narrows results', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(
          status: DeviceStatusFilter.online,
          ssidName: 'Home',
        ),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      // wifiOnline (Home, active) + ethernetOnline (ethernet passes SSID filter)
      expect(filtered, hasLength(2));
      expect(filtered.any((d) => d.mac == wifiOnline.mac), isTrue);
      expect(filtered.any((d) => d.mac == ethernetOnline.mac), isTrue);
      container.dispose();
    });

    test('combined node + search narrows results', () async {
      final container = createContainer(
        filter: const DeviceFilterConfig(
          nodeId: 'NODE-01',
          searchQuery: 'desktop',
        ),
      );
      await container.read(devicesDataProvider.future);

      final filtered = container.read(filteredDeviceListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.first.mac, ethernetOnline.mac);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // deviceFilterOptionsProvider
  // ---------------------------------------------------------------------------

  group('deviceFilterOptionsProvider', () {
    test('derives available SSIDs and bands from device data', () async {
      final container = createContainer();
      await container.read(devicesDataProvider.future);

      final options = container.read(deviceFilterOptionsProvider);

      expect(options.nodes, hasLength(2));
      expect(options.ssids, containsAll(['Guest', 'Home']));
      expect(options.bands, containsAll(['2.4GHz', '5GHz']));
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
      container.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Fake DevicesDataNotifier
// ---------------------------------------------------------------------------

class _FakeDevicesNotifier extends AsyncNotifier<DevicesData>
    implements DevicesDataNotifier {
  final DevicesData? _data;
  _FakeDevicesNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data ?? const DevicesData();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
