import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Single source of truth for theme configuration.
///
/// Responsible for parsing JSON configuration and generating [ThemeData].
/// Supports loading from a complete JSON object, JSON string, or asset file.
class ThemeJsonConfig {
  final Map<String, dynamic> _lightJson;
  final Map<String, dynamic> _darkJson;

  ThemeJsonConfig._({
    required Map<String, dynamic> lightJson,
    required Map<String, dynamic> darkJson,
  })  : _lightJson = lightJson,
        _darkJson = darkJson;

  /// Default configuration (Glass style).
  factory ThemeJsonConfig.defaultConfig() => ThemeJsonConfig._(
        lightJson: {'style': 'flat', 'brightness': 'light'},
        darkJson: {'style': 'flat', 'brightness': 'dark'},
      );

  /// Constructs from a complete JSON object (including light/dark colors).
  ///
  /// JSON structure example:
  /// ```json
  /// {
  ///   "style": "glass",
  ///   "seedColor": "#6750A4",
  ///   "colors": {
  ///     "light": { "primary": "#..." },
  ///     "dark": { "primary": "#..." }
  ///   },
  ///   "overrides": { ... }
  /// }
  /// ```
  factory ThemeJsonConfig.fromJson(Map<String, dynamic> json) {
    final style = json['style'] as String? ?? 'glass';
    final seedColor = json['seedColor'] as String?;
    final overrides = json['overrides'] as Map<String, dynamic>?;
    final colors = json['colors'] as Map<String, dynamic>?;

    // Compose light theme JSON
    final lightJson = <String, dynamic>{
      'style': style,
      'brightness': 'light',
      if (seedColor != null) 'seedColor': seedColor,
      if (overrides != null) 'overrides': overrides,
      ...?(colors?['light'] as Map<String, dynamic>?),
    };

    // Compose dark theme JSON
    final darkJson = <String, dynamic>{
      'style': style,
      'brightness': 'dark',
      if (seedColor != null) 'seedColor': seedColor,
      if (overrides != null) 'overrides': overrides,
      ...?(colors?['dark'] as Map<String, dynamic>?),
    };

    return ThemeJsonConfig._(lightJson: lightJson, darkJson: darkJson);
  }

  /// Constructs from a JSON string.
  factory ThemeJsonConfig.fromJsonString(String jsonString) {
    if (jsonString.isEmpty) return ThemeJsonConfig.defaultConfig();
    try {
      return ThemeJsonConfig.fromJson(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('Error parsing theme JSON: $e');
      return ThemeJsonConfig.defaultConfig();
    }
  }

  /// Loads from assets.
  static Future<ThemeJsonConfig> fromAssets(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      return ThemeJsonConfig.fromJsonString(jsonString);
    } catch (e) {
      // debugPrint('Theme asset not found: $assetPath');
      return ThemeJsonConfig.defaultConfig();
    }
  }

  /// Creates Light ThemeData (using CustomDesignTheme.fromJson).
  ThemeData createLightTheme([Color? overrideSeedColor]) {
    final json = Map<String, dynamic>.from(_lightJson);
    if (overrideSeedColor != null) {
      json['seedColor'] =
          '#${overrideSeedColor.toARGB32().toRadixString(16).substring(2)}';
    }

    final designTheme = CustomDesignTheme.fromJson(json);
    return AppTheme.create(
      brightness: Brightness.light,
      seedColor: overrideSeedColor ?? AppPalette.brandPrimary,
      designThemeBuilder: (_) => designTheme,
    );
  }

  /// Creates Dark ThemeData.
  ThemeData createDarkTheme([Color? overrideSeedColor]) {
    final json = Map<String, dynamic>.from(_darkJson);
    if (overrideSeedColor != null) {
      json['seedColor'] =
          '#${overrideSeedColor.toARGB32().toRadixString(16).substring(2)}';
    }

    final designTheme = CustomDesignTheme.fromJson(json);
    // return AppTheme.create(
    //   brightness: Brightness.dark,
    //   seedColor: overrideSeedColor ?? AppPalette.brandPrimary,
    //   designThemeBuilder: (_) => designTheme,
    // );
    // TODO: Temporary workaround for dark mode creation to ensure consistency,
    // verifying parameter passing.
    return AppTheme.create(
      brightness: Brightness.dark,
      seedColor: overrideSeedColor ?? AppPalette.brandPrimary,
      designThemeBuilder: (_) => designTheme,
    );
  }
}
