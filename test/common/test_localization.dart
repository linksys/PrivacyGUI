import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:meta/meta.dart';

import 'theme.dart';

final mockLightThemeData =
    linksysLightThemeData.copyWith(textTheme: mockLinksysDarkTextTheme);
final mockDarkThemeData =
    linksysDarkThemeData.copyWith(textTheme: mockLinksysLightTextTheme);

@isTest
void testLocalizations(
  String name,
  FutureOr<void> Function(WidgetTester, Locale) testMain,
) async {
  testGoldens(name, (tester) async {
    await loadTestFonts();
    const supportedLocales = AppLocalizations.supportedLocales;
    // final supportedLocales = AppLocalizations.supportedLocales.sublist(0, 1);
    for (final locale in supportedLocales) {
      await testMain(tester, locale);

      await multiScreenGolden(
        tester,
        '$name-${locale.languageCode}',
        devices: const [
          Device(name: 'Device320w', size: Size(320, 568)),
          Device(name: 'Device480w', size: Size(480, 932)),
          Device(name: 'Device744w', size: Size(744, 1133)),
          Device(name: 'Device1280w', size: Size(1280, 720)),
          Device(name: 'Device1440w', size: Size(1440, 900)),
        ],
      );
    }
  }, tags: ['loc']);
}
