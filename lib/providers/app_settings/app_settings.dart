// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/util/extensions.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final Locale? locale;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'themeMode': themeMode.name,
      'locale': locale?.toLanguageTag(),
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
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
