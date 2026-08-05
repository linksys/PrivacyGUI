import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the fonts the app actually ships with into the test font collection.
///
/// Flutter's test runner registers no real fonts: every glyph falls back to the
/// engine's built-in monospace test font, which is 1.8-2.7x wider than
/// NeueHaasGrotTextRound (a MAC address measures 238dp instead of ~130dp). Tests
/// that measure layout therefore need the real fonts, or they measure a font no
/// user ever sees.
///
/// Call this from a `flutter_test_config.dart` so it runs once before the tests
/// in that directory. Safe to call more than once.
Future<void> loadAppTestFonts() async {
  final uiKitRoot = _resolveUiKitPath();

  // Main font from the ui_kit_library package.
  final mainFont = FontLoader('packages/ui_kit_library/NeueHaasGrotTextRound');
  final mainFontFile =
      File('$uiKitRoot/assets/fonts/NeueHaasGrotTextRound-55Roman.otf');
  if (mainFontFile.existsSync()) {
    mainFont.addFont(
        Future.value(ByteData.view(mainFontFile.readAsBytesSync().buffer)));
    final boldFile =
        File('$uiKitRoot/assets/fonts/NeueHaasGrotTextRound-75Bold.otf');
    if (boldFile.existsSync()) {
      mainFont.addFont(
          Future.value(ByteData.view(boldFile.readAsBytesSync().buffer)));
    }
  }
  await mainFont.load();

  // Fallback fonts for non-Latin locales.
  const fontNames = [
    'NotoSans',
    'NotoSansKR',
    'NotoSansSC',
    'NotoSansArabic',
    'NotoSansThai',
  ];
  const fontFiles = [
    'NotoSans-Regular.ttf',
    'NotoSansKR-Regular.ttf',
    'NotoSansSC-Regular.ttf',
    'NotoSansArabic-Regular.ttf',
    'NotoSansThai-Regular.ttf',
  ];
  for (var i = 0; i < fontNames.length; i++) {
    final loader = FontLoader('packages/ui_kit_library/${fontNames[i]}');
    final file = File('test/fonts/${fontFiles[i]}');
    if (file.existsSync()) {
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

/// Resolve the ui_kit_library package root from .dart_tool/package_config.json.
///
/// Parses the structured JSON (per Dart package config spec) rather than relying
/// on regex or hardcoded paths, so it works on any machine and CI environment.
String _resolveUiKitPath() {
  final configFile = File('.dart_tool/package_config.json');
  if (configFile.existsSync()) {
    final json = jsonDecode(configFile.readAsStringSync()) as Map;
    final packages = json['packages'] as List? ?? [];
    for (final pkg in packages) {
      if (pkg['name'] == 'ui_kit_library') {
        final rootUri = pkg['rootUri'] as String;
        if (rootUri.startsWith('file://')) {
          return Uri.parse(rootUri).toFilePath();
        }
        // Relative path (rare for git dependencies, but handle it)
        return File('.dart_tool/$rootUri').path;
      }
    }
  }
  throw StateError(
    'Cannot resolve ui_kit_library path. '
    'Run "flutter pub get" to generate .dart_tool/package_config.json.',
  );
}
