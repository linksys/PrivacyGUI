import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';

enum DeviceStatusFilter { all, online, offline }

enum DeviceSignalLevel { excellent, good, fair, poor }

enum PrivateMacFilter { all, privateOnly, publicOnly }

class DeviceFilterConfig extends Equatable {
  final String searchQuery;
  final DeviceStatusFilter status;
  final Set<ConnectionType> connections;
  final Set<DeviceCategory> deviceCategories;
  final PrivateMacFilter privateMac;
  final Set<DeviceSignalLevel> signals;
  final bool includeUnknownSignal;
  final Set<String> nodeIds;
  final Set<String> ssidNames;
  final Set<String> bands;

  const DeviceFilterConfig({
    this.searchQuery = '',
    this.status = DeviceStatusFilter.all,
    this.connections = const {},
    this.deviceCategories = const {},
    this.privateMac = PrivateMacFilter.all,
    this.signals = const {},
    this.includeUnknownSignal = false,
    this.nodeIds = const {},
    this.ssidNames = const {},
    this.bands = const {},
  });

  int get activeCount {
    var count = 0;
    if (status != DeviceStatusFilter.all) count++;
    if (connections.isNotEmpty) count++;
    if (deviceCategories.isNotEmpty) count++;
    if (privateMac != PrivateMacFilter.all) count++;
    if (signals.isNotEmpty || includeUnknownSignal) count++;
    if (nodeIds.isNotEmpty) count++;
    if (ssidNames.isNotEmpty) count++;
    if (bands.isNotEmpty) count++;
    return count;
  }

  int get activeCountExcludingStatus {
    var count = 0;
    if (connections.isNotEmpty) count++;
    if (deviceCategories.isNotEmpty) count++;
    if (privateMac != PrivateMacFilter.all) count++;
    if (signals.isNotEmpty || includeUnknownSignal) count++;
    if (nodeIds.isNotEmpty) count++;
    if (ssidNames.isNotEmpty) count++;
    if (bands.isNotEmpty) count++;
    return count;
  }

  bool get isActive => activeCount > 0 || searchQuery.isNotEmpty;

  bool get hasWifiOnlyFilter =>
      signals.isNotEmpty ||
      includeUnknownSignal ||
      ssidNames.isNotEmpty ||
      bands.isNotEmpty;

  bool get isEthernetOnly =>
      connections.length == 1 && connections.contains(ConnectionType.wired);

  DeviceFilterConfig copyWith({
    String? searchQuery,
    DeviceStatusFilter? status,
    Set<ConnectionType>? connections,
    Set<DeviceCategory>? deviceCategories,
    PrivateMacFilter? privateMac,
    Set<DeviceSignalLevel>? signals,
    bool? includeUnknownSignal,
    Set<String> Function()? nodeIds,
    Set<String> Function()? ssidNames,
    Set<String> Function()? bands,
  }) {
    return DeviceFilterConfig(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
      connections: connections ?? this.connections,
      deviceCategories: deviceCategories ?? this.deviceCategories,
      privateMac: privateMac ?? this.privateMac,
      signals: signals ?? this.signals,
      includeUnknownSignal: includeUnknownSignal ?? this.includeUnknownSignal,
      nodeIds: nodeIds != null ? nodeIds() : this.nodeIds,
      ssidNames: ssidNames != null ? ssidNames() : this.ssidNames,
      bands: bands != null ? bands() : this.bands,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        status,
        connections,
        deviceCategories,
        privateMac,
        signals,
        includeUnknownSignal,
        nodeIds,
        ssidNames,
        bands,
      ];
}

class DeviceFilterOptions extends Equatable {
  final List<NodeEntity> nodes;
  final List<String> ssids;
  final List<String> bands;
  final List<DeviceCategory> deviceCategories;
  final bool hasUnknownSignalDevices;

  const DeviceFilterOptions({
    this.nodes = const [],
    this.ssids = const [],
    this.bands = const [],
    this.deviceCategories = const [],
    this.hasUnknownSignalDevices = false,
  });

  @override
  List<Object?> get props =>
      [nodes, ssids, bands, deviceCategories, hasUnknownSignalDevices];
}
