import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import '../mocks/jnap_service_supported_mocks.dart';
import 'theme_config.dart';
import 'theme_data.dart';

void mockDependencyRegister({ThemeVariant? themeVariant}) {
  // Unregister if already exists to allow fresh mock setup
  if (getIt.isRegistered<ServiceHelper>()) {
    getIt.unregister<ServiceHelper>();
  }
  getIt.registerSingleton<ServiceHelper>(MockServiceHelper());

  // Register ThemeJsonConfig for DesignSystem.init to use
  final config = themeVariant != null
      ? ThemeJsonConfig.fromJson({
          'style': themeVariant.style.name,
          'visualEffects': 0, // Disable animations for stable screenshots
          'brightness': themeVariant.brightness.name,
          'globalOverlay': 'none',
        })
      : ThemeJsonConfig.defaultConfig();

  if (getIt.isRegistered<ThemeJsonConfig>()) {
    getIt.unregister<ThemeJsonConfig>();
  }
  getIt.registerSingleton<ThemeJsonConfig>(config);

  if (!getIt.isRegistered<ThemeData>(instanceName: 'lightThemeData')) {
    getIt.registerSingleton<ThemeData>(mockLightThemeData,
        instanceName: 'lightThemeData');
  }
  if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
    getIt.registerSingleton<ThemeData>(mockDarkThemeData,
        instanceName: 'darkThemeData');
  }
}

/// Update the ThemeJsonConfig registration for a specific theme variant.
/// Call this before pumping widgets when testing different themes.
///
/// This also updates the ThemeData instances in getIt, because several widgets
/// directly read from getIt<ThemeData> instead of Theme.of(context).
void updateThemeConfig(ThemeVariant themeVariant) {
  final config = ThemeJsonConfig.fromJson({
    'style': themeVariant.style.name,
    'visualEffects': 15,
    'brightness': themeVariant.brightness.name,
    'globalOverlay': 'none',
  });

  if (getIt.isRegistered<ThemeJsonConfig>()) {
    getIt.unregister<ThemeJsonConfig>();
  }
  getIt.registerSingleton<ThemeJsonConfig>(config);

  // Also update the ThemeData instances because some widgets use getIt directly
  final lightVariant =
      ThemeVariant(style: themeVariant.style, brightness: Brightness.light);
  final darkVariant =
      ThemeVariant(style: themeVariant.style, brightness: Brightness.dark);

  final lightTheme = createMockThemeData(lightVariant);
  final darkTheme = createMockThemeData(darkVariant);

  if (getIt.isRegistered<ThemeData>(instanceName: 'lightThemeData')) {
    getIt.unregister<ThemeData>(instanceName: 'lightThemeData');
  }
  getIt.registerSingleton<ThemeData>(lightTheme, instanceName: 'lightThemeData');

  if (getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
    getIt.unregister<ThemeData>(instanceName: 'darkThemeData');
  }
  getIt.registerSingleton<ThemeData>(darkTheme, instanceName: 'darkThemeData');
}
