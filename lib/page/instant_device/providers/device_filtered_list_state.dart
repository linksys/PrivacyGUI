// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class DeviceFilterConfigState extends Equatable {
  final bool connectionFilter;
  final List<String> nodeFilter;
  final List<String> wifiFilter;
  final List<String> bandFilter;
  final bool showOrphanNodes;

  const DeviceFilterConfigState({
    required this.connectionFilter,
    required this.nodeFilter,
    required this.wifiFilter,
    required this.bandFilter,
     this.showOrphanNodes = false,
  });

  DeviceFilterConfigState copyWith({
    bool? connectionFilter,
    List<String>? nodeFilter,
    List<String>? wifiFilter,
    List<String>? bandFilter,
    bool? showOrphanNodes,
  }) {
    return DeviceFilterConfigState(
      connectionFilter: connectionFilter ?? this.connectionFilter,
      nodeFilter: nodeFilter ?? this.nodeFilter,
      wifiFilter: wifiFilter ?? this.wifiFilter,
      bandFilter: bandFilter ?? this.bandFilter,
      showOrphanNodes: showOrphanNodes ?? this.showOrphanNodes,
    );
  }

  @override
  List<Object> get props {
    return [
      connectionFilter,
      nodeFilter,
      wifiFilter,
      bandFilter,
      showOrphanNodes,
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'connectionFilter': connectionFilter,
      'nodeFilter': nodeFilter,
      'wifiFilter': wifiFilter,
      'bandFilter': bandFilter,
      'showOrphanNodes': showOrphanNodes,
    };
  }

  factory DeviceFilterConfigState.fromMap(Map<String, dynamic> map) {
    return DeviceFilterConfigState(
      connectionFilter: map['connectionFilter'] ?? false,
      nodeFilter: List<String>.from(map['nodeFilter']),
      wifiFilter: List<String>.from(map['wifiFilter']),
      bandFilter: List<String>.from(map['bandFilter']),
      showOrphanNodes: map['showOrphanNodes'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceFilterConfigState.fromJson(String source) => DeviceFilterConfigState.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DeviceFilterConfigState(connectionFilter: $connectionFilter, nodeFilter: $nodeFilter, wifiFilter: $wifiFilter, bandFilter: $bandFilter, showOrphanNodes: $showOrphanNodes)';
  }
}
