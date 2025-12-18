import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import 'theme_data.dart';

// Assign a globalKey in order to retrieve current Build Context
GlobalKey<NavigatorState> globalKey = GlobalKey();

Widget testableWidget({
  required Widget child,
  ProviderContainer? parent,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? theme,
  ThemeData? darkTheme,
  Locale? locale,
}) =>
    ProviderScope(
      overrides: overrides,
      parent: parent,
      child: MaterialApp(
        navigatorKey: globalKey,
        theme: theme ?? mockLightThemeData,
        darkTheme: darkTheme ?? mockDarkThemeData,
        locale: locale,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: AppResponsiveLayout(
            mobile: child,
            desktop: child,
          ),
        ),
      ),
    );
