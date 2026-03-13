import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_analytics_state.dart';

const _prefsKey = 'usp_device_analytics';

/// Save hourly history + known MACs to SharedPreferences.
Future<void> saveDeviceAnalytics(DeviceAnalyticsState state) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, state.toJsonString());
}

/// Load hourly history from SharedPreferences.
///
/// Returns a state with only historical data (no current distribution).
/// Automatically prunes entries older than 24 hours.
Future<DeviceAnalyticsState> loadDeviceAnalytics() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_prefsKey);
  if (json == null) return const DeviceAnalyticsState();

  final loaded = DeviceAnalyticsState.fromJsonString(json);

  // Prune entries older than 24 hours
  final cutoff = DateTime.now().subtract(Duration(hours: 24));
  final pruned =
      loaded.hourlyHistory.where((h) => h.hour.isAfter(cutoff)).toList();

  // Rebuild allKnownMacs from pruned history only
  final activeMacs = <String>{};
  for (final h in pruned) {
    activeMacs.addAll(h.activeMacs);
  }

  return DeviceAnalyticsState(
    hourlyHistory: pruned,
    allKnownMacs: activeMacs,
    macDisplayNames: loaded.macDisplayNames,
  );
}
