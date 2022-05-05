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
    primary: MoabColor.white,//模板
    secondary: MoabColor.black,//文字,輸入外框
    tertiary: MoabColor.blackAlpha70,//透明文字
    surface: MoabColor.placeholderGrey,//placeHolder文字
    background: MoabColor.white,//背景
    onPrimary: MoabColor.primaryBlue,//主按鈕背景色
    onSecondary: MoabColor.primaryBlueAlpha10,//次按鈕背景色
    onTertiary: MoabColor.textButtonBlue,//TextBtn文字
  );

  static final _mainDarkColorTheme = const ColorScheme.dark().copyWith(
    brightness: Brightness.dark,
    primary: MoabColor.primaryDarkGrey,//模板
    secondary: Colors.yellow,//文字,輸入外框
    tertiary: const Color.fromRGBO(246, 191, 0, 0.7),//透明文字
    surface: Colors.white,//placeHolder文字
    background: MoabColor.primaryDarkGrey,//背景
    onPrimary: const Color.fromRGBO(0, 0, 0, 1.0),//主按鈕背景色
    onSecondary: const Color.fromRGBO(0, 0, 0, 0.1),//次按鈕背景色
    onTertiary: const Color.fromRGBO(12, 234, 188, 1.0),//TextBtn文字
  );

  ///////Setup

  static final setupModuleLightModeData = ThemeData.from(
    colorScheme: _setupModuleLightColorTheme,
    textTheme: _textTheme,
  );

  static final setupModuleDarkModeData = ThemeData.from(
    colorScheme: _setupModuleDarkColorTheme,
    textTheme: _textTheme,
  );

  static final _setupModuleLightColorTheme = const ColorScheme.light().copyWith(
    brightness: Brightness.light,
    primary: MoabColor.primaryBlue,//模板
    secondary: MoabColor.white,//文字,輸入外框
    tertiary: MoabColor.whiteAlpha70,//透明文字
    surface: MoabColor.placeholderGrey,//placeHolder文字
    background: MoabColor.primaryBlue,//背景
    onPrimary: MoabColor.white,//主按鈕背景色
    onSecondary: MoabColor.whiteAlpha10,//次按鈕背景色
    onTertiary: MoabColor.textButtonBlue,//TextBtn文字
  );

  static final _setupModuleDarkColorTheme = const ColorScheme.dark().copyWith(
    brightness: Brightness.dark,
    primary: MoabColor.primaryDarkGreen,//模板
    secondary: Colors.yellow,//文字,輸入外框
    tertiary: const Color.fromRGBO(246, 191, 0, 0.7),//透明文字
    surface: Colors.white,//placeHolder文字
    background: MoabColor.primaryDarkGreen,//背景
    onPrimary: const Color.fromRGBO(0, 0, 0, 1.0),//主按鈕背景色
    onSecondary: const Color.fromRGBO(0, 0, 0, 0.1),//次按鈕背景色
    onTertiary: const Color.fromRGBO(234, 12, 56, 1.0),//TextBtn文字
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