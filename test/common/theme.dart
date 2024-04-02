import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:linksys_widgets/theme/material/theme_data.dart';


final mockLightThemeData =
    linksysLightThemeData.copyWith(textTheme: mockLinksysDarkTextTheme);
final mockDarkThemeData =
    linksysDarkThemeData.copyWith(textTheme: mockLinksysLightTextTheme);
    
///
/// This is used to help to generate snapshots with localizations
/// The font is different than Application using.
///
final mockLinksysLightTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 57,
    decoration: TextDecoration.none,
    height: 64 / 57,
    letterSpacing: -0.25,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  displayMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 45,
    decoration: TextDecoration.none,
    height: 52 / 45,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  displaySmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 36,
    decoration: TextDecoration.none,
    height: 44 / 36,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  headlineLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    decoration: TextDecoration.none,
    height: 40 / 32,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  headlineMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    decoration: TextDecoration.none,
    height: 36 / 28,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  headlineSmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    decoration: TextDecoration.none,
    height: 32 / 24,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  titleLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 22,
    decoration: TextDecoration.none,
    height: 28 / 22,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  titleMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    decoration: TextDecoration.none,
    height: 24 / 16,
    letterSpacing: 0.15,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  titleSmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    decoration: TextDecoration.none,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  labelLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    decoration: TextDecoration.none,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  labelMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 12,
    decoration: TextDecoration.none,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  labelSmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 11,
    decoration: TextDecoration.none,
    height: 16 / 11,
    letterSpacing: 0.5,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  bodyLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    decoration: TextDecoration.none,
    height: 24 / 16,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  bodyMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    decoration: TextDecoration.none,
    height: 20 / 14,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
  bodySmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    decoration: TextDecoration.none,
    height: 16 / 12,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.white,
  ),
);
final mockLinksysDarkTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 57,
    decoration: TextDecoration.none,
    height: 64 / 57,
    letterSpacing: -0.25,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  displayMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 45,
    decoration: TextDecoration.none,
    height: 52 / 45,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  displaySmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 36,
    decoration: TextDecoration.none,
    height: 44 / 36,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  headlineLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    decoration: TextDecoration.none,
    height: 40 / 32,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  headlineMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    decoration: TextDecoration.none,
    height: 36 / 28,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  headlineSmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    decoration: TextDecoration.none,
    height: 32 / 24,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  titleLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 22,
    decoration: TextDecoration.none,
    height: 28 / 22,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  titleMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    decoration: TextDecoration.none,
    height: 24 / 16,
    letterSpacing: 0.15,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  titleSmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    decoration: TextDecoration.none,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  labelLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    decoration: TextDecoration.none,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  labelMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 12,
    decoration: TextDecoration.none,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  labelSmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w700,
    fontSize: 11,
    decoration: TextDecoration.none,
    height: 16 / 11,
    letterSpacing: 0.5,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  bodyLarge: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    decoration: TextDecoration.none,
    height: 24 / 16,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  bodyMedium: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    decoration: TextDecoration.none,
    height: 20 / 14,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
  bodySmall: TextStyle(
    fontFamily: 'NoToSans',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    decoration: TextDecoration.none,
    height: 16 / 12,
    letterSpacing: 0,
    fontFamilyFallback: _fallbackFontFamily,
    color: Colors.black,
  ),
);
final List<String> _fallbackFontFamily = List.from(_testFonts.keys);

///
/// Add fonts here is there has more fonts needed.
///
final _testFonts = <String, String>{
  'NoToSans': 'test/fonts/NotoSans-Regular.ttf',
  'NoToSansKR': 'test/fonts/NotoSansKR-Regular.ttf',
  'NoToSansTC': 'test/fonts/NotoSansTC-Regular.ttf',
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
