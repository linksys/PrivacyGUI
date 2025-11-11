import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import 'config.dart';
import 'screen.dart';
import 'theme_data.dart';

extension ScreenSizeManager on WidgetTester {
  Future<void> setScreenSize(ScreenSize screenSize) async {
    return _setScreenSize(
      width: screenSize.width,
      height: screenSize.height,
      pixelDensity: screenSize.pixelDensity,
    );
  }

  Future<void> _setScreenSize({
    required double width,
    required double height,
    required double pixelDensity,
  }) async {
    final size = Size(width, height);
    await binding.setSurfaceSize(size);
    view.physicalSize = size;
    view.devicePixelRatio = pixelDensity;
  }
}

@isTest
void testResponsiveWidgets(
  String description,
  WidgetTesterCallback callback, {
  String? goldenFilename,
  Future<void> Function(String sizeName, WidgetTester tester)? goldenCallback,
  Future<void> Function(WidgetTester tester)? onCompleted,
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  ValueVariant<ScreenSize>? variants,
  List<String> tags = const [],
}) {
  final variant = variants ?? responsiveAllVariants;
  testWidgets(
    description,
    (tester) async {
      await tester.setScreenSize(variant.currentValue!);
      await callback(tester);
      if (goldenCallback != null && goldenFilename != null) {
        await goldenCallback(
            '$goldenFilename-${variant.currentValue!.toShort()}',
            tester);
      }
      if (onCompleted != null) {
        await onCompleted.call(tester);
      } else {
        // for some scenario w/ timer, pump a few seconds to avoid exception occurs
        await tester.pump(const Duration(seconds: 5));
      }
    },
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: ['ui', ...tags],
  );
}

@isTest
void testLocalizations(
  String name,
  FutureOr<void> Function(WidgetTester, Locale) testMain, {
  String? goldenFilename,
  List<Locale>? locales,
  List<ScreenSize>? screens,
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  Future<void> Function(WidgetTester tester)? onCompleted,
}) async {
  final envLocales = targetLocales;
  final envScreens = targetScreens;

  final supportedLocales = (locales ?? AppLocalizations.supportedLocales)
      .toSet()
      .where((element) => envLocales.toSet().contains(element))
      .toList();
  final supportedDevices = (screens ?? responsiveAllScreens)
      .toSet()
      .where(
          (element) => envScreens.toSet().any((e) => e.width == element.width))
      .toList();
  final isScreenIncluded = supportedDevices.isNotEmpty;
  final set = supportedLocales
      .map((locale) => supportedDevices.map((device) =>
          LocalizedScreen.fromScreenSize(locale: locale, screen: device)))
      .expand((list) => list)
      .toSet();
  final variants = ValueVariant(set);
  testResponsiveWidgets(
    name,
    (tester) async {
      await loadTestFonts();
      final current = variants.currentValue!;
      await tester.setScreenSize(current);
      await testMain(tester, current.locale);
    },
    goldenFilename: goldenFilename,
    goldenCallback: (name, tester) async {
      final actualFinder = find.byWidgetPredicate((w) => true).first;
      await expectLater(actualFinder, matchesGoldenFile('goldens/$name.png'));
    },
    onCompleted: onCompleted,
    variants: !isScreenIncluded ? null : variants,
    skip: (skip ?? false) || !isScreenIncluded,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: ['loc'],
  );
}
