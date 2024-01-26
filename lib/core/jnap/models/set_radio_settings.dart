// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/radio_info.dart';

class SetRadioSettings extends Equatable {
  final List<NewRadioSettings> radios;

  const SetRadioSettings({
    required this.radios,
  });

  SetRadioSettings copyWith({
    List<NewRadioSettings>? radios,
  }) {
    return SetRadioSettings(
      radios: radios ?? this.radios,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radios': radios.map((x) => x.toMap()).toList(),
    };
  }

  factory SetRadioSettings.fromMap(Map<String, dynamic> map) {
    return SetRadioSettings(
      radios: List<NewRadioSettings>.from(
        (map['radios'] as List<dynamic>).map<NewRadioSettings>(
          (x) => NewRadioSettings.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SetRadioSettings.fromJson(String source) =>
      SetRadioSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [radios];
}

class NewRadioSettings extends Equatable {
  final String radioID;
  final RouterRadioSettings settings;

  const NewRadioSettings({
    required this.radioID,
    required this.settings,
  });

  NewRadioSettings copyWith({
    String? radioID,
    RouterRadioSettings? settings,
  }) {
    return NewRadioSettings(
      radioID: radioID ?? this.radioID,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radioID': radioID,
      'settings': settings.toMap(),
    };
  }

  factory NewRadioSettings.fromMap(Map<String, dynamic> map) {
    return NewRadioSettings(
      radioID: map['radioID'] as String,
      settings:
          RouterRadioSettings.fromMap(map['settings'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory NewRadioSettings.fromJson(String source) =>
      NewRadioSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [radioID, settings];
}
