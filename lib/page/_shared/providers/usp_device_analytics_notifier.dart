import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/providers/device_analytics_persistence.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

/// Device connection analytics provider — computes distributions, hourly
/// aggregates, and signal quality data from the existing dashboard state.
///
/// NOT autoDispose — hourly history persists across tab switches.
/// Watches [devicesDataProvider] for updates; no extra USP requests.
final uspDeviceAnalyticsProvider =
    NotifierProvider<UspDeviceAnalyticsNotifier, DeviceAnalyticsState>(
  UspDeviceAnalyticsNotifier.new,
);

class UspDeviceAnalyticsNotifier extends Notifier<DeviceAnalyticsState> {
  /// Cached serial number for persistence key scoping.
  String? _serialNumber;

  /// Whether persisted history has been loaded.
  bool _historyLoaded = false;

  @override
  DeviceAnalyticsState build() {
    // Reset instance state on rebuild (e.g., after invalidate)
    _historyLoaded = false;
    _serialNumber = null;

    // Listen to device data changes for future updates
    ref.listen(devicesDataProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      // Use clientDevices to exclude mesh nodes (master/slave)
      _onDashboardUpdated(data.clientDevices);
    });

    // Wait for systemInfoDataProvider to load, then load persisted history
    // and process current device data
    Future.microtask(() async {
      await _loadPersistedHistory();

      final data = ref.read(devicesDataProvider).valueOrNull;
      if (data != null) {
        _onDashboardUpdated(data.clientDevices);
      }
    });

