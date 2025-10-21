import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import '../mocks/jnap_service_supported_mocks.dart';
import 'theme_data.dart';

void mockDependencyRegister() {
  if (!getIt.isRegistered<ServiceHelper>()) {
    getIt.registerSingleton<ServiceHelper>(MockServiceHelper());
  }
  if (!getIt.isRegistered<ThemeData>(instanceName: 'lightThemeData')) {
    getIt.registerSingleton<ThemeData>(mockLightThemeData,
        instanceName: 'lightThemeData');
  }
  if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
    getIt.registerSingleton<ThemeData>(mockDarkThemeData,
        instanceName: 'darkThemeData');
  }
}
