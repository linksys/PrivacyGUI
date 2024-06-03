// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';

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

class DMZSettingsState extends Equatable {
  final DMZSettings settings;
  final DMZSourceType sourceType;
  final DMZDestinationType destinationType;
  const DMZSettingsState({
    required this.settings,
    required this.sourceType,
    required this.destinationType,
  });

  DMZSettingsState copyWith({
    DMZSettings? settings,
    DMZSourceType? sourceType,
    DMZDestinationType? destinationType,
  }) {
    return DMZSettingsState(
      settings: settings ?? this.settings,
      sourceType: sourceType ?? this.sourceType,
      destinationType: destinationType ?? this.destinationType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap(),
      'sourceType': sourceType.name,
      'destinationType': destinationType.name,
    };
  }

  factory DMZSettingsState.fromMap(Map<String, dynamic> map) {
    return DMZSettingsState(
      settings: DMZSettings.fromMap(map['settings'] as Map<String, dynamic>),
      sourceType: DMZSourceType.resolve(map['sourceType']),
      destinationType: DMZDestinationType.resolve(map['destinationType']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DMZSettingsState.fromJson(String source) =>
      DMZSettingsState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, sourceType, destinationType];
}
