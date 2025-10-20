// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/dmz_settings.dart' as model;
import 'package:privacy_gui/providers/feature_state.dart';

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

class DMZSettings extends Equatable {
  final model.DMZSettings settings;
  final DMZSourceType sourceType;
  final DMZDestinationType destinationType;
  const DMZSettings({
    required this.settings,
    required this.sourceType,
    required this.destinationType,
  });

  @override
  List<Object> get props => [settings, sourceType, destinationType];

  DMZSettings copyWith({
    model.DMZSettings? settings,
    DMZSourceType? sourceType,
    DMZDestinationType? destinationType,
  }) {
    return DMZSettings(
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
}

class DMZStatus extends Equatable {
  const DMZStatus();

  @override
  List<Object> get props => [];

  Map<String, dynamic> toMap() {
    return {};
  }
}

class DMZSettingsState extends FeatureState<DMZSettings, DMZStatus> {
  const DMZSettingsState({
    required super.settings,
    required super.status,
  });

  @override
  DMZSettingsState copyWith({
    DMZSettings? settings,
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
      'settings': settings.toMap(),
      'status': status.toMap(),
    };
  }
}
