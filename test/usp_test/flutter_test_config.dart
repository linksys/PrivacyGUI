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
      ),
    ),
    run: testMain,
  );
}

Future<void> _loadFonts() async {
  final fontLoader = FontLoader('NotoSans');
  final fontFile = File('test/fonts/NotoSans-Regular.ttf');
  if (fontFile.existsSync()) {
    final bytes = fontFile.readAsBytesSync();
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await fontLoader.load();
}
