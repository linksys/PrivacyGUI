import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_status.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

enum DMZSourceType {
  auto,
  range,
  ;

  static DMZSourceType resolve(String value) =>
      values.firstWhere((element) => element.name == value);
}

enum DMZDestinationType {
  ip,
  mac,
  ;

  static DMZDestinationType resolve(String value) =>
      values.firstWhere((element) => element.name == value);
}

/// UI-specific model for DMZ source IP restriction.
///
/// This is the Application layer's view of source restrictions, separate
/// from the Data layer's [DMZSourceRestriction] model. This ensures the
/// Provider layer only knows about UI models, not JNAP data models.
class DMZSourceRestrictionUI extends Equatable {
  final String firstIPAddress;
  final String lastIPAddress;

  const DMZSourceRestrictionUI({
    required this.firstIPAddress,
    required this.lastIPAddress,
  });

  @override
  List<Object> get props => [firstIPAddress, lastIPAddress];

  DMZSourceRestrictionUI copyWith({
    String? firstIPAddress,
    String? lastIPAddress,
  }) {
    return DMZSourceRestrictionUI(
      firstIPAddress: firstIPAddress ?? this.firstIPAddress,
      lastIPAddress: lastIPAddress ?? this.lastIPAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstIPAddress': firstIPAddress,
      'lastIPAddress': lastIPAddress,
    };
  }

  factory DMZSourceRestrictionUI.fromMap(Map<String, dynamic> map) {
    return DMZSourceRestrictionUI(
      firstIPAddress: map['firstIPAddress'] as String,
      lastIPAddress: (map['lastIPAddress'] ?? map['firstIPAddress']) as String,
    );
  }
}

class DMZUISettings extends Equatable {
  final bool isDMZEnabled;
  final DMZSourceRestrictionUI? sourceRestriction;
  final String? destinationIPAddress;
  final String? destinationMACAddress;
  final DMZSourceType sourceType;
  final DMZDestinationType destinationType;

  const DMZUISettings({
    required this.isDMZEnabled,
    this.sourceRestriction,
    this.destinationIPAddress,
    this.destinationMACAddress,
    required this.sourceType,
    required this.destinationType,
  });

  @override
  List<Object?> get props => [
        isDMZEnabled,
        sourceRestriction,
        destinationIPAddress,
        destinationMACAddress,
        sourceType,
        destinationType,
      ];

  DMZUISettings copyWith({
    bool? isDMZEnabled,
    ValueGetter<DMZSourceRestrictionUI?>? sourceRestriction,
    ValueGetter<String?>? destinationIPAddress,
    ValueGetter<String?>? destinationMACAddress,
    DMZSourceType? sourceType,
    DMZDestinationType? destinationType,
  }) {
    return DMZUISettings(
      isDMZEnabled: isDMZEnabled ?? this.isDMZEnabled,
      sourceRestriction: sourceRestriction != null
          ? sourceRestriction()
          : this.sourceRestriction,
      destinationIPAddress: destinationIPAddress != null
          ? destinationIPAddress()
          : this.destinationIPAddress,
      destinationMACAddress: destinationMACAddress != null
          ? destinationMACAddress()
          : this.destinationMACAddress,
      sourceType: sourceType ?? this.sourceType,
      destinationType: destinationType ?? this.destinationType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDMZEnabled': isDMZEnabled,
      'sourceRestriction': sourceRestriction?.toMap(),
      'destinationIPAddress': destinationIPAddress,
      'destinationMACAddress': destinationMACAddress,
      'sourceType': sourceType.name,
      'destinationType': destinationType.name,
    };
  }

  factory DMZUISettings.fromMap(Map<String, dynamic> map) {
    return DMZUISettings(
      isDMZEnabled: map['isDMZEnabled'] as bool,
      sourceRestriction: map['sourceRestriction'] != null
          ? DMZSourceRestrictionUI.fromMap(
              map['sourceRestriction'] as Map<String, dynamic>)
          : null,
      destinationIPAddress: map['destinationIPAddress'] as String?,
      destinationMACAddress: map['destinationMACAddress'] as String?,
      sourceType: DMZSourceType.resolve(map['sourceType'] ?? 'auto'),
      destinationType:
          DMZDestinationType.resolve(map['destinationType'] ?? 'ip'),
    );
  }
}

class DMZSettingsState extends FeatureState<DMZUISettings, DMZStatus> {
  const DMZSettingsState({
    required super.settings,
    required super.status,
  });

  @override
  DMZSettingsState copyWith({
    Preservable<DMZUISettings>? settings,
    DMZStatus? status,
  }) {
    return DMZSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap((value) => value.toMap()),
      'status': status.toMap(),
    };
  }

  factory DMZSettingsState.fromMap(Map<String, dynamic> map) {
    return DMZSettingsState(
      settings: Preservable<DMZUISettings>.fromMap(map['settings'],
          (m) => DMZUISettings.fromMap(m as Map<String, dynamic>)),
      status: DMZStatus.fromMap(map['status']),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory DMZSettingsState.fromJson(String source) =>
      DMZSettingsState.fromMap(json.decode(source));

  @override
  List<Object> get props => [settings, status];
}
