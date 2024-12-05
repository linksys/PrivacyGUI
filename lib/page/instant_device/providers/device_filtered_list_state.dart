// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class DeviceFilterConfigState extends Equatable {
  final bool connectionFilter;
  final List<String> nodeFilter;
  final List<String> wifiFilter;
  final List<String> bandFilter;

  const DeviceFilterConfigState({
    required this.connectionFilter,
    required this.nodeFilter,
    required this.wifiFilter,
    required this.bandFilter,
  });

  DeviceFilterConfigState copyWith({
    bool? connectionFilter,
    List<String>? nodeFilter,
    List<String>? wifiFilter,
    List<String>? bandFilter,
  }) {
    return DeviceFilterConfigState(
      connectionFilter: connectionFilter ?? this.connectionFilter,
      nodeFilter: nodeFilter ?? this.nodeFilter,
      wifiFilter: wifiFilter ?? this.wifiFilter,
      bandFilter: bandFilter ?? this.bandFilter,
    );
  }

  @override
  List<Object> get props => [
        connectionFilter,
        nodeFilter,
        wifiFilter,
        bandFilter,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'connectionFilter': connectionFilter,
      'nodeFilter': nodeFilter,
      'wifiFilter': wifiFilter,
      'bandFilter': bandFilter,
    };
  }

  factory DeviceFilterConfigState.fromMap(Map<String, dynamic> map) {
    return DeviceFilterConfigState(
      connectionFilter: map['connectionFilter'] as bool,
      nodeFilter:
          map['nodeFilter'] == null ? [] : List<String>.from(map['nodeFilter']),
      wifiFilter:
          map['wifiFilter'] == null ? [] : List<String>.from(map['wifiFilter']),
      bandFilter:
          map['bandFilter'] == null ? [] : List<String>.from(map['bandFilter']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceFilterConfigState.fromJson(String source) =>
      DeviceFilterConfigState.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
