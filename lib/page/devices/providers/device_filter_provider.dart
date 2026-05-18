import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';

/// Bucket a signal strength (dBm) into a `DeviceSignalFilter` value.
/// Delegates to [getWifiSignalLevel] so the filter, the list-tile indicator,
/// and every other project surface share the same RSSI thresholds
/// (-65 / -71 / -78 dBm for excellent / good / fair).
DeviceSignalFilter signalBucketOf(int? rssi) {
  if (rssi == null) return DeviceSignalFilter.unknown;
  return switch (getWifiSignalLevel(rssi)) {
    NodeSignalLevel.excellent => DeviceSignalFilter.excellent,
    NodeSignalLevel.good => DeviceSignalFilter.good,
    NodeSignalLevel.fair => DeviceSignalFilter.fair,
    NodeSignalLevel.poor || NodeSignalLevel.none => DeviceSignalFilter.poor,
    // `wired` only returns when rssi is null, which we handled above.
    NodeSignalLevel.wired => DeviceSignalFilter.unknown,
  };
}

/// Map a `DeviceSignalFilter` bucket back to the canonical [NodeSignalLevel]
/// so UI can reuse [NodeSignalLevelExt.resolveLabel] / `resolveColor` and
/// stay consistent with the node/topology pages.
NodeSignalLevel? nodeLevelOf(DeviceSignalFilter bucket) {
  return switch (bucket) {
    DeviceSignalFilter.all => null,
    DeviceSignalFilter.excellent => NodeSignalLevel.excellent,
    DeviceSignalFilter.good => NodeSignalLevel.good,
    DeviceSignalFilter.fair => NodeSignalLevel.fair,
    DeviceSignalFilter.poor => NodeSignalLevel.poor,
    DeviceSignalFilter.unknown => null,
  };
}

/// User-selected filter configuration. Hosted in a notifier so that all
/// cross-field dependency resets (e.g. Status=Offline clears everything else)
/// and orphan reconciliation (e.g. selected SSID disappears after SSE refresh)
/// happen in one place rather than being duplicated at every call site.
final deviceFilterConfigProvider =
    StateNotifierProvider<DeviceFilterNotifier, DeviceFilterConfig>((ref) {
  return DeviceFilterNotifier(ref);
});

class DeviceFilterNotifier extends StateNotifier<DeviceFilterConfig> {
  DeviceFilterNotifier(this._ref) : super(const DeviceFilterConfig()) {
    // Reconcile when the underlying option set changes (SSE refresh, devices
    // join/leave, node drops). Clears any field that no longer has a matching
    // option so the UI never shows an invisible active filter.
    _ref.listen<DeviceFilterOptions>(
      deviceFilterOptionsProvider,
      (_, options) => _reconcile(options),
      fireImmediately: true,
    );
  }

  final Ref _ref;

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  /// Status flips are the widest-blast-radius change: Offline collapses every
  /// other dimension because offline devices have no live SSID/band/RSSI/node.
  void setStatus(DeviceStatusFilter value) {
    if (value == DeviceStatusFilter.offline) {
      state = state.copyWith(
        status: value,
        connection: DeviceConnectionFilter.all,
        signal: DeviceSignalFilter.all,
        nodeId: () => null,
        ssidName: () => null,
        band: () => null,
      );
      return;
    }
    state = state.copyWith(status: value);
  }

  /// Picking Ethernet invalidates every WiFi-only dimension; picking WiFi or
  /// All does not need to clear anything (Ethernet filter was never gating
  /// them).
  void setConnection(DeviceConnectionFilter value) {
    if (value == DeviceConnectionFilter.ethernet) {
      state = state.copyWith(
        connection: value,
        signal: DeviceSignalFilter.all,
        ssidName: () => null,
        band: () => null,
      );
      return;
    }
    state = state.copyWith(connection: value);
  }

  void setSignal(DeviceSignalFilter value) {
    state = state.copyWith(signal: value);
  }

  void setNodeId(String? value) {
    state = state.copyWith(nodeId: () => value);
  }

  void setSsidName(String? value) {
    state = state.copyWith(ssidName: () => value);
  }

