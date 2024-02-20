import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_widgets/theme/_theme.dart';

import 'font_util.dart';

final mockLightThemeData =
    linksysLightThemeData.copyWith(textTheme: mockLinksysDarkTextTheme);
final mockDarkThemeData =
    linksysDarkThemeData.copyWith(textTheme: mockLinksysLightTextTheme);

Future<void> testLocalizations(
    String name, FutureOr<void> Function(WidgetTester, Locale) testMain) async {
  return testGoldens(name, (tester) async {
    await loadTestFonts();
    for (final locale in AppLocalizations.supportedLocales) {
      await testMain(tester, locale);

      
      await screenMatchesGolden(
        tester,
        '$name-${locale.languageCode}',
      );
      // await multiScreenGolden(
      //   tester,
      //   '$name-${locale.languageCode}',
      //   devices: [Device.iphone11, Device.phone, Device.tabletLandscape],
      // );
    }
  }, tags: ['loc']);
}
