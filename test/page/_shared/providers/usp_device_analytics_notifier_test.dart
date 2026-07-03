import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

/// Test-only devices data notifier returning canned data.
class _TestDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _data;
  final bool shouldThrow;
  _TestDevicesDataNotifier(this._data, {this.shouldThrow = false});

  @override
  Future<DevicesData> build() async {
    if (shouldThrow) throw Exception('devices fetch failed');
    return _data;
  }
}

void main() {
  final wifiDevice5g = ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'Phone',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: const WifiConnectionInfo(
      band: '5GHz',
      signalStrength: -55, // level 3 (excellent, >= -65)
    ),
  );

  final wifiDevice24g = ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'Tablet',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: const WifiConnectionInfo(
      band: '2.4GHz',
      signalStrength: -75, // level 1 (fair, -71..-78)
    ),
  );

  final wiredDevice = ClientDevice(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop',
    isActive: true,
    connectionType: ConnectionType.wired,
  );

  final offlineDevice = ClientDevice(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.103',
    hostName: 'Printer',
    isActive: false,
    connectionType: ConnectionType.wifi,
    wifi: const WifiConnectionInfo(
      band: '2.4GHz',
      signalStrength: -85,
    ),
  );

  final testDevices = [wifiDevice5g, wifiDevice24g, wiredDevice, offlineDevice];

  DevicesData createDevicesData(List<ClientDevice> clients) {
    return DevicesData(
      meshNetwork: MeshNetwork(
        master: MasterNode(
          deviceId: 'GATEWAY',
          model: 'Router',
          connectedClients: clients,
        ),
      ),
    );
  }

  final testDevicesData = createDevicesData(testDevices);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer createContainer(
      {DevicesData? data, bool shouldThrow = false}) {
    final devicesData = data ?? testDevicesData;
    final container = ProviderContainer(
      overrides: [
        devicesDataProvider.overrideWith(() =>
            _TestDevicesDataNotifier(devicesData, shouldThrow: shouldThrow)),
      ],
    );
    return container;
  }

  /// Wait for devicesDataProvider to resolve and analytics microtask to fire.
  Future<void> waitForAnalytics(ProviderContainer container) async {
    // Read analytics provider first to trigger build() and schedule microtask.
    container.read(uspDeviceAnalyticsProvider);
    // Wait for devicesDataProvider to resolve.
    try {
      await container.read(devicesDataProvider.future);
    } catch (_) {}
    // Let analytics microtask + listener + persistence run.
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
  }

  group('UspDeviceAnalyticsNotifier', () {
    test('build starts with empty state', () async {
      final container = createContainer();

      final state = container.read(uspDeviceAnalyticsProvider);
      expect(state.current, isNull);
      expect(state.hourlyHistory, isEmpty);
      expect(state.allKnownMacs, isEmpty);

      // Wait for async work before dispose.
      await waitForAnalytics(container);
      container.dispose();
    });

    test('dashboard update computes distribution', () async {
      final container = createContainer();
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);
      expect(state.current, isNotNull);

      final dist = state.current!;
      // 2 wifi online + 1 wired online = 3 online, 1 offline
      expect(dist.onlineCount, 3);
      expect(dist.offlineCount, 1);
      expect(dist.wifiCount, 2);
      expect(dist.wiredCount, 1);
      expect(dist.totalCount, 4);

      // Band distribution: 5GHz→1, 2.4GHz→1, Wired→1
      expect(dist.bandDistribution['5GHz'], 1);
      expect(dist.bandDistribution['2.4GHz'], 1);
      expect(dist.bandDistribution['Wired'], 1);
      container.dispose();
    });

    test('dashboard update creates hourly aggregate', () async {
      final container = createContainer();
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);
      expect(state.hourlyHistory, hasLength(1));

      final agg = state.hourlyHistory.first;
      expect(agg.wifiCount, 2);
      expect(agg.wiredCount, 1);
      // Active MACs: the 3 online devices
      expect(agg.activeMacs, contains('AA:BB:CC:DD:EE:01'));
      expect(agg.activeMacs, contains('AA:BB:CC:DD:EE:02'));
      expect(agg.activeMacs, contains('AA:BB:CC:DD:EE:03'));
      // Offline device not in active MACs
      expect(agg.activeMacs, isNot(contains('AA:BB:CC:DD:EE:04')));
      container.dispose();
    });

    test('allKnownMacs and macDisplayNames are populated', () async {
      final container = createContainer();
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);
      // allKnownMacs from hourly history active MACs (online only)
      expect(state.allKnownMacs, hasLength(3));

      // macDisplayNames includes ALL devices (online + offline)
      expect(state.macDisplayNames['AA:BB:CC:DD:EE:01'], 'Phone');
      expect(state.macDisplayNames['AA:BB:CC:DD:EE:02'], 'Tablet');
      expect(state.macDisplayNames['AA:BB:CC:DD:EE:03'], 'Desktop');
      expect(state.macDisplayNames['AA:BB:CC:DD:EE:04'], 'Printer');
      container.dispose();
    });

    test('signal level distribution counts WiFi devices by level', () async {
      final container = createContainer();
      await waitForAnalytics(container);

      final dist = container.read(uspDeviceAnalyticsProvider).current!;
      // Using wifi.dart thresholds (signalThresholdRSSI: [-65, -71, -78]):
      // wifiDevice5g: -55 dBm → level 3 (excellent, >= -65)
      // wifiDevice24g: -75 dBm → level 1 (fair, -71..-78)
      expect(dist.signalLevelDistribution[3], 1);
      expect(dist.signalLevelDistribution[1], 1);
      container.dispose();
    });

    test('empty device list produces empty distribution', () async {
      final container = createContainer(data: createDevicesData([]));
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);
      expect(state.current, isNotNull);
      expect(state.current!.onlineCount, 0);
      expect(state.current!.offlineCount, 0);
      expect(state.current!.bandDistribution, isEmpty);
      expect(state.current!.signalLevelDistribution, isEmpty);
      container.dispose();
    });

    test('hourly history older than 24h is pruned on dashboard update',
        () async {
      final now = DateTime.now();
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);

      // Pre-populate SharedPreferences with old + recent history entries.
      final oldHour = currentHour.subtract(Duration(hours: 25));
      final recentHour = currentHour.subtract(Duration(hours: 2));
      final persistedState = DeviceAnalyticsState(
        hourlyHistory: [
          HourlyAggregate(
            hour: oldHour,
            wifiCount: 5,
            wiredCount: 2,
            activeMacs: {'OLD:MAC:01'},
          ),
          HourlyAggregate(
            hour: recentHour,
            wifiCount: 3,
            wiredCount: 1,
            activeMacs: {'RECENT:MAC:01'},
          ),
        ],
        allKnownMacs: {'OLD:MAC:01', 'RECENT:MAC:01'},
        macDisplayNames: {'OLD:MAC:01': 'OldDevice', 'RECENT:MAC:01': 'Recent'},
      );
      SharedPreferences.setMockInitialValues({
        'usp_device_analytics': persistedState.toJsonString(),
      });

      final container = createContainer();
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);
      // The 25h-old entry should have been pruned (by both load and update).
      // Only the recent entry + the new current-hour entry should remain.
      for (final h in state.hourlyHistory) {
        expect(h.hour.isAfter(oldHour), isTrue,
            reason: 'Old entry ($oldHour) should be pruned');
      }
      // Old MAC should not appear in allKnownMacs anymore.
      expect(state.allKnownMacs, isNot(contains('OLD:MAC:01')));
      container.dispose();
    });

    test('devicesDataProvider error does not crash analytics', () async {
      final container = createContainer(shouldThrow: true);
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);
      // State remains at initial empty — devicesDataProvider error → no update.
      expect(state.current, isNull);
      expect(state.hourlyHistory, isEmpty);
      container.dispose();
    });

    test('band signal quality computes average per band', () async {
      // Two 5GHz devices with different signal strengths
      final wifi5a = ClientDevice(
        mac: 'FF:00:00:00:00:01',
        ip: '192.168.1.200',
        hostName: 'DeviceA',
        isActive: true,
        connectionType: ConnectionType.wifi,
        wifi: const WifiConnectionInfo(
          band: '5GHz',
          signalStrength: -30, // quality 1.0
        ),
      );
      final wifi5b = ClientDevice(
        mac: 'FF:00:00:00:00:02',
        ip: '192.168.1.201',
        hostName: 'DeviceB',
        isActive: true,
        connectionType: ConnectionType.wifi,
        wifi: const WifiConnectionInfo(
          band: '5GHz',
          signalStrength: -90, // quality 0.0
        ),
      );
      final data = createDevicesData([wifi5a, wifi5b]);
      final container = createContainer(data: data);
      await waitForAnalytics(container);

      final dist = container.read(uspDeviceAnalyticsProvider).current!;
      // Average quality for 5GHz = (1.0 + 0.0) / 2 = 0.5
      expect(dist.bandSignalQuality['5GHz'], closeTo(0.5, 0.01));
      container.dispose();
    });

    test('child node clients use parentNodeName as category', () async {
      // Master WiFi with band
      final masterWifi = ClientDevice(
        mac: 'FF:00:00:00:00:01',
        ip: '192.168.1.200',
        hostName: 'MasterClient',
        isActive: true,
        connectionType: ConnectionType.wifi,
        wifi: const WifiConnectionInfo(
          band: '5GHz',
          signalStrength: -50,
        ),
      );
      // Child node WiFi client (no band, has parentNodeName)
      final childWifi = ClientDevice(
        mac: 'FF:00:00:00:00:02',
        ip: '192.168.1.201',
        hostName: 'ChildClient',
        isActive: true,
        connectionType: ConnectionType.wifi,
        parentNodeId: 'CHILD_NODE_ID',
        parentNodeName: 'Extender-1',
        wifi: const WifiConnectionInfo(
          signalStrength: -60,
        ),
      );
      // Child node Wired client
      final childWired = ClientDevice(
        mac: 'FF:00:00:00:00:03',
        ip: '192.168.1.202',
        hostName: 'ChildWired',
        isActive: true,
        connectionType: ConnectionType.wired,
        parentNodeId: 'CHILD_NODE_ID',
        parentNodeName: 'Extender-1',
      );
      // Master Wired client (no parentNodeName)
      final masterWired = ClientDevice(
        mac: 'FF:00:00:00:00:04',
        ip: '192.168.1.203',
        hostName: 'MasterWired',
        isActive: true,
        connectionType: ConnectionType.wired,
      );
      final data =
          createDevicesData([masterWifi, childWifi, childWired, masterWired]);
      final container = createContainer(data: data);
      await waitForAnalytics(container);

      final dist = container.read(uspDeviceAnalyticsProvider).current!;
      // Master WiFi: uses band (5GHz)
      expect(dist.bandDistribution['5GHz'], 1);
      // Child node clients (WiFi + Wired): use parentNodeName
      expect(dist.bandDistribution['Extender-1'], 2);
      // Master Wired: uses "Wired"
      expect(dist.bandDistribution['Wired'], 1);
      container.dispose();
    });
  });
}
