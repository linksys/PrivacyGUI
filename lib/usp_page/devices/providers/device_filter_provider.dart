import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/devices/providers/device_filter_state.dart';

/// User-selected filter configuration (UI directly mutates this).
final deviceFilterConfigProvider = StateProvider<DeviceFilterConfig>(
  (ref) => const DeviceFilterConfig(),
);

/// Available filter options derived from current dashboard device data.
final deviceFilterOptionsProvider = Provider<DeviceFilterOptions>((ref) {
  final state = ref.watch(uspDashboardProvider).valueOrNull;
  if (state == null) return const DeviceFilterOptions();
  final devices = state.deviceModels;
  return DeviceFilterOptions(
    nodes: state.meshTopology.nodes,
    ssids: devices
        .map((d) => d.ssidName)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
    bands: devices
        .map((d) => d.band)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  );
});

/// Filtered device list — applies all 4 filter dimensions + search.
final filteredDeviceListProvider = Provider<List<DeviceUIModel>>((ref) {
  final state = ref.watch(uspDashboardProvider).valueOrNull;
  if (state == null) return [];
  final filter = ref.watch(deviceFilterConfigProvider);
  return state.deviceModels.where((d) => _matches(d, filter)).toList();
});

bool _matches(DeviceUIModel device, DeviceFilterConfig filter) {
  // Status filter
  if (filter.status == DeviceStatusFilter.online && !device.isActive) {
    return false;
  }
  if (filter.status == DeviceStatusFilter.offline && device.isActive) {
    return false;
  }

  // Node filter
  if (filter.nodeId != null && device.parentNodeId != filter.nodeId) {
    return false;
  }

  // SSID filter (Ethernet devices pass through — SSID doesn't apply)
  if (filter.ssidName != null && device.isWifi && device.ssidName != filter.ssidName) {
    return false;
  }

  // Band filter (Ethernet devices pass through — band doesn't apply)
  if (filter.band != null && device.isWifi && device.band != filter.band) {
    return false;
  }

  // Search query — match hostname, MAC, or IP (case-insensitive)
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    final matchesHostName = device.hostName.toLowerCase().contains(q);
    final matchesMac = device.mac.toLowerCase().contains(q);
    final matchesIp = device.ip.toLowerCase().contains(q);
    if (!matchesHostName && !matchesMac && !matchesIp) return false;
  }

  return true;
}
