// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/layer2_connection.dart';

class NodeWirelessConnections extends Equatable {
  final String deviceID;
  final List<NodeWirelessLayer2Connections> connections;
  const NodeWirelessConnections({
    required this.deviceID,
    required this.connections,
  });

  NodeWirelessConnections copyWith({
    String? deviceID,
    List<NodeWirelessLayer2Connections>? connections,
  }) {
    return NodeWirelessConnections(
      deviceID: deviceID ?? this.deviceID,
      connections: connections ?? this.connections,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceID': deviceID,
      'connections': connections.map((x) => x.toMap()).toList(),
    };
  }

  factory NodeWirelessConnections.fromMap(Map<String, dynamic> map) {
    return NodeWirelessConnections(
      deviceID: map['deviceID'] as String,
      connections: List.from(
        (map['connections']).map(
          (x) => NodeWirelessLayer2Connections.fromMap(x),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory NodeWirelessConnections.fromJson(String source) =>
      NodeWirelessConnections.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [deviceID, connections];
}
