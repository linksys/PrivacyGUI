// AppSettings: the theme mode, language and theme color the app keeps in
// SharedPreferences between launches, as JSON.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';

void main() {
  test('starts in the system theme, with no language or color of its own', () {
    const settings = AppSettings();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.locale, isNull);
    expect(settings.themeColor, isNull);
  });

  test('reads what it saved', () {
    final settings = AppSettings.fromJson(
        '{"themeMode":"dark","locale":"zh-TW","themeColor":4294198070}');

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.locale, const Locale('zh', 'TW'));
    expect(settings.themeColor, const Color(0xFFF44336));
  });

  test('saves the theme mode by name, the language by tag, the color by value',
      () {
    const settings = AppSettings(
      themeMode: ThemeMode.light,
      locale: Locale('fr', 'CA'),
      themeColor: Color(0xFF673AB7),
    );

    expect(settings.toMap(), {
      'themeMode': 'light',
      'locale': 'fr-CA',
      'themeColor': 0xFF673AB7,
    });
    expect(settings.toJson(),
        '{"themeMode":"light","locale":"fr-CA","themeColor":4284955319}');
  });

  test('reads a theme mode it does not know, and no language, as the defaults',
      () {
    final settings =
        AppSettings.fromMap(const {'themeMode': 'sepia', 'locale': null});

    expect(settings, const AppSettings());
  });

  group('copyWith', () {
    const saved = AppSettings(
      themeMode: ThemeMode.dark,
      locale: Locale('de'),
      themeColor: Color(0xFFFFC107),
    );

    test('keeps what it is not given', () {
      final copy = saved.copyWith();

      expect(copy.themeMode, ThemeMode.dark);
      expect(copy.locale, const Locale('de'));
      expect(copy.themeColor, const Color(0xFFFFC107));
    });

    test('sets the language back to the system\'s, and clears the color', () {
      final copy = saved.copyWith(
        themeMode: ThemeMode.system,
        locale: () => null,
        themeColor: () => null,
      );

      expect(copy.themeMode, ThemeMode.system);
      expect(copy.locale, isNull);
      expect(copy.themeColor, isNull);
    });
  });

  test('settings with another theme mode or language are not equal', () {
    const settings = AppSettings(themeMode: ThemeMode.dark, locale: Locale('de'));

    expect(settings,
        const AppSettings(themeMode: ThemeMode.dark, locale: Locale('de')));
    expect(settings, isNot(const AppSettings(locale: Locale('de'))));
    expect(settings, isNot(const AppSettings(themeMode: ThemeMode.dark)));
  });
}
