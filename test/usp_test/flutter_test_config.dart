import 'dart:async';
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
  // Load main font from ui_kit_library package
  final mainFont = FontLoader('packages/ui_kit_library/NeueHaasGrotTextRound');
  final mainFontFromCache = File(
      '${_uiKitPath()}/assets/fonts/NeueHaasGrotTextRound-55Roman.otf');
  if (mainFontFromCache.existsSync()) {
    final bytes = mainFontFromCache.readAsBytesSync();
    mainFont.addFont(Future.value(ByteData.view(bytes.buffer)));
    final boldFile = File(
        '${_uiKitPath()}/assets/fonts/NeueHaasGrotTextRound-75Bold.otf');
    if (boldFile.existsSync()) {
      mainFont.addFont(Future.value(ByteData.view(boldFile.readAsBytesSync().buffer)));
    }
  }
  await mainFont.load();

  // Load fallback fonts
  final fontNames = ['NotoSans', 'NotoSansKR', 'NotoSansSC', 'NotoSansArabic', 'NotoSansThai'];
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
      loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

String _uiKitPath() {
  final configFile = File('.dart_tool/package_config.json');
  if (configFile.existsSync()) {
    final content = configFile.readAsStringSync();
    final match = RegExp(r'"rootUri":\s*"file://([^"]+)"')
        .allMatches(content)
        .where((m) => m.group(1)!.contains('privacyGUI-UI-kit'))
        .firstOrNull;
    if (match != null) return match.group(1)!;
  }
  return '/Users/peter.jhong/.pub-cache/git/privacyGUI-UI-kit-b34d9c062b307cb87b34711666a9ce1296618660';
}
