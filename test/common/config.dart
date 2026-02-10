import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/util/extensions.dart';

import 'screen.dart';
import 'theme_config.dart';

final responsiveAllScreens = [
  ...responsiveMobileScreens,
  ...responsiveDesktopScreens,
];
final responsiveMobileScreens = [
  // device320w,
  device480w,
];
final responsiveDesktopScreens = [
  device744w,
  device1080w,
  device1280w,
  device1440w,
];

final responsiveAllVariants = ValueVariant<ScreenSize>({
  ...responsiveMobileVariants.values,
  ...responsiveDesktopVariants.values,
});
final responsiveMobileVariants = ValueVariant<ScreenSize>({
  // device320w,
  device480w,
});
final responsiveDesktopVariants = ValueVariant<ScreenSize>({
  device744w,
  device1080w,
  device1280w,
  device1440w,
});

// const device320w = ScreenSize('Device320w', 320, 568, 1);
const device480w = ScreenSize('Device480w', 480, 932, 1);
const device744w = ScreenSize('Device744w', 744, 1133, 1);
const device1080w = ScreenSize('Device1080w', 1080, 720, 1);
const device1280w = ScreenSize('Device1280w', 1280, 720, 1);
const device1440w = ScreenSize('Device1440w', 1440, 900, 1);

bool _screenConfigured = false;
bool get hasScreenConfig => _screenConfigured;

List<ScreenSize> get targetScreens {
  const value = String.fromEnvironment('screens', defaultValue: 'all');
  if (value == 'all') {
    _screenConfigured = false;
    return responsiveAllScreens;
  } else {
    try {
      _screenConfigured = true;
      return value
          .split(',')
          .map((e) => switch (e) {
                // 'd320' || '320' => device320w,
                'd480' || '480' => device480w,
                'd744' || '744' => device744w,
                'd1080' || '1080' => device1080w,
                'd1280' || '1280' => device1280w,
                'd1440' || '1440' => device1440w,
                _ => device1440w
              })
          .toList()
          .unique((screen) => screen.name);
    } catch (e) {
      _screenConfigured = false;
      return responsiveAllScreens;
    }
  }
}

bool _localeConfigured = false;
bool get hasLocaleConfig => _localeConfigured;

List<Locale> get targetLocales {
  const value = String.fromEnvironment('locales', defaultValue: 'en');
  const allLocales = AppLocalizations.supportedLocales;
  if (value == 'all') {
    _localeConfigured = false;
    return allLocales;
  } else {
    try {
      _localeConfigured = true;
      return value
          .split(',')
          .map((e) => allLocales
              .firstWhereOrNull((locale) => locale.toLanguageTag() == e.trim()))
          .nonNulls
          .toList();
    } catch (e) {
      _localeConfigured = false;
      return allLocales;
    }
  }
}

bool _themeConfigured = false;
bool get hasThemeConfig => _themeConfigured;

/// Parse themes from dart-define parameter.
///
/// Supported formats:
/// - Single theme: "glass-light"
/// - Multiple themes: "glass-light,brutal-dark"
/// - Style only (defaults to light): "glass,brutal"
/// - All themes: "all"
List<ThemeVariant> get targetThemes {
  const value = String.fromEnvironment('themes', defaultValue: 'glass-light');
  if (value == 'all') {
    _themeConfigured = false;
    return allThemeVariants;
  } else {
    try {
      _themeConfigured = true;
      return value
          .split(',')
          .map((e) {
            final trimmed = e.trim();
            final parts = trimmed.split('-');
            final styleName = parts[0];
            final brightnessName = parts.length > 1 ? parts[1] : 'light';

            final style = ThemeStyle.values.firstWhereOrNull(
              (s) => s.name == styleName,
            );
            if (style == null) return null;

            final brightness =
                brightnessName == 'dark' ? Brightness.dark : Brightness.light;

            return ThemeVariant(style: style, brightness: brightness);
          })
          .nonNulls
          .toList()
          .unique();
    } catch (e) {
      _themeConfigured = false;
      return [defaultThemeVariant];
    }
  }
}
