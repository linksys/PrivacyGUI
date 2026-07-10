import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';

DeviceSignalLevel signalLevelOf(int rssi) {
  return switch (getWifiSignalLevel(rssi)) {
    NodeSignalLevel.excellent => DeviceSignalLevel.excellent,
    NodeSignalLevel.good => DeviceSignalLevel.good,
    NodeSignalLevel.fair => DeviceSignalLevel.fair,
    NodeSignalLevel.poor || NodeSignalLevel.none => DeviceSignalLevel.poor,
    NodeSignalLevel.wired => DeviceSignalLevel.poor,
  };
}

NodeSignalLevel? nodeLevelOf(DeviceSignalLevel level) {
  return switch (level) {
    DeviceSignalLevel.excellent => NodeSignalLevel.excellent,
    DeviceSignalLevel.good => NodeSignalLevel.good,
    DeviceSignalLevel.fair => NodeSignalLevel.fair,
    DeviceSignalLevel.poor => NodeSignalLevel.poor,
  };
}

final deviceFilterConfigProvider =
    StateNotifierProvider<DeviceFilterNotifier, DeviceFilterConfig>((ref) {
  return DeviceFilterNotifier(ref);
});

class DeviceFilterNotifier extends StateNotifier<DeviceFilterConfig> {
  DeviceFilterNotifier(this._ref) : super(const DeviceFilterConfig()) {
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

  void setStatus(DeviceStatusFilter value) {
    if (value == DeviceStatusFilter.offline) {
      state = state.copyWith(
        status: value,
        connections: const {},
        signals: const {},
        includeUnknownSignal: false,
        nodeIds: () => const {},
        ssidNames: () => const {},
        bands: () => const {},
      );
      return;
    }
    state = state.copyWith(status: value);
  }

  void setConnections(Set<ConnectionType> values) {
    final isEthernetOnly =
        values.length == 1 && values.contains(ConnectionType.wired);
    if (isEthernetOnly) {
      state = state.copyWith(
        connections: values,
        signals: const {},
        includeUnknownSignal: false,
        ssidNames: () => const {},
        bands: () => const {},
      );
      return;
    }
    state = state.copyWith(connections: values);
  }

  void toggleConnection(ConnectionType type) {
    var next = Set<ConnectionType>.from(state.connections);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    setConnections(next);
  }

  void setSignals(Set<DeviceSignalLevel> values) {
    state = state.copyWith(signals: values);
  }

  void toggleSignal(DeviceSignalLevel level) {
    var next = Set<DeviceSignalLevel>.from(state.signals);
    if (next.contains(level)) {
      next.remove(level);
    } else {
      next.add(level);
    }
    state = state.copyWith(signals: next);
  }

  void setIncludeUnknownSignal(bool value) {
    state = state.copyWith(includeUnknownSignal: value);
  }

  void setNodeIds(Set<String> values) {
    state = state.copyWith(nodeIds: () => values);
  }

  void toggleNodeId(String nodeId) {
    var next = Set<String>.from(state.nodeIds);
    if (next.contains(nodeId)) {
      next.remove(nodeId);
    } else {
      next.add(nodeId);
    }
    state = state.copyWith(nodeIds: () => next);
  }

  void setSsidNames(Set<String> values) {
    state = state.copyWith(ssidNames: () => values);
  }

  void toggleSsidName(String ssid) {
    var next = Set<String>.from(state.ssidNames);
    if (next.contains(ssid)) {
      next.remove(ssid);
    } else {
      next.add(ssid);
    }
    state = state.copyWith(ssidNames: () => next);
  }

  void setBands(Set<String> values) {
    state = state.copyWith(bands: () => values);
  }

  void toggleBand(String band) {
    var next = Set<String>.from(state.bands);
    if (next.contains(band)) {
      next.remove(band);
    } else {
      next.add(band);
    }
    state = state.copyWith(bands: () => next);
  }

  void setDeviceCategories(Set<DeviceCategory> values) {
    state = state.copyWith(deviceCategories: values);
  }

  void toggleDeviceCategory(DeviceCategory category) {
    var next = Set<DeviceCategory>.from(state.deviceCategories);
    if (next.contains(category)) {
      next.remove(category);
    } else {
      next.add(category);
    }
    state = state.copyWith(deviceCategories: next);
  }

  void setPrivateMac(PrivateMacFilter value) {
    state = state.copyWith(privateMac: value);
  }

  void clearAll() {
    state = state.copyWith(
      searchQuery: '',
      status: DeviceStatusFilter.all,
      connections: const {},
      deviceCategories: const {},
      privateMac: PrivateMacFilter.all,
      signals: const {},
      includeUnknownSignal: false,
      nodeIds: () => const {},
      ssidNames: () => const {},
      bands: () => const {},
    );
  }

  void _reconcile(DeviceFilterOptions options) {
    var next = state;

    if (next.nodeIds.isNotEmpty) {
      final validNodeIds = options.nodes.map((n) => n.deviceId).toSet();
      final filtered = next.nodeIds.intersection(validNodeIds);
      if (filtered.length != next.nodeIds.length) {
        next = next.copyWith(nodeIds: () => filtered);
      }
    }

    if (next.ssidNames.isNotEmpty) {
      final validSsids = options.ssids.toSet();
      final filtered = next.ssidNames.intersection(validSsids);
      if (filtered.length != next.ssidNames.length) {
        next = next.copyWith(ssidNames: () => filtered);
      }
    }

    if (next.bands.isNotEmpty) {
      final validBands = options.bands.toSet();
      final filtered = next.bands.intersection(validBands);
      if (filtered.length != next.bands.length) {
        next = next.copyWith(bands: () => filtered);
      }
    }

    if (next.includeUnknownSignal && !options.hasUnknownSignalDevices) {
      next = next.copyWith(includeUnknownSignal: false);
    }

    if (next.deviceCategories.isNotEmpty) {
      final validCategories = options.deviceCategories.toSet();
      final filtered = next.deviceCategories.intersection(validCategories);
      if (filtered.length != next.deviceCategories.length) {
        next = next.copyWith(deviceCategories: filtered);
      }
    }

    if (next != state) state = next;
  }
}

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
    deviceCategories: devices
        .map((d) => DeviceClassifier.classify(hostname: d.hostName, mac: d.mac))
        .toSet()
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index)),
    hasUnknownSignalDevices:
        devices.any((d) => d.isWifi && d.signalStrength == null),
  );
});

