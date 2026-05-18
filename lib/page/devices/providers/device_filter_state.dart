import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

enum DeviceStatusFilter { all, online, offline }

enum DeviceConnectionFilter { all, wifi, ethernet }

/// Signal-quality buckets, thresholds aligned with `DeviceUIModel.signalLevel`.
/// `unknown` exists so that WiFi devices without RSSI data (rare firmware
/// state) can still be addressed explicitly, matching the `--` picker option
/// surfaced in the UI only when such devices are present.
enum DeviceSignalFilter { all, excellent, good, fair, poor, unknown }

/// User-selected filter configuration for the device list.
class DeviceFilterConfig extends Equatable {
  final String searchQuery;
  final DeviceStatusFilter status;
  final DeviceConnectionFilter connection;
  final DeviceSignalFilter signal;
  final String? nodeId;
  final String? ssidName;
  final String? band;

  const DeviceFilterConfig({
    this.searchQuery = '',
    this.status = DeviceStatusFilter.all,
    this.connection = DeviceConnectionFilter.all,
    this.signal = DeviceSignalFilter.all,
    this.nodeId,
    this.ssidName,
    this.band,
  });

  /// Count of active filter dimensions (excluding search).
  int get activeCount {
    var count = 0;
    if (status != DeviceStatusFilter.all) count++;
    if (connection != DeviceConnectionFilter.all) count++;
    if (signal != DeviceSignalFilter.all) count++;
    if (nodeId != null) count++;
    if (ssidName != null) count++;
    if (band != null) count++;
    return count;
  }

  /// Count of active filter dimensions excluding status (for filter panel badge).
  /// Status is displayed separately above the list, so the panel badge should
  /// only reflect the "additional" filters.
  int get activeCountExcludingStatus {
    var count = 0;
    if (connection != DeviceConnectionFilter.all) count++;
    if (signal != DeviceSignalFilter.all) count++;
    if (nodeId != null) count++;
    if (ssidName != null) count++;
    if (band != null) count++;
    return count;
  }

  bool get isActive => activeCount > 0 || searchQuery.isNotEmpty;

  DeviceFilterConfig copyWith({
    String? searchQuery,
    DeviceStatusFilter? status,
    DeviceConnectionFilter? connection,
    DeviceSignalFilter? signal,
    String? Function()? nodeId,
    String? Function()? ssidName,
    String? Function()? band,
  }) {
    return DeviceFilterConfig(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
      connection: connection ?? this.connection,
      signal: signal ?? this.signal,
      nodeId: nodeId != null ? nodeId() : this.nodeId,
      ssidName: ssidName != null ? ssidName() : this.ssidName,
      band: band != null ? band() : this.band,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        status,
        connection,
        signal,
        nodeId,
        ssidName,
        band,
      ];
}

/// Available filter options derived from current dashboard data.
class DeviceFilterOptions extends Equatable {
  final List<NodeUIModel> nodes;
  final List<String> ssids;
  final List<String> bands;

  /// True when at least one WiFi device in the current list has no RSSI.
  /// Controls whether the `--` (unknown) signal option is offered.
  final bool hasUnknownSignalDevices;

  const DeviceFilterOptions({
    this.nodes = const [],
    this.ssids = const [],
    this.bands = const [],
    this.hasUnknownSignalDevices = false,
  });

  @override
  List<Object?> get props => [nodes, ssids, bands, hasUnknownSignalDevices];
}
