import 'package:flutter/material.dart';
import 'package:moab_poc/design/colors.dart';

class MoabTheme {
  static final mainLightModeData = ThemeData.from(
    colorScheme: _mainLightColorTheme,
    textTheme: _textTheme,
  );

  static final mainDarkModeData = ThemeData.from(
    colorScheme: _mainDarkColorTheme,
    textTheme: _textTheme,
  );

  static final _mainLightColorTheme = const ColorScheme.light().copyWith(
    brightness: Brightness.light,
    primary: MoabColor.white, //文字,輸入外框,主按鈕背景等主色調
    secondary: MoabColor.whiteAlpha10, //次按鈕背景色
    tertiary: MoabColor.whiteAlpha70, //透明文字
    primaryContainer: MoabColor.progressBarBlue,
    surface: MoabColor.placeholderGrey, //placeHolder文字
    background: MoabColor.authBackground, //背景
    onPrimary: MoabColor.black, //主按鈕文字
    onSecondary: MoabColor.white, //次按鈕文字
    onTertiary: MoabColor.textButtonBlue, //TextBtn文字
    onPrimaryContainer: MoabColor.progressBarGreen,
  );

  static final _mainDarkColorTheme = const ColorScheme.dark().copyWith(
    brightness: Brightness.dark,
    primary: MoabColor.primaryDarkGrey,
    secondary: Colors.yellow,
    tertiary: const Color.fromRGBO(246, 191, 0, 0.7),
    primaryContainer: MoabColor.progressBarBlue,
    surface: Colors.white,
    background: MoabColor.primaryDarkGrey,
    onPrimary: const Color.fromRGBO(0, 0, 0, 1.0),
    onSecondary: const Color.fromRGBO(0, 0, 0, 0.1),
    onTertiary: const Color.fromRGBO(12, 234, 188, 1.0),
    onPrimaryContainer: MoabColor.progressBarGreen,
  );

  ///////Setup

  static final setupModuleLightModeData = ThemeData.from(
    colorScheme: _setupModuleLightColorTheme,
    textTheme: _textTheme,
  ).copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  )));

  static final setupModuleDarkModeData = ThemeData.from(
    colorScheme: _setupModuleDarkColorTheme,
    textTheme: _textTheme,
  ).copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  )));

  ///////Dashboard
  static final dashboardLightModeData = ThemeData.from(
    colorScheme: _dashboardLightColorTheme,
    textTheme: _textTheme,
  ).copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  )));

  static final _dashboardLightColorTheme = const ColorScheme.light().copyWith(
    brightness: Brightness.light,
    primary: MoabColor.white, //文字,輸入外框,主按鈕背景等主色調
    secondary: MoabColor.whiteAlpha10, //次按鈕背景色
    tertiary: MoabColor.whiteAlpha70, //透明文字
    primaryContainer: MoabColor.progressBarBlue,
    surface: MoabColor.placeholderGrey, //placeHolder文字
    background: MoabColor.dashboardBackground, //背景
    onPrimary: MoabColor.black, //主按鈕文字
    onSecondary: MoabColor.white, //次按鈕文字
    onTertiary: MoabColor.textButtonBlue, //TextBtn文字
    onPrimaryContainer: MoabColor.progressBarGreen,
  );

  static final _setupModuleLightColorTheme = const ColorScheme.light().copyWith(
    brightness: Brightness.light,
    primary: MoabColor.white, //文字,輸入外框,主按鈕背景等主色調
    secondary: MoabColor.whiteAlpha10, //次按鈕背景色
    tertiary: MoabColor.whiteAlpha70, //透明文字
    primaryContainer: MoabColor.progressBarBlue,
    surface: MoabColor.placeholderGrey, //placeHolder文字
    background: MoabColor.primaryBlue, //背景
    onPrimary: MoabColor.black, //主按鈕文字
    onSecondary: MoabColor.white, //次按鈕文字
    onTertiary: MoabColor.textButtonBlue, //TextBtn文字
    onPrimaryContainer: MoabColor.progressBarGreen,
  );

  static final _setupModuleDarkColorTheme = const ColorScheme.dark().copyWith(
    brightness: Brightness.dark,
    primary: MoabColor.primaryDarkGreen,
    secondary: Colors.yellow,
    tertiary: const Color.fromRGBO(246, 191, 0, 0.7),
    primaryContainer: MoabColor.progressBarBlue,
    surface: Colors.white,
    background: MoabColor.primaryDarkGreen,
    onPrimary: const Color.fromRGBO(0, 0, 0, 1.0),
    onSecondary: const Color.fromRGBO(0, 0, 0, 0.1),
    onTertiary: const Color.fromRGBO(234, 12, 56, 1.0),
    onPrimaryContainer: MoabColor.progressBarGreen,
  );

  static final _textTheme = Typography().white.copyWith(
        headline1: const TextStyle(
          fontSize: 22,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        headline2: const TextStyle(
          fontSize: 18,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        headline3: const TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        headline4: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        button: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        bodyText1: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
      );
}