/// Filtered device list — applies every active dimension + search.
final filteredDeviceListProvider = Provider<List<ClientDevice>>((ref) {
  final data = ref.watch(devicesDataProvider).valueOrNull;
  if (data == null) return [];
  final filter = ref.watch(deviceFilterConfigProvider);
  return data.clientDevices.where((d) => _matches(d, filter)).toList();
});

bool _matches(ClientDevice device, DeviceFilterConfig filter) {
  // Status.
  if (filter.status == DeviceStatusFilter.online && !device.isActive) {
    return false;
  }
  if (filter.status == DeviceStatusFilter.offline && device.isActive) {
    return false;
  }

  // Connection type (multi-select OR)
  if (filter.connections.isNotEmpty) {
    final deviceType =
        device.isWifi ? ConnectionType.wifi : ConnectionType.wired;
    if (!filter.connections.contains(deviceType)) {
      return false;
    }
  }

  // BUG FIX: Exclude Ethernet when WiFi-specific filters are active
  if (filter.hasWifiOnlyFilter && !device.isWifi) {
    if (!filter.connections.contains(ConnectionType.wired)) {
      return false;
    }
  }

  // Device category (multi-select OR)
  if (filter.deviceCategories.isNotEmpty) {
    final category =
        DeviceClassifier.classify(hostname: device.hostName, mac: device.mac);
    if (!filter.deviceCategories.contains(category)) {
      return false;
    }
  }

  // Private MAC filter
  if (filter.privateMac != PrivateMacFilter.all) {
    final isPrivate = OuiLookup.isRandomizedMac(device.mac);
    if (filter.privateMac == PrivateMacFilter.privateOnly && !isPrivate) {
      return false;
    }
    if (filter.privateMac == PrivateMacFilter.publicOnly && isPrivate) {
      return false;
    }
  }

  // Node (multi-select OR). Offline devices pass through.
  if (filter.nodeIds.isNotEmpty && device.isActive) {
    if (device.parentNodeId == null ||
        !filter.nodeIds.contains(device.parentNodeId)) {
      return false;
    }
  }

  // Signal (multi-select OR + unknown toggle)
  if (filter.signals.isNotEmpty || filter.includeUnknownSignal) {
    if (device.isWifi) {
      if (device.signalStrength == null) {
        if (!filter.includeUnknownSignal) return false;
      } else {
        // Device has known signal strength
        if (filter.signals.isEmpty) {
          // Only unknown signals requested, exclude devices with known signal
          return false;
        }
        if (!filter.signals.contains(signalLevelOf(device.signalStrength!))) {
          return false;
        }
      }
    }
  }

  // SSID (multi-select OR)
  if (filter.ssidNames.isNotEmpty && device.isWifi) {
    if (device.ssidName == null ||
        !filter.ssidNames.contains(device.ssidName)) {
      return false;
    }
  }

  // Band (multi-select OR)
  if (filter.bands.isNotEmpty && device.isWifi) {
    if (device.band == null || !filter.bands.contains(device.band)) {
      return false;
    }
  }

  // Search query
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    final matchesHostName = device.hostName.toLowerCase().contains(q);
    final matchesMac = device.mac.toLowerCase().contains(q);
    final matchesIp = device.ip.toLowerCase().contains(q);
    if (!matchesHostName && !matchesMac && !matchesIp) return false;
  }

  return true;
}
