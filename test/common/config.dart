import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/util/extensions.dart';

import 'screen.dart';

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
