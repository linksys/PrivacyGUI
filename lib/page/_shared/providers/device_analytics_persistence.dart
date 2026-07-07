import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_analytics_state.dart';

const _prefsKeyPrefix = 'usp_device_analytics';

/// Build storage key scoped to a specific router by serial number.
///
/// This ensures analytics history from different routers don't mix.
String _buildKey(String? serialNumber) {
  if (serialNumber == null || serialNumber.isEmpty) {
    return _prefsKeyPrefix;
  }
  return '${_prefsKeyPrefix}_$serialNumber';
}

/// Save hourly history + known MACs to SharedPreferences.
///
/// [serialNumber] scopes the data to a specific router (master SN).
Future<void> saveDeviceAnalytics(
  DeviceAnalyticsState state, {
  String? serialNumber,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_buildKey(serialNumber), state.toJsonString());
}

/// Load hourly history from SharedPreferences.
///
/// [serialNumber] scopes the data to a specific router (master SN).
/// Returns a state with only historical data (no current distribution).
/// Automatically prunes entries older than 24 hours.
Future<DeviceAnalyticsState> loadDeviceAnalytics({String? serialNumber}) async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_buildKey(serialNumber));
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
