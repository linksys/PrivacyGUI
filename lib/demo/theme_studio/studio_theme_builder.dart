import 'package:flutter/material.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/demo/providers/theme_studio_config_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Builds a [ThemeData] by merging a base [ThemeJsonConfig] with
/// [ThemeStudioConfig] overrides from the Theme Studio.
///
/// [themeConfig] — base JSON config (device-specific or default).
/// Falls back to `getIt<ThemeJsonConfig>()` when omitted.
///
/// Used by both `LinksysApp` (production) and `DemoLinksysApp` (demo mode)
/// to keep theme-building logic in a single place.
/// Merges a base theme JSON with [ThemeStudioConfig] overrides into the
/// effective theme JSON.
///
/// Pure function (no I/O), extracted so the override semantics can be unit
/// tested directly. The critical contract: `style` / `visualEffects` are only
/// overwritten when the studio config set them explicitly (non-null); when
/// null they inherit from [baseJson] (device theme / THEME_JSON). This is what
/// stops the studio defaults from clobbering the build-time theme in
/// production / E2E builds where Theme Studio is never touched.
Map<String, dynamic> mergeStudioConfigJson(
  Map<String, dynamic> baseJson,
  ThemeStudioConfig config, {
  Color? userThemeColor,
}) {
  final dynamicJson = Map<String, dynamic>.from(baseJson);
  // style / visualEffects are only overwritten when the user explicitly set
  // them in Theme Studio (non-null). When null, the base config's values
  // (device theme / THEME_JSON) are preserved.
  if (config.style != null) {
    dynamicJson['style'] = config.style;
  }
  if (config.globalOverlay != null) {
    dynamicJson['globalOverlay'] = config.globalOverlay!.name;
  }
  if (config.visualEffects != null) {
    dynamicJson['visualEffects'] = config.visualEffects;
  }

  // Seed color: config takes priority, then userThemeColor fallback
  final effectiveSeedColor = config.seedColor ?? userThemeColor;
  if (effectiveSeedColor != null) {
    dynamicJson['seedColor'] =
        '#${effectiveSeedColor.toARGB32().toRadixString(16).substring(2)}';
  }

  // Granular color overrides
  String? colorToHex(Color? c) =>
      c != null ? '#${c.toARGB32().toRadixString(16).substring(2)}' : null;

  if (config.primary != null) {
    dynamicJson['primary'] = colorToHex(config.primary);
  }
  if (config.secondary != null) {
    dynamicJson['secondary'] = colorToHex(config.secondary);
  }
  if (config.tertiary != null) {
    dynamicJson['tertiary'] = colorToHex(config.tertiary);
  }
  if (config.surface != null) {
    dynamicJson['surface'] = colorToHex(config.surface);
  }
  if (config.error != null) {
    dynamicJson['error'] = colorToHex(config.error);
  }

  // Advanced overrides (semantic + component layer)
  if (config.overrides != null) {
    dynamicJson['overrides'] = config.overrides!.toJson();
  }

  return dynamicJson;
}

ThemeData buildStudioThemeData({
  required Brightness brightness,
  required ThemeStudioConfig config,
  ThemeJsonConfig? themeConfig,
  Color? userThemeColor,
}) {
  final effectiveConfig = themeConfig ?? getIt<ThemeJsonConfig>();
  final baseJson = brightness == Brightness.dark
      ? effectiveConfig.darkJson
      : effectiveConfig.lightJson;

  final dynamicJson =
      mergeStudioConfigJson(baseJson, config, userThemeColor: userThemeColor);

  final designTheme = CustomDesignTheme.fromJson(dynamicJson);

  // Resolve final seed color for AppTheme.create. mergeStudioConfigJson has
  // already written the effective seed (config.seedColor ?? userThemeColor)
  // into dynamicJson, so parsing it back covers both sources.
  final seedColorHex = dynamicJson['seedColor'] as String?;
  Color? parsedSeedColor;
  if (seedColorHex != null) {
    try {
      final cleanHex = seedColorHex.replaceAll('#', '');
      if (cleanHex.length == 6) {
        parsedSeedColor = Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        parsedSeedColor = Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
  }
  final resolvedSeedColor = parsedSeedColor ?? AppPalette.brandPrimary;

  return AppTheme.create(
    brightness: brightness,
    seedColor: resolvedSeedColor,
    designThemeBuilder: (_) => designTheme,
  );
}
