// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:privacy_gui/providers/app_settings/temperature_unit.dart';
import 'package:privacy_gui/util/extensions.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final Locale? locale;
  final Color? themeColor;
  final bool showMascot;

  /// The unit the user picked by tapping a temperature (#1926), or null to
  /// follow the browser's region (`temperatureUnitProvider`).
  final TemperatureUnit? temperatureUnit;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.themeColor,
    this.showMascot = true,
    this.temperatureUnit,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    ValueGetter<Locale?>? locale,
    ValueGetter<Color?>? themeColor,
    bool? showMascot,
    ValueGetter<TemperatureUnit?>? temperatureUnit,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale != null ? locale() : this.locale,
      themeColor: themeColor != null ? themeColor() : this.themeColor,
      showMascot: showMascot ?? this.showMascot,
      temperatureUnit:
          temperatureUnit != null ? temperatureUnit() : this.temperatureUnit,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, showMascot, temperatureUnit];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'themeMode': themeMode.name,
      'locale': locale?.toLanguageTag(),
      'themeColor': themeColor?.toARGB32(),
      'showMascot': showMascot,
      'temperatureUnit': temperatureUnit?.name,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhereOrNull(
              (element) => element.name == map['themeMode']) ??
          ThemeMode.system,
      locale: map['locale'] != null
          ? LocaleExt.fromLanguageTag(map['locale'])
          : null,
      themeColor: map['themeColor'] != null ? Color(map['themeColor']) : null,
      showMascot: map['showMascot'] ?? true,
      temperatureUnit: TemperatureUnit.values
          .firstWhereOrNull((unit) => unit.name == map['temperatureUnit']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