  void setBand(String? value) {
    state = state.copyWith(band: () => value);
  }

  void clearAll() {
    state = state.copyWith(
      searchQuery: '',
      status: DeviceStatusFilter.all,
      connection: DeviceConnectionFilter.all,
      signal: DeviceSignalFilter.all,
      nodeId: () => null,
      ssidName: () => null,
      band: () => null,
    );
  }

  void _reconcile(DeviceFilterOptions options) {
    var next = state;
    if (next.nodeId != null &&
        !options.nodes.any((n) => n.deviceId == next.nodeId)) {
      next = next.copyWith(nodeId: () => null);
    }
    if (next.ssidName != null && !options.ssids.contains(next.ssidName)) {
      next = next.copyWith(ssidName: () => null);
    }
    if (next.band != null && !options.bands.contains(next.band)) {
      next = next.copyWith(band: () => null);
    }
    if (next.signal == DeviceSignalFilter.unknown &&
        !options.hasUnknownSignalDevices) {
      next = next.copyWith(signal: DeviceSignalFilter.all);
    }
    if (next != state) state = next;
  }
}

/// Available filter options derived from current device data.
final deviceFilterOptionsProvider = Provider<DeviceFilterOptions>((ref) {
  final data = ref.watch(devicesDataProvider).valueOrNull;
  if (data == null) return const DeviceFilterOptions();
  final devices = data.clientDevices;
  return DeviceFilterOptions(
    nodes: data.meshTopology.nodes,
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
    hasUnknownSignalDevices:
        devices.any((d) => d.isWifi && d.signalStrength == null),
  );
});

/// Filtered device list — applies every active dimension + search.
final filteredDeviceListProvider = Provider<List<DeviceUIModel>>((ref) {
  final data = ref.watch(devicesDataProvider).valueOrNull;
  if (data == null) return [];
  final filter = ref.watch(deviceFilterConfigProvider);
  return data.clientDevices.where((d) => _matches(d, filter)).toList();
});

bool _matches(DeviceUIModel device, DeviceFilterConfig filter) {
  // Status.
  if (filter.status == DeviceStatusFilter.online && !device.isActive) {
    return false;
  }
  if (filter.status == DeviceStatusFilter.offline && device.isActive) {
    return false;
  }

  // Connection type (WiFi vs. Ethernet).
  if (filter.connection == DeviceConnectionFilter.wifi && !device.isWifi) {
    return false;
  }
  if (filter.connection == DeviceConnectionFilter.ethernet && device.isWifi) {
    return false;
  }

  // Node. Offline devices lose their parentNodeId (mesh STA table only lists
  // currently associated clients), so node filter must pass them through —
  // otherwise Status=All + Node=X would silently drop every offline device.
  if (filter.nodeId != null &&
      device.isActive &&
      device.parentNodeId != filter.nodeId) {
    return false;
  }

  // Signal. Ethernet and null-RSSI WiFi devices pass through when a specific
  // level is selected; `unknown` is the explicit opt-in bucket for null-RSSI
  // WiFi devices.
  if (filter.signal != DeviceSignalFilter.all) {
    if (filter.signal == DeviceSignalFilter.unknown) {
      if (!device.isWifi || device.signalStrength != null) return false;
    } else if (device.isWifi && device.signalStrength != null) {
      if (signalBucketOf(device.signalStrength) != filter.signal) return false;
    }
  }

  // SSID — WiFi-only dimension, Ethernet passes through.
  if (filter.ssidName != null &&
      device.isWifi &&
      device.ssidName != filter.ssidName) {
    return false;
  }

  // Band — WiFi-only dimension, Ethernet passes through.
  if (filter.band != null && device.isWifi && device.band != filter.band) {
    return false;
  }

  // Search query — match hostname, MAC, or IP (case-insensitive).
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    final matchesHostName = device.hostName.toLowerCase().contains(q);
    final matchesMac = device.mac.toLowerCase().contains(q);
    final matchesIp = device.ip.toLowerCase().contains(q);
    if (!matchesHostName && !matchesMac && !matchesIp) return false;
  }

  return true;
}
