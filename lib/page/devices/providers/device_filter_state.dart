import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';

enum DeviceStatusFilter { all, online, offline }

/// User-selected filter configuration for the device list.
class DeviceFilterConfig extends Equatable {
  final String searchQuery;
  final DeviceStatusFilter status;
  final String? nodeId;
  final String? ssidName;
  final String? band;

  const DeviceFilterConfig({
    this.searchQuery = '',
    this.status = DeviceStatusFilter.all,
    this.nodeId,
    this.ssidName,
    this.band,
  });

  bool get isActive =>
      status != DeviceStatusFilter.all ||
      nodeId != null ||
      ssidName != null ||
      band != null ||
      searchQuery.isNotEmpty;

  DeviceFilterConfig copyWith({
    String? searchQuery,
    DeviceStatusFilter? status,
    String? Function()? nodeId,
    String? Function()? ssidName,
    String? Function()? band,
  }) {
    return DeviceFilterConfig(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
      nodeId: nodeId != null ? nodeId() : this.nodeId,
      ssidName: ssidName != null ? ssidName() : this.ssidName,
      band: band != null ? band() : this.band,
    );
  }

  @override
  List<Object?> get props => [searchQuery, status, nodeId, ssidName, band];
}

/// Available filter options derived from current dashboard data.
class DeviceFilterOptions extends Equatable {
  final List<MeshNodeInfo> nodes;
  final List<String> ssids;
  final List<String> bands;

  const DeviceFilterOptions({
    this.nodes = const [],
    this.ssids = const [],
    this.bands = const [],
  });

  @override
  List<Object?> get props => [nodes, ssids, bands];
}
