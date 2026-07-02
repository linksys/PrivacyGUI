import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
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

/// Test-only system info notifier returning canned data.
class _TestSystemInfoDataNotifier extends SystemInfoDataNotifier {
  final String serialNumber;
  _TestSystemInfoDataNotifier({this.serialNumber = 'TEST_SN_001'});

  @override
  Future<SystemInfoData> build() async {
    return SystemInfoData(
      model: SystemInfoUIModel(
        modelName: 'TestRouter',
        hardwareVersion: '1.0',
        manufacturer: 'Test',
        serialNumber: serialNumber,
        softwareVersion: '1.0.0',
        uptime: 3600,
        totalMemory: 512000,
        freeMemory: 256000,
        cpuUsage: 25,
      ),
    );
  }
}

void main() {
  const wifiDevice5g = DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'Phone',
    isActive: true,
    isWifi: true,
    band: '5GHz',
    signalStrength: -55, // level 3 (excellent, >= -65)
  );

  const wifiDevice24g = DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'Tablet',
    isActive: true,
    isWifi: true,
    band: '2.4GHz',
    signalStrength: -75, // level 1 (fair, -71..-78)
  );

  const wiredDevice = DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop',
    isActive: true,
    isWifi: false,
  );

  const offlineDevice = DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.103',
    hostName: 'Printer',
    isActive: false,
    isWifi: true,
    band: '2.4GHz',
    signalStrength: -85,
  );

  final testDevices = [wifiDevice5g, wifiDevice24g, wiredDevice, offlineDevice];
  final testDevicesData = DevicesData(deviceModels: testDevices);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer createContainer({
    DevicesData? data,
    bool shouldThrow = false,
    String serialNumber = 'TEST_SN_001',
  }) {
    final devicesData = data ?? testDevicesData;
    final container = ProviderContainer(
      overrides: [
        devicesDataProvider.overrideWith(() =>
            _TestDevicesDataNotifier(devicesData, shouldThrow: shouldThrow)),
        systemInfoDataProvider.overrideWith(
            () => _TestSystemInfoDataNotifier(serialNumber: serialNumber)),
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
      final container = createContainer(data: const DevicesData());
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

    test('excludes mesh nodes from distribution', () async {
      // Add mesh nodes (master and slave routers) to the device list
      const masterNode = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:05',
        ip: '192.168.1.1',
        hostName: 'Router',
        isActive: true,
        isWifi: false,
        deviceRole: 'master',
      );
      const slaveNode = DeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:06',
        ip: '192.168.1.2',
        hostName: 'Extender',
        isActive: true,
        isWifi: true,
        band: '5GHz',
        signalStrength: -50,
        deviceRole: 'slave',
      );
      // Include mesh nodes alongside regular client devices
      final dataWithMesh = DevicesData(
        deviceModels: [...testDevices, masterNode, slaveNode],
      );
      final container = createContainer(data: dataWithMesh);
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);
      expect(state.current, isNotNull);

      final dist = state.current!;
      // Mesh nodes should NOT be counted — same as without them
      // 2 wifi online + 1 wired online = 3 online, 1 offline (no mesh nodes)
      expect(dist.onlineCount, 3);
      expect(dist.offlineCount, 1);
      expect(dist.wifiCount, 2);
      expect(dist.wiredCount, 1);
      expect(dist.totalCount, 4);

      // Band distribution should NOT include the slave's 5GHz
      expect(dist.bandDistribution['5GHz'], 1); // Only wifiDevice5g
      expect(dist.bandDistribution['2.4GHz'], 1);
      expect(dist.bandDistribution['Wired'], 1);
      container.dispose();
    });

    test('band signal quality computes average per band', () async {
      // Two 5GHz devices with different signal strengths
      const wifi5a = DeviceUIModel(
        mac: 'FF:00:00:00:00:01',
        ip: '192.168.1.200',
        hostName: 'DeviceA',
        isActive: true,
        isWifi: true,
        band: '5GHz',
        signalStrength: -30, // quality 1.0
      );
      const wifi5b = DeviceUIModel(
        mac: 'FF:00:00:00:00:02',
        ip: '192.168.1.201',
        hostName: 'DeviceB',
        isActive: true,
        isWifi: true,
        band: '5GHz',
        signalStrength: -90, // quality 0.0
      );
      const data = DevicesData(deviceModels: [wifi5a, wifi5b]);
      final container = createContainer(data: data);
      await waitForAnalytics(container);

      final dist = container.read(uspDeviceAnalyticsProvider).current!;
      // Average quality for 5GHz = (1.0 + 0.0) / 2 = 0.5
      expect(dist.bandSignalQuality['5GHz'], closeTo(0.5, 0.01));
      container.dispose();
    });

    test('filters router MACs from persisted history on load', () async {
      // Simulate legacy persisted data that includes router MACs
      final now = DateTime.now();
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);
      const routerMac = 'AA:BB:CC:DD:EE:05'; // Will be marked as master
      const clientMac = 'AA:BB:CC:DD:EE:01'; // Regular client

      final legacyState = DeviceAnalyticsState(
        hourlyHistory: [
          HourlyAggregate(
            hour: currentHour.subtract(Duration(hours: 1)),
            wifiCount: 2,
            wiredCount: 0,
            activeMacs: {routerMac, clientMac}, // Legacy: contains router MAC
          ),
        ],
        allKnownMacs: {routerMac, clientMac},
        macDisplayNames: {routerMac: 'Router', clientMac: 'Phone'},
      );

      // Pre-populate SharedPreferences with legacy data
      SharedPreferences.setMockInitialValues({
        'flutter.usp_device_analytics_LEGACY_SN': legacyState.toJsonString(),
      });

      // Create container with a mesh node that has the router MAC
      const masterNode = DeviceUIModel(
        mac: routerMac,
        ip: '192.168.1.1',
        hostName: 'Router',
        isActive: true,
        isWifi: false,
        deviceRole: 'master',
      );
      final dataWithRouter = DevicesData(
        deviceModels: [wifiDevice5g, masterNode],
      );

      final container = createContainer(
        data: dataWithRouter,
        serialNumber: 'LEGACY_SN',
      );
      await waitForAnalytics(container);

      final state = container.read(uspDeviceAnalyticsProvider);

      // Router MAC should be filtered out from allKnownMacs
      expect(state.allKnownMacs, isNot(contains(routerMac)));
      expect(state.allKnownMacs, contains(clientMac));

      // Hourly history activeMacs should also exclude router MAC
      for (final h in state.hourlyHistory) {
        expect(h.activeMacs, isNot(contains(routerMac)));
      }

      container.dispose();
    });

    test('persistence is scoped by router serial number', () async {
      // First router with SN "ROUTER_A"
      final containerA = createContainer(serialNumber: 'ROUTER_A');
      await waitForAnalytics(containerA);
      final stateA = containerA.read(uspDeviceAnalyticsProvider);
      expect(stateA.hourlyHistory, hasLength(1));
      containerA.dispose();

      // Second router with different SN "ROUTER_B"
      final containerB = createContainer(
        data: const DevicesData(deviceModels: []),
        serialNumber: 'ROUTER_B',
      );
      await waitForAnalytics(containerB);
      final stateB = containerB.read(uspDeviceAnalyticsProvider);
      // Should NOT inherit history from Router A — different SN means different key
      expect(stateB.hourlyHistory, hasLength(1)); // Only its own empty entry
      expect(stateB.current!.onlineCount, 0); // Empty device list
      containerB.dispose();

      // Back to Router A — should still have its data
      final containerA2 = createContainer(serialNumber: 'ROUTER_A');
      await waitForAnalytics(containerA2);
      final stateA2 = containerA2.read(uspDeviceAnalyticsProvider);
      // Should have 2 entries now (original + this session's update)
      expect(stateA2.hourlyHistory.isNotEmpty, isTrue);
      expect(
          stateA2.current!.onlineCount, 3); // Has devices from testDevicesData
      containerA2.dispose();
    });
  });
}
