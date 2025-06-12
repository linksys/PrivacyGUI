import 'package:flutter/material.dart';

/// Enum representing the available app colors for modular apps.
enum ModularAppColor {
  cyanAccent('cyanAccent', 0xFF00E5FF),
  dpOrangeAccent('dpOrangeAccent', 0xFFFF6D00),
  ltGreenAccent('ltGreenAccent', 0xFF64DD17),
  ltBlueAccent('ltBlueAccent', 0xFF00B0FF),
  purpleAccent('purpleAccent', 0xFFD500F9),
  pinkAccent('pinkAccent', 0xFFFF4081),
  amberAccent('amberAccent', 0xFFFFAB00),
  tealAccent('tealAccent', 0xFF1DE9B6),
  deepPurpleAccent('deepPurpleAccent', 0xFF7C4DFF),
  lightBlueAccent('lightBlueAccent', 0xFF40C4FF),
  limeAccent('limeAccent', 0xFFC6FF00),
  deepOrangeAccent('deepOrangeAccent', 0xFFFF3D00),
  indigoAccent('indigoAccent', 0xFF536DFE),
  redAccent('redAccent', 0xFFFF1744),
  yellowAccent('yellowAccent', 0xFFFFEA00),
  lightGreenAccent('lightGreenAccent', 0x76FF03),
  blueGreyAccent('blueGreyAccent', 0x546E7A),
  brownAccent('brownAccent', 0x8D6E63),
  deepOrangeAccent2('deepOrangeAccent2', 0xFF6E40C4),
  lightPinkAccent('lightPinkAccent', 0xFF80DEEA),
  blueAccent('blueAccent', 0x2979FF),
  greenAccent('greenAccent', 0x00E676),
  deepPurpleAccent2('deepPurpleAccent2', 0x7E57C2),
  amberAccent2('amberAccent2', 0xFFC400);

  final String value;
  final int colorValue;

  const ModularAppColor(this.value, this.colorValue);

  /// Returns the Color object for this color
  Color get color => Color(colorValue);

  /// Converts a string value to the corresponding ModularAppColor enum.
  /// Returns null if no match is found.
  static ModularAppColor fromString(String value) {
    try {
      return ModularAppColor.values.firstWhere(
        (color) => color.value == value,
      );
    } catch (e) {
      return ModularAppColor.amberAccent;
    }
  }

  @override
  String toString() => value;

  /// Returns the color value as a hex string
  String get hexValue =>
      '#${colorValue.toRadixString(16).substring(2).toUpperCase()}';
}
