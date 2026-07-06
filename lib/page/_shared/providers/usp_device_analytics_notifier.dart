import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
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
  Set<String> _getRouterMacs() {
    final allDeviceModels =
        ref.read(devicesDataProvider).valueOrNull?.deviceModels ?? [];
    return allDeviceModels.where((d) => d.isMeshNode).map((d) => d.mac).toSet();
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

    // Get router MACs to filter out from history (mesh nodes should not appear)
    final routerMacs = _getRouterMacs();

    // Rebuild allKnownMacs from history, excluding router MACs
    final allMacs = <String>{};
    for (final h in history) {
      allMacs.addAll(h.activeMacs.where((mac) => !routerMacs.contains(mac)));
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
