// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ui';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:meta/meta.dart';

import 'theme.dart';

// const allDevicesVariants = [
//   ...allMobileVariants,
//   ...allDesktopVariants,
// ];

// const allMobileVariants = [
//   Device(name: 'Device320w', size: Size(320, 568)),
//   Device(name: 'Device480w', size: Size(480, 932)),
//   Device(name: 'Device744w', size: Size(744, 1133)),
// ];
// const allDesktopVariants = [
//   Device(name: 'Device1280w', size: Size(1280, 720)),
//   Device(name: 'Device1440w', size: Size(1440, 900)),
// ];

// class LocalizedScreen extends ScreenSize {
//   final Locale locale;
//   final ScreenSize screenSize;

//   LocalizedScreen(
//     String name, {
//     required this.locale,
//     required this.screenSize,
//     required double width,
//     required double height,
//     double pixelDensity = 1.0,
//   }) : super(
//           name,
//           width,
//           height,
//           pixelDensity,
//         );

//   @override
//   String toString() =>
//       '${screenSize.name}-${locale.languageCode}_${locale.countryCode ?? ''}(${screenSize.width}, ${screenSize.height}, ${screenSize.pixelDensity})';
//   String toShort() => '${screenSize.name}-${locale.toLanguageTag()}';
// }

@Deprecated(
    'Please use another testLocalization in #test_responsive_widget.dart')
@isTest
void testLocalizations(
  String name,
  FutureOr<void> Function(WidgetTester, Locale) testMain, {
  List<Device>? deviceVariants,
  List<Locale>? locales,
}) async {
  testGoldens(name, (tester) async {
    await loadTestFonts();
    final supportedLocales = locales ?? AppLocalizations.supportedLocales;
    // final supportedLocales = AppLocalizations.supportedLocales.sublist(0, 1);
    for (final locale in supportedLocales) {
      await testMain(tester, locale);

      // await multiScreenGolden(
      //   tester,
      //   '$name-${locale.languageCode}',
      //   devices: deviceVariants ?? allDevicesVariants,
      // );
    }
  });
}

// @isTest
// void testLocalizations2(
//   String name,
//   FutureOr<void> Function(WidgetTester, Locale) testMain, {
//   String? altName,
//   List<Locale>? locales,
//   List<ScreenSize>? devices,
//   bool? skip,
//   Timeout? timeout,
//   bool semanticsEnabled = true,
// }) async {
//   final supportedLocales = locales ?? AppLocalizations.supportedLocales;
//   final supportedDevices = devices ?? responsiveAllScreens;
//   final set = supportedLocales
//       .map((locale) => supportedDevices
//           .map((device) => LocalizedScreen(locale: locale, screenSize: device)))
//       .expand((list) => list)
//       .toSet();
//   final variants = ValueVariant(set);
//   testWidgets(
//     name,
//     (tester) async {
//       await loadTestFonts();
//       final current = variants.currentValue!;
//       await tester.setScreenSize(current.screenSize);
//       await testMain(tester, current.locale);
//       final actualFinder = find.byWidgetPredicate((w) => true).first;

//       await expectLater(
//           actualFinder,
//           matchesGoldenFile(
//               "goldens/${altName ?? name}-${current.toShort()}.png"));
//     },
//     variant: variants,
//     skip: skip,
//     timeout: timeout,
//     semanticsEnabled: semanticsEnabled,
//     tags: ['loc'],
//   );
// }
