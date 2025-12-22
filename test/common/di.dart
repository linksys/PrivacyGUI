import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import '../mocks/jnap_service_supported_mocks.dart';

void mockDependencyRegister() {
  if (!getIt.isRegistered<ServiceHelper>()) {
    getIt.registerSingleton<ServiceHelper>(MockServiceHelper());
  }

  // Use ThemeJsonConfig to match testableRouter themes for consistent rendering
  final config = ThemeJsonConfig.defaultConfig();

  if (!getIt.isRegistered<ThemeData>(instanceName: 'lightThemeData')) {
    getIt.registerSingleton<ThemeData>(config.createLightTheme(),
        instanceName: 'lightThemeData');
  }
  if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
    getIt.registerSingleton<ThemeData>(config.createDarkTheme(),
        instanceName: 'darkThemeData');
  }
}
