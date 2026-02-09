import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

import 'package:privacy_gui/theme/theme_json_config.dart';

/// A global instance of [GetIt] used as a service locator for dependency injection.
///
/// This instance is used to register and retrieve singleton objects, such as
/// services or theme data, from anywhere in the application.
final getIt = GetIt.instance;

/// Sets up the application's dependencies by registering them with [GetIt].
///
/// This function is called once at application startup to initialize and
/// register all singleton services and objects that need to be globally
/// accessible. Currently, it registers:
/// - A singleton of [ServiceHelper].
/// - The application's theme configuration (legacy, kept for backward compatibility).
/// - The application's light and dark theme data as named instances.
///
/// ## Theme Management Note:
/// Theme management has been migrated to Riverpod providers for reactive updates.
/// The [ThemeJsonConfig] registered here serves as a **fallback only**.
///
/// **Active theme loading** is handled by:
/// - `deviceThemeConfigProvider` in [lib/providers/device_theme_config_provider.dart]
/// - Device-specific themes loaded via `BrandUtils.getDeviceTheme()`
/// - Reactive updates when user logs into different router models
///
/// The theme registered in GetIt is only used as a default fallback if the
/// reactive provider fails to load a theme for any reason.
void dependencySetup({ThemeJsonConfig? themeConfig}) {
  getIt.registerSingleton<ServiceHelper>(ServiceHelper());

  // Legacy theme config registration (fallback only)
  // Active theme system uses deviceThemeConfigProvider (Riverpod)
  final config = themeConfig ?? ThemeJsonConfig.defaultConfig();
  getIt.registerSingleton<ThemeJsonConfig>(config);

  getIt.registerSingleton<ThemeData>(
    config.createLightTheme(),
    instanceName: 'lightThemeData',
  );
  getIt.registerSingleton<ThemeData>(
    config.createDarkTheme(),
    instanceName: 'darkThemeData',
  );
}
