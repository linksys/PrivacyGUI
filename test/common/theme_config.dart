import 'package:flutter/material.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Available theme styles for screenshot testing.
/// Matches the styles supported by ThemeJsonConfig.
enum ThemeStyle { flat, glass, pixel, aurora, brutal, neumorphic }

/// Represents a theme configuration combining style and brightness.
///
/// Used for generating screenshot test variants across all theme combinations.
class ThemeVariant {
  final ThemeStyle style;
  final Brightness brightness;

  const ThemeVariant({
    required this.style,
    required this.brightness,
  });

  /// Returns the theme name in 'style-brightness' format (e.g., 'glass-light').
  String get name => '${style.name}-${brightness.name}';

  /// Creates ThemeData for this variant using ThemeJsonConfig.
  ThemeData createTheme() {
    final config = ThemeJsonConfig.fromJson({
      'style': style.name,
      'brightness': brightness.name,
      'visualEffects': 15,
      'globalOverlay': 'none',
    });

    return brightness == Brightness.light
        ? config.createLightTheme()
        : config.createDarkTheme();
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeVariant &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          brightness == other.brightness;

  @override
  int get hashCode => Object.hash(style, brightness);
}

/// All available theme variants (6 styles x 2 brightness = 12 combinations).
const allThemeVariants = <ThemeVariant>[
  ThemeVariant(style: ThemeStyle.flat, brightness: Brightness.light),
  ThemeVariant(style: ThemeStyle.flat, brightness: Brightness.dark),
  ThemeVariant(style: ThemeStyle.glass, brightness: Brightness.light),
  ThemeVariant(style: ThemeStyle.glass, brightness: Brightness.dark),
  ThemeVariant(style: ThemeStyle.pixel, brightness: Brightness.light),
  ThemeVariant(style: ThemeStyle.pixel, brightness: Brightness.dark),
  ThemeVariant(style: ThemeStyle.aurora, brightness: Brightness.light),
  ThemeVariant(style: ThemeStyle.aurora, brightness: Brightness.dark),
  ThemeVariant(style: ThemeStyle.brutal, brightness: Brightness.light),
  ThemeVariant(style: ThemeStyle.brutal, brightness: Brightness.dark),
  ThemeVariant(style: ThemeStyle.neumorphic, brightness: Brightness.light),
  ThemeVariant(style: ThemeStyle.neumorphic, brightness: Brightness.dark),
];

/// Default theme variant for backward compatibility.
const defaultThemeVariant = ThemeVariant(
  style: ThemeStyle.glass,
  brightness: Brightness.light,
);

/// Helper extension for ThemeVariant list operations.
extension ThemeVariantListExtension on List<ThemeVariant> {
  /// Get unique theme variants by name.
  List<ThemeVariant> unique() {
    final seen = <String>{};
    return where((t) => seen.add(t.name)).toList();
  }
}
