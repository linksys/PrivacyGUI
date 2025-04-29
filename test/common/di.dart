import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';

import '../mocks/jnap_service_supported_mocks.dart';
import 'theme.dart';

void mockDependencyRegister() {
  getIt.registerSingleton<ServiceHelper>(MockServiceHelper());
  getIt.registerSingleton<ThemeData>(mockLightThemeData, instanceName: 'lightThemeData');
  getIt.registerSingleton<ThemeData>(mockDarkThemeData, instanceName: 'darkThemeData');
}