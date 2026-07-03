import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/providers/device_analytics_persistence.dart';
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
  @override
  DeviceAnalyticsState build() {
    // Load persisted history on init
    _loadPersistedHistory();

    // Listen to device data changes for future updates
    ref.listen(devicesDataProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      // Use clientDevices to exclude mesh nodes (master/slave)
      _onDashboardUpdated(data.clientDevices);
    });

    // Process current device data after build() completes
    // (same pattern as UspTrafficMonitorNotifier)
    Future.microtask(() {
      final data = ref.read(devicesDataProvider).valueOrNull;
      if (data != null) {
        _onDashboardUpdated(data.clientDevices);
      }
    });

    return const DeviceAnalyticsState();
  }

  Future<void> _loadPersistedHistory() async {
    try {
      final persisted = await loadDeviceAnalytics();
      if (persisted.hourlyHistory.isNotEmpty) {
        state = state.copyWith(
          hourlyHistory: persisted.hourlyHistory,
          allKnownMacs: persisted.allKnownMacs,
          macDisplayNames: persisted.macDisplayNames,
        );
      }
    } catch (e) {
      logger
          .w('[USP][Monitor][Analytics]: Failed to load persisted history: $e');
    }
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

    // Rebuild allKnownMacs from history
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

    // Category distribution (online only):
    // - Master WiFi with band: show band (2.4GHz, 5GHz, 6GHz)
    // - Child node WiFi: show parentNodeName (e.g., "Community00090")
    // - Master Wired: show "Wired"
    // - Child node Wired: show parentNodeName
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
  /// - Master WiFi with band: actual band (2.4GHz, 5GHz, 6GHz)
  /// - Child node client (WiFi or Wired): parentNodeName
  /// - Master Wired: "Wired"
  String _getDeviceCategory(ClientDevice d) {
    final isChildNodeClient = d.parentNodeName != null && d.band == null;
    if (isChildNodeClient) {
      return d.parentNodeName!;
    }
    if (d.isWifi) {
      return d.band ?? 'WiFi';
    }
    return 'Wired';
  }

  Future<void> _persistState() async {
    try {
      await saveDeviceAnalytics(state);
    } catch (e) {
      logger.w('[USP][Monitor][Analytics]: Failed to persist: $e');
    }
  }
}
