import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import '../mocks/jnap_service_supported_mocks.dart';

void mockDependencyRegister() {
  getIt.registerSingleton<ServiceHelper>(MockServiceHelper());
  getIt.registerSingleton<ThemeData>(linksysLightThemeData, instanceName: 'lightThemeData');
  getIt.registerSingleton<ThemeData>(linksysDarkThemeData, instanceName: 'darkThemeData');
}