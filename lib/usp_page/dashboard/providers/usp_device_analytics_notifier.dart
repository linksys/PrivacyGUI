import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_analytics_state.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/device_analytics_persistence.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';

/// Device connection analytics provider — computes distributions, hourly
/// aggregates, and signal quality data from the existing dashboard state.
///
/// NOT autoDispose — hourly history persists across tab switches.
/// Watches [uspDashboardProvider] for updates; no extra USP requests.
final uspDeviceAnalyticsProvider =
    NotifierProvider<UspDeviceAnalyticsNotifier, DeviceAnalyticsState>(
  UspDeviceAnalyticsNotifier.new,
);

class UspDeviceAnalyticsNotifier extends Notifier<DeviceAnalyticsState> {
  @override
  DeviceAnalyticsState build() {
    // Load persisted history on init
    _loadPersistedHistory();

    // Listen to dashboard state changes for future updates
    ref.listen(uspDashboardProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      _onDashboardUpdated(data.deviceModels);
    });

    // Process current dashboard data after build() completes
    // (same pattern as UspTrafficMonitorNotifier)
    Future.microtask(() {
      final data = ref.read(uspDashboardProvider).valueOrNull;
      if (data != null) {
        _onDashboardUpdated(data.deviceModels);
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
      logger.w('[USP][Monitor][Analytics]Failed to load persisted history: $e');
    }
  }

  void _onDashboardUpdated(List<DeviceUIModel> devices) {
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

  DeviceDistribution _computeDistribution(List<DeviceUIModel> devices) {
    final online = devices.where((d) => d.isActive).toList();
    final offline = devices.where((d) => !d.isActive).toList();

    // WiFi vs Wired counts (online only for meaningful distribution)
    final wifiDevices = online.where((d) => d.isWifi).toList();
    final wiredDevices = online.where((d) => !d.isWifi).toList();

    // Band distribution (online WiFi only + wired category)
    final bandDist = <String, int>{};
    for (final d in wifiDevices) {
      final band = d.band ?? 'Unknown';
      bandDist[band] = (bandDist[band] ?? 0) + 1;
    }
    if (wiredDevices.isNotEmpty) {
      bandDist['Wired'] = wiredDevices.length;
    }

    // Signal level distribution (online WiFi only)
    final signalDist = <int, int>{};
    for (final d in wifiDevices) {
      final level = d.signalLevel;
      signalDist[level] = (signalDist[level] ?? 0) + 1;
    }

    // Average signal quality per band (for radar chart)
    final bandQualitySum = <String, double>{};
    final bandQualityCount = <String, int>{};
    for (final d in wifiDevices) {
      final band = d.band ?? 'Unknown';
      bandQualitySum[band] = (bandQualitySum[band] ?? 0) + d.signalQuality;
      bandQualityCount[band] = (bandQualityCount[band] ?? 0) + 1;
    }
    final bandSignalQuality = <String, double>{};
    for (final band in bandQualitySum.keys) {
      bandSignalQuality[band] = bandQualitySum[band]! / bandQualityCount[band]!;
    }

    return DeviceDistribution(
      wifiCount: wifiDevices.length,
      wiredCount: wiredDevices.length,
      onlineCount: online.length,
      offlineCount: offline.length,
      bandDistribution: bandDist,
      signalLevelDistribution: signalDist,
      bandSignalQuality: bandSignalQuality,
    );
  }

  Future<void> _persistState() async {
    try {
      await saveDeviceAnalytics(state);
    } catch (e) {
      logger.w('[USP][Monitor][Analytics]Failed to persist: $e');
    }
  }
}
