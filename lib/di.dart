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
/// - The application's light theme data as a named instance.
/// - The application's dark theme data as a named instance.
void dependencySetup({ThemeJsonConfig? themeConfig}) {
  getIt.registerSingleton<ServiceHelper>(ServiceHelper());

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
