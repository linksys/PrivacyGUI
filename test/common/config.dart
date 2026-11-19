import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import 'screen.dart';

final responsiveAllScreens = [
  ...responsiveMobileScreens,
  ...responsiveDesktopScreens,
];
final responsiveMobileScreens = [
  // device320w,
  device480w,
  device744w,
];
final responsiveDesktopScreens = [
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
  device744w,
});
final responsiveDesktopVariants = ValueVariant<ScreenSize>({
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

/// A size the `screens` define asks for: a width, and a height when one is
/// given.
typedef RequestedScreen = ({double width, double? height});

/// The sizes the `screens` define asks for, or null for its default, `all`.
List<RequestedScreen>? get requestedScreens {
  const value = String.fromEnvironment('screens', defaultValue: 'all');
  return value == 'all' ? null : parseScreens(value);
}

final _requestedScreen = RegExp(r'^d?(\d+)(?:x(\d+))?$');

/// Parses the `screens` define: comma-separated widths, each optionally with
/// a height, as in `480,905,1280x420`. The `d480` form is accepted too.
///
/// Throws a [FormatException] on anything else, so a mistyped size fails the
/// run instead of measuring a size nobody asked for.
List<RequestedScreen> parseScreens(String value) => value.split(',').map((raw) {
      final match = _requestedScreen.firstMatch(raw.trim());
      final width = double.tryParse(match?.group(1) ?? '');
      final heightText = match?.group(2);
      final height = heightText == null ? null : double.parse(heightText);
      if (width == null || width <= 0 || (height != null && height <= 0)) {
        throw FormatException(
            'screens: "$raw" is not a width or a <width>x<height>', value);
      }
      return (width: width, height: height);
    }).toList();

/// Whether the `locales` define picked the locales. Read from the define, so it
/// does not depend on [targetLocales] having been read first.
bool get hasLocaleConfig =>
    const String.fromEnvironment('locales', defaultValue: 'all') != 'all';

List<Locale> get targetLocales {
  const value = String.fromEnvironment('locales', defaultValue: 'all');
  const allLocales = AppLocalizations.supportedLocales;
  if (value == 'all') {
    return allLocales;
  } else {
    try {
      return value
          .split(',')
          .map((e) => allLocales
              .firstWhereOrNull((locale) => locale.toLanguageTag() == e.trim()))
          .whereNotNull()
          .toList();
    } catch (e) {
      return allLocales;
    }
  }
}
