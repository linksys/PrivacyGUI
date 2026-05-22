import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      ciGoldensConfig: CiGoldensConfig(enabled: false),
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: true,
        renderShadows: false,
        filePathResolver: (fileName, _) => 'goldens/$fileName.png',
        diffThreshold: 0.025,
      ),
    ),
    run: testMain,
  );
}

Future<void> _loadFonts() async {
  final uiKitRoot = _resolveUiKitPath();

  // Load main font from ui_kit_library package
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

  // Load fallback fonts
  final fontNames = [
    'NotoSans',
    'NotoSansKR',
    'NotoSansSC',
    'NotoSansArabic',
    'NotoSansThai'
  ];
  final fontFiles = [
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
