import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI-friendly representation of backhaul information
///
/// Replaces BackHaulInfoData (JNAP model) in State/Provider layers.
/// Per constitution Article V Section 5.3.1 - separate models per layer.
class BackhaulInfoUIModel extends Equatable {
  final String deviceUUID;
  final String connectionType;
  final String timestamp;

  const BackhaulInfoUIModel({
    required this.deviceUUID,
    required this.connectionType,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [deviceUUID, connectionType, timestamp];

  Map<String, dynamic> toMap() => {
        'deviceUUID': deviceUUID,
        'connectionType': connectionType,
        'timestamp': timestamp,
      };

  factory BackhaulInfoUIModel.fromMap(Map<String, dynamic> map) =>
      BackhaulInfoUIModel(
        deviceUUID: map['deviceUUID'] ?? '',
        connectionType: map['connectionType'] ?? '',
        timestamp: map['timestamp'] ?? '',
      );

  String toJson() => json.encode(toMap());

  factory BackhaulInfoUIModel.fromJson(String source) =>
      BackhaulInfoUIModel.fromMap(json.decode(source));
}
