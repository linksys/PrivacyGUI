import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's real fonts (NeueHaasGrotTextRound + the Noto Sans family)
/// into the test binding via [FontLoader].
///
/// WHY THIS EXISTS AS A SHARED HELPER
///   Flutter's default test font is Ahem — every glyph is a fixed-width block,
///   so measured text widths are meaningless. Any test whose *correctness*
///   depends on real text metrics (layout, RenderFlex overflow, ellipsis) must
///   load the real fonts first, or it will pass/fail for the wrong reasons.
///
///   The golden pipeline already does this inside
///   `test/golden_test/flutter_test_config.dart`. But a `flutter_test_config.dart`
///   only auto-applies to tests in its own directory and below, so a test that
///   must live *outside* `test/golden_test/` (e.g. to run in the PR gate rather
///   than the golden-tagged set) can't inherit it. Extracting the logic here
///   lets both callers share one implementation — call it from `setUpAll`.
///
/// Idempotent-ish: safe to call once per test file in `setUpAll`. Missing font
/// files are skipped silently (CI without the ui_kit checkout still runs, just
/// with fewer fallbacks) — the primary NeueHaas + NotoSans covers Latin scripts,
/// which is what the long-word overflow locales (de/fi/ru/fr) need.
Future<void> loadAppFonts() async {
  final uiKitRoot = _resolveUiKitPath();

  // Primary font, shipped inside the ui_kit_library package.
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

  // CJK / Arabic / Thai fallbacks, vendored under test/fonts/.
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

/// Resolves the ui_kit_library package root from
/// `.dart_tool/package_config.json`.
///
/// Parses the structured JSON (per the Dart package-config spec) rather than
/// relying on regex or hardcoded paths, so it works on any machine and CI env.
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
        // Relative path (rare for git dependencies, but handle it).
        return File('.dart_tool/$rootUri').path;
      }
    }
  }
  throw StateError(
    'Cannot resolve ui_kit_library path. '
    'Run "flutter pub get" to generate .dart_tool/package_config.json.',
  );
}
