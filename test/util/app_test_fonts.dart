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
/// Idempotent-ish: safe to call once per test file in `setUpAll`.
///
/// A MISSING TEXT FONT THROWS, IT IS NOT SKIPPED
///   This used to skip missing files silently so that "CI without the ui_kit
///   checkout" could still run. That is not a state worth running in: it is the
///   state where every pixel measurement is quietly Ahem's, and a suite that
///   passes there passes for the wrong reason. Nor is it a real condition —
///   `ui_kit_library` is a pub dependency, present after `flutter pub get`, and
///   the five Noto files are committed under `test/fonts/`. What *is* real is a
///   ui_kit ref bump moving the pub-cache path (resolved here from
///   `package_config.json`) or renaming an `.otf`, which is exactly the failure
///   that must be loud.
///
///   The icon fonts stay tolerant: glyph advances in an icon font are one em by
///   definition and Flutter sizes icons from the widget, so a missing icon font
///   costs a tofu box, not a wrong measurement.
import 'package:privacy_gui/localization/fallback_font_resolver.dart';

Future<void> loadAppFonts() async {
  // Injects the bare-name fallback resolver into ui_kit for AppText
  FallbackFontResolver.install();

  final uiKitRoot = _resolveUiKitPath();

  /// Text fonts whose absence would silently turn every measurement into Ahem's.
  final missing = <String>[];

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
    } else {
      missing.add(boldFile.path);
    }
  } else {
    missing.add(mainFontFile.path);
  }
  await mainFont.load();

  // Icon fonts: LinksysIcons (ui_kit_library) & MaterialIcons (Flutter SDK).
  final linksysFontFile = File('$uiKitRoot/assets/fonts/LinksysIcons.otf');
  if (linksysFontFile.existsSync()) {
    final bytes = linksysFontFile.readAsBytesSync();
    final linksysLoaderPkg = FontLoader('packages/ui_kit_library/LinksysIcons');
    linksysLoaderPkg.addFont(Future.value(ByteData.view(bytes.buffer)));
    await linksysLoaderPkg.load();

    final linksysLoaderBare = FontLoader('LinksysIcons');
    linksysLoaderBare.addFont(Future.value(ByteData.view(bytes.buffer)));
    await linksysLoaderBare.load();
  }

  final matFile = _findMaterialIconsFile();
  if (matFile != null && matFile.existsSync()) {
    final matLoader = FontLoader('MaterialIcons');
    matLoader
        .addFont(Future.value(ByteData.view(matFile.readAsBytesSync().buffer)));
    await matLoader.load();
  }

  // CJK / Arabic / Thai / Russian fallbacks mapping.
  //
  // NotoSansTC/JP/HK all point at the SC file. Measured, that substitution is
  // metric-neutral for these scripts — one CJK string came out at 177.6px under
  // SC, TC and KR alike, because the advance is one em per ideograph in all of
  // them — so it changes no measurement; it only avoids committing three more
  // multi-megabyte files.
  final fontMap = <String, String>{
    'NotoSans': 'test/fonts/NotoSans-Regular.ttf',
    'NotoSansLatinExt': 'test/fonts/NotoSans-Regular.ttf',
    'NotoSansArabic': 'test/fonts/NotoSansArabic-Regular.ttf',
    'NotoSansThai': 'test/fonts/NotoSansThai-Regular.ttf',
    'NotoSansKR': 'test/fonts/NotoSansKR-Regular.ttf',
    'NotoSansSC': 'test/fonts/NotoSansSC-Regular.ttf',
    'NotoSansTC': 'test/fonts/NotoSansSC-Regular.ttf',
    'NotoSansJP': 'test/fonts/NotoSansSC-Regular.ttf',
    'NotoSansHK': 'test/fonts/NotoSansSC-Regular.ttf',
  };

  for (final entry in fontMap.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) {
      missing.add(file.path);
      continue;
    }
    final bytes = file.readAsBytesSync();

    final loaderPkg = FontLoader('packages/ui_kit_library/${entry.key}');
    loaderPkg.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loaderPkg.load();

    final loaderBare = FontLoader(entry.key);
    loaderBare.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loaderBare.load();
  }

  // System fallback families for Flutter test engine missing glyph resolution.
  const fallbackFamilies = ['Roboto', '.SF UI Text', '.AppleSystemUIFont'];
  for (final family in fallbackFamilies) {
    final fallbackLoader = FontLoader(family);
    for (final fontPath in fontMap.values.toSet()) {
      final file = File(fontPath);
      if (file.existsSync()) {
        fallbackLoader.addFont(
            Future.value(ByteData.view(file.readAsBytesSync().buffer)));
      }
    }
    await fallbackLoader.load();
  }

  if (missing.isNotEmpty) {
    throw StateError(
      'loadAppFonts() could not find ${missing.length} text font file(s):\n'
      '  ${missing.join('\n  ')}\n'
      'Without them the test engine substitutes its own block font — every '
      'glyph one em wide — so any test that measures text passes or fails on '
      'fictional metrics. Fix the paths rather than tolerating this: the ui_kit '
      'fonts live in the pub-cache checkout resolved from '
      '.dart_tool/package_config.json (a ref bump moves it, so run '
      '"flutter pub get"), and the Noto files are committed under test/fonts/.',
    );
  }
}

File? _findMaterialIconsFile() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final file = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (file.existsSync()) return file;
  }
  // Fallback: resolve relative to the current flutter executable or fvm version
  final flutterBin = File(Platform.resolvedExecutable);
  final sdkDir = flutterBin.parent.parent;
  final candidate = File(
      '${sdkDir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (candidate.existsSync()) return candidate;
  return null;
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
