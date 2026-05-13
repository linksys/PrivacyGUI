import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

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
/// - Default light/dark [ThemeData] (used by some UI widgets).
///
/// Theme configuration loading is handled by `themeConfigProvider` (Riverpod).
void dependencySetup() {
  // Register default ThemeData for UI widgets that read from GetIt
  // (e.g., top_bar.dart, general_settings_widget.dart)
  final config = ThemeJsonConfig.defaultConfig();

  if (!getIt.isRegistered<ThemeJsonConfig>()) {
    getIt.registerSingleton<ThemeJsonConfig>(config);
  }

  if (!getIt.isRegistered<ThemeData>(instanceName: 'lightThemeData')) {
    getIt.registerSingleton<ThemeData>(
      config.createLightTheme(),
      instanceName: 'lightThemeData',
    );
  }

  if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
    getIt.registerSingleton<ThemeData>(
      config.createDarkTheme(),
      instanceName: 'darkThemeData',
    );
  }

  // Register UspClient on Web platform only
  if (kIsWeb && !getIt.isRegistered<UspClient>()) {
    try {
      getIt.registerSingleton<UspClient>(UspClient(
        Uri.base.origin,
      ));
      logger.d('[DI]: UspClient registered (Web)');
    } catch (e) {
      logger.w('[DI]: UspClient registration failed: $e');
    }
  }
}
