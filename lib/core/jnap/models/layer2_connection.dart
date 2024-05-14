// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/wirless_connection.dart';

class Layer2Connection extends Equatable {
  final String macAddress;
  final int negotiatedMbps;
  final WirelessConnection? wireless;

  const Layer2Connection({
    required this.macAddress,
    required this.negotiatedMbps,
    required this.wireless,
  });

  Layer2Connection copyWith({
    String? macAddress,
    int? negotiatedMbps,
    WirelessConnection? wireless,
  }) {
    return Layer2Connection(
      macAddress: macAddress ?? this.macAddress,
      negotiatedMbps: negotiatedMbps ?? this.negotiatedMbps,
      wireless: wireless ?? this.wireless,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'macAddress': macAddress,
      'negotiatedMbps': negotiatedMbps,
      'wireless': wireless?.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory Layer2Connection.fromMap(Map<String, dynamic> map) {
    return Layer2Connection(
      macAddress: map['macAddress'] as String,
      negotiatedMbps: map['negotiatedMbps'],
      wireless: map['wireless'] != null
          ? WirelessConnection.fromMap(map['wireless'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Layer2Connection.fromJson(String source) =>
      Layer2Connection.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [macAddress, negotiatedMbps, wireless];
}

class NodeWirelessLayer2Connections extends Layer2Connection {
  final String timestamp;

  const NodeWirelessLayer2Connections({
    required super.macAddress,
    required super.negotiatedMbps,
    required this.timestamp,
    required super.wireless,
  });

  @override
  NodeWirelessLayer2Connections copyWith({
    String? macAddress,
    int? negotiatedMbps,
    String? timestamp,
    WirelessConnection? wireless,
  }) {
    return NodeWirelessLayer2Connections(
      macAddress: macAddress ?? this.macAddress,
      negotiatedMbps: negotiatedMbps ?? this.negotiatedMbps,
      timestamp: timestamp ?? this.timestamp,
      wireless: wireless ?? this.wireless,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'macAddress': macAddress,
      'negotiatedMbps': negotiatedMbps,
      'timestamp': timestamp,
      'wireless': wireless?.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory NodeWirelessLayer2Connections.fromMap(Map<String, dynamic> map) {
    return NodeWirelessLayer2Connections(
      macAddress: map['macAddress'] as String,
      negotiatedMbps: map['negotiatedMbps'],
      timestamp: map['timestamp'] as String,
      wireless:
          WirelessConnection.fromMap(map['wireless'] as Map<String, dynamic>),
    );
  }
  @override
  String toJson() => json.encode(toMap());

  factory NodeWirelessLayer2Connections.fromJson(String source) =>
      NodeWirelessLayer2Connections.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [macAddress, negotiatedMbps, timestamp, wireless];
}
