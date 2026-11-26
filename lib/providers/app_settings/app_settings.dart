// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/util/extensions.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final Locale? locale;
  final Color? themeColor;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.themeColor,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    ValueGetter<Locale?>? locale,
    ValueGetter<Color?>? themeColor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale != null ? locale() : this.locale,
      themeColor: themeColor != null ? themeColor() : this.themeColor,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'themeMode': themeMode.name,
      'locale': locale?.toLanguageTag(),
      'themeColor': themeColor?.value,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
