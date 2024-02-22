// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class WifiAdvancedSettingsState extends Equatable {
  final bool? isIptvEnabled;
  final bool? isClientSteeringEnabled;
  final bool? isNodesSteeringEnabled;
  final bool? isMLOEnabled;
  final bool? isDFSEnabled;
  final bool? isAirtimeFairnessEnabled;

  const WifiAdvancedSettingsState({
    this.isIptvEnabled,
    this.isClientSteeringEnabled,
    this.isNodesSteeringEnabled,
    this.isMLOEnabled,
    this.isDFSEnabled,
    this.isAirtimeFairnessEnabled,
  });

  WifiAdvancedSettingsState copyWith({
    bool? isIptvEnabled,
    bool? isClientSteeringEnabled,
    bool? isNodesSteeringEnabled,
    bool? isMLOEnabled,
    bool? isDFSEnabled,
    bool? isAirtimeFairnessEnabled,
  }) {
    return WifiAdvancedSettingsState(
      isIptvEnabled: isIptvEnabled ?? this.isIptvEnabled,
      isClientSteeringEnabled:
          isClientSteeringEnabled ?? this.isClientSteeringEnabled,
      isNodesSteeringEnabled:
          isNodesSteeringEnabled ?? this.isNodesSteeringEnabled,
      isMLOEnabled: isMLOEnabled ?? this.isMLOEnabled,
      isDFSEnabled: isDFSEnabled ?? this.isDFSEnabled,
      isAirtimeFairnessEnabled:
          isAirtimeFairnessEnabled ?? this.isAirtimeFairnessEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isIptvEnabled': isIptvEnabled,
      'isClientSteeringEnabled': isClientSteeringEnabled,
      'isNodesSteeringEnabled': isNodesSteeringEnabled,
      'isMLOEnabled': isMLOEnabled,
      'isDFSEnabled': isDFSEnabled,
      'isAirtimeFairnessEnabled': isAirtimeFairnessEnabled,
    };
  }

  factory WifiAdvancedSettingsState.fromMap(Map<String, dynamic> map) {
    return WifiAdvancedSettingsState(
      isIptvEnabled:
          map['isIptvEnabled'] != null ? map['isIptvEnabled'] as bool : null,
      isClientSteeringEnabled: map['isClientSteeringEnabled'] != null
          ? map['isClientSteeringEnabled'] as bool
          : null,
      isNodesSteeringEnabled: map['isNodesSteeringEnabled'] != null
          ? map['isNodesSteeringEnabled'] as bool
          : null,
      isMLOEnabled:
          map['isMLOEnabled'] != null ? map['isMLOEnabled'] as bool : null,
      isDFSEnabled:
          map['isDFSEnabled'] != null ? map['isDFSEnabled'] as bool : null,
      isAirtimeFairnessEnabled: map['isAirtimeFairnessEnabled'] != null
          ? map['isAirtimeFairnessEnabled'] as bool
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WifiAdvancedSettingsState.fromJson(String source) =>
      WifiAdvancedSettingsState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      isIptvEnabled,
      isClientSteeringEnabled,
      isNodesSteeringEnabled,
      isMLOEnabled,
      isDFSEnabled,
      isAirtimeFairnessEnabled,
    ];
  }
}
