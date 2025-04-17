import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacygui_widgets/theme/material/theme_data.dart';

final getIt = GetIt.instance;

void dependencySetup() {
  getIt.registerSingleton<ServiceHelper>(ServiceHelper());
  getIt.registerSingleton<ThemeData>(linksysLightThemeData, instanceName: 'lightThemeData');
  getIt.registerSingleton<ThemeData>(linksysDarkThemeData, instanceName: 'darkThemeData');
}
