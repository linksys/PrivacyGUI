import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:golden_toolkit/golden_toolkit.dart';


///
/// Add fonts here is there has more fonts needed.
///
final _testFonts = <String, String>{
  'NoToSans': 'plugins/widgets/lib/fonts/NotoSans-Regular.ttf',
  'NoToSansKR': 'plugins/widgets/lib/fonts/NotoSansKR-Regular.ttf',
  'NoToSansSC': 'plugins/widgets/lib/fonts/NotoSansSC-Regular.ttf',
  'NoToSansAR': 'plugins/widgets/lib/fonts/NotoSansArabic-Regular.ttf',
  'NoToSansTh': 'plugins/widgets/lib/fonts/NotoSansThai-Regular.ttf'
};

///
/// To load custom fonts for testing use.
///
Future<void> loadTestFonts() async {
  await loadAppFonts();

  // Load custom fonts
  for (final font in _testFonts.entries) {
    await _loadFont(font.value, font.key);
  }
}

Future<void> _loadFont(String path, String fontFamily) async {
  File file = File(path);
  Uint8List bytes = file.readAsBytesSync();
  await loadFontFromList(bytes, fontFamily: fontFamily);
}