    return const DeviceAnalyticsState();
  }

  Future<void> _loadPersistedHistory() async {
    if (_historyLoaded) return;

    try {
      // Wait for systemInfoDataProvider to have data
      final sysInfo = ref.read(systemInfoDataProvider).valueOrNull;
      if (sysInfo == null) {
        // Try to wait for it
        try {
          await ref
              .read(systemInfoDataProvider.future)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          // Timeout or error — proceed without SN (uses legacy key)
        }
      }

      _serialNumber =
          ref.read(systemInfoDataProvider).valueOrNull?.model.serialNumber;

      final persisted = await loadDeviceAnalytics(serialNumber: _serialNumber);
      if (persisted.hourlyHistory.isNotEmpty) {
        // Get router MACs to filter out from persisted history
        // (legacy data may contain mesh node MACs before the fix)
        final routerMacs = _getRouterMacs();

        // Clean router MACs from persisted data
        final cleanedHistory = persisted.hourlyHistory
            .map((h) => HourlyAggregate(
                  hour: h.hour,
                  wifiCount: h.wifiCount,
                  wiredCount: h.wiredCount,
                  activeMacs: h.activeMacs
                      .where((m) => !routerMacs.contains(m))
                      .toSet(),
                ))
            .toList();

        final cleanedMacs = persisted.allKnownMacs
            .where((m) => !routerMacs.contains(m))
            .toSet();

        state = state.copyWith(
          hourlyHistory: cleanedHistory,
          allKnownMacs: cleanedMacs,
          macDisplayNames: persisted.macDisplayNames,
        );
      }

      _historyLoaded = true;
    } catch (e) {
      logger
          .w('[USP][Monitor][Analytics]: Failed to load persisted history: $e');
      // Mark as loaded even on failure so subsequent _persistState() calls are
      // not permanently gated by `if (!_historyLoaded) return`. Otherwise a
      // one-off load error (e.g. SharedPreferences cold-start race, corrupted
      // JSON) would silently drop every future write for this provider's life.
      _historyLoaded = true;
    }
  }

  /// Returns the set of router MACs (master + slave nodes).
  /// Used to clean legacy persisted data that may contain mesh node MACs.
  Set<String> _getRouterMacs() {
    final data = ref.read(devicesDataProvider).valueOrNull;
    if (data == null) return {};
    final nodeMacs = <String>{data.master.deviceId};
    for (final slave in data.slaves) {
      nodeMacs.add(slave.deviceId);
    }
    return nodeMacs;
  }

  void _onDashboardUpdated(List<ClientDevice> devices) {
    // 1. Compute current distribution
    final distribution = _computeDistribution(devices);

    // 2. Update hourly aggregates
    final now = DateTime.now();
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final onlineMacs =
        devices.where((d) => d.isActive).map((d) => d.mac).toSet();

    // Build display name map from current devices
    final displayNames = Map<String, String>.from(state.macDisplayNames);
    for (final d in devices) {
      displayNames[d.mac] = d.displayName;
    }

    var history = List<HourlyAggregate>.from(state.hourlyHistory);

    if (history.isNotEmpty && history.last.hour == currentHour) {
      // Update the current hour's aggregate
      final existing = history.last;
      history[history.length - 1] = HourlyAggregate(
        hour: currentHour,
        wifiCount: distribution.wifiCount,
        wiredCount: distribution.wiredCount,
        activeMacs: {...existing.activeMacs, ...onlineMacs},
      );
    } else {
      // New hour — append
      history.add(HourlyAggregate(
        hour: currentHour,
        wifiCount: distribution.wifiCount,
        wiredCount: distribution.wiredCount,
        activeMacs: onlineMacs,
      ));
    }

    // Prune older than 24h
    final cutoff = now.subtract(Duration(hours: DeviceAnalyticsState.maxHours));
    history = history.where((h) => h.hour.isAfter(cutoff)).toList();

    // Rebuild allKnownMacs from history (clientDevices already excludes mesh nodes)
    final allMacs = <String>{};
    for (final h in history) {
      allMacs.addAll(h.activeMacs);
    }

    state = state.copyWith(
      current: () => distribution,
      hourlyHistory: history,
      allKnownMacs: allMacs,
      macDisplayNames: displayNames,
    );

    // Persist asynchronously (fire-and-forget)
    _persistState();
  }

  DeviceDistribution _computeDistribution(List<ClientDevice> devices) {
    final online = devices.where((d) => d.isActive).toList();
    final offline = devices.where((d) => !d.isActive).toList();

    // WiFi vs Wired counts (online only for meaningful distribution)
    final wifiDevices = online.where((d) => d.isWifi).toList();
    final wiredDevices = online.where((d) => !d.isWifi).toList();

    // Category distribution (online only) — see _getDeviceCategory:
    // - WiFi with a band: show band (2.4GHz, 5GHz, 6GHz)
    // - Wired: show "Wired"
    // - WiFi without a band (e.g. slave clients pending #1118): show node name
    final categoryDist = <String, int>{};
    for (final d in online) {
      final category = _getDeviceCategory(d);
      categoryDist[category] = (categoryDist[category] ?? 0) + 1;
    }

    // Signal level distribution (online WiFi only)
    final signalDist = <int, int>{};
    for (final d in wifiDevices) {
      final level = d.signalLevel;
      signalDist[level] = (signalDist[level] ?? 0) + 1;
    }

    // Average signal quality per category (WiFi devices only)
    final categoryQualitySum = <String, double>{};
    final categoryQualityCount = <String, int>{};
    for (final d in wifiDevices) {
      final category = _getDeviceCategory(d);
      categoryQualitySum[category] =
          (categoryQualitySum[category] ?? 0) + d.signalQuality;
      categoryQualityCount[category] =
          (categoryQualityCount[category] ?? 0) + 1;
    }
    final bandSignalQuality = <String, double>{};
    for (final cat in categoryQualitySum.keys) {
      bandSignalQuality[cat] =
          categoryQualitySum[cat]! / categoryQualityCount[cat]!;
    }

    return DeviceDistribution(
      wifiCount: wifiDevices.length,
      wiredCount: wiredDevices.length,
      onlineCount: online.length,
      offlineCount: offline.length,
      bandDistribution: categoryDist,
      signalLevelDistribution: signalDist,
      bandSignalQuality: bandSignalQuality,
    );
  }

  /// Determines the display category for a device.
  ///
  /// - WiFi client with a resolved band: the band (2.4GHz / 5GHz / 6GHz)
  /// - Wired client: "Wired"
  /// - WiFi client without a band: the connected node name, else "WiFi"
  ///
  /// Band takes priority over the node grouping, because a master WiFi client
  /// keeps a valid band in a mesh too (it comes from the local
  /// `WiFi.AccessPoint` chain, not DataElements). Keying off `parentNodeId`
  /// alone was wrong: `MeshTopologyBuilder` maps EVERY node's associated STAs —
  /// including the master's own clients — into `clientToNodeMap`, so master
  /// clients also get a non-null `parentNodeId` on a mesh, which previously
  /// collapsed their band under the gateway name.
  ///
  /// Slave WiFi clients currently have no band (DataElements band resolution is
  /// pending — see #1118), so they fall through to the node-name grouping.
  String _getDeviceCategory(ClientDevice d) {
    if (d.isWifi) {
      final band = d.band;
      if (band != null && band.isNotEmpty) return band;
      // WiFi client without a resolved band: group under its node.
      return d.parentNodeName ?? 'WiFi';
    }
    return 'Wired';
  }

  Future<void> _persistState() async {
    // Don't persist before history is loaded — _serialNumber isn't set yet,
    // and we'd write to the legacy key instead of the scoped key.
    if (!_historyLoaded) return;
    try {
      await saveDeviceAnalytics(state, serialNumber: _serialNumber);
    } catch (e) {
      logger.w('[USP][Monitor][Analytics]: Failed to persist: $e');
    }
  }
}
