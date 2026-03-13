import 'package:flutter/material.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Builds a [ThemeData] by merging a base [ThemeJsonConfig] with
/// [DemoThemeConfig] overrides from the Theme Studio.
///
/// [themeConfig] — base JSON config (device-specific or default).
/// Falls back to `getIt<ThemeJsonConfig>()` when omitted.
///
/// Used by both `LinksysApp` (production) and `DemoLinksysApp` (demo mode)
/// to keep theme-building logic in a single place.
ThemeData buildDemoThemeData({
  required Brightness brightness,
  required DemoThemeConfig config,
  ThemeJsonConfig? themeConfig,
  Color? userThemeColor,
}) {
  final effectiveConfig = themeConfig ?? getIt<ThemeJsonConfig>();
  final baseJson = brightness == Brightness.dark
      ? effectiveConfig.darkJson
      : effectiveConfig.lightJson;

  final dynamicJson = Map<String, dynamic>.from(baseJson);
  dynamicJson['style'] = config.style;
  if (config.globalOverlay != null) {
    dynamicJson['globalOverlay'] = config.globalOverlay!.name;
  } else {
    dynamicJson.remove('globalOverlay');
  }
  dynamicJson['visualEffects'] = config.visualEffects;

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

  final designTheme = CustomDesignTheme.fromJson(dynamicJson);

  // Resolve final seed color for AppTheme.create
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
  final resolvedSeedColor =
      effectiveSeedColor ?? parsedSeedColor ?? AppPalette.brandPrimary;

  return AppTheme.create(
    brightness: brightness,
    seedColor: resolvedSeedColor,
    designThemeBuilder: (_) => designTheme,
  );
}
