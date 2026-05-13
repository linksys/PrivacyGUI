import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  await _loadTestFonts();
  return testMain();
}

Future<void> _loadTestFonts() async {
  final fontLoader = FontLoader('NotoSans');
  final fontFile = File('test/fonts/NotoSans-Regular.ttf');
  if (fontFile.existsSync()) {
    final bytes = fontFile.readAsBytesSync();
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await fontLoader.load();
}
