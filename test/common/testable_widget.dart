import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Assign a globalKey in order to retrieve current Build Context
GlobalKey<NavigatorState> globalKey = GlobalKey();

Widget testableWidget({
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? theme,
  ThemeData? darkTheme,
  Locale? locale,
}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        navigatorKey: globalKey,
        theme: theme ?? linksysLightThemeData,
        darkTheme: darkTheme ?? linksysDarkThemeData,
        locale: locale,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: CustomResponsive(
            child: child,
          ),
        ),
      ),
    );

Widget testableWidgetWithFont({
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  Locale? locale,
  required String fontFamily,
}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        navigatorKey: globalKey,
        theme: linksysLightThemeData,
        darkTheme: linksysDarkThemeData,
        locale: locale,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomResponsive(
            child: Material(
                textStyle: TextStyle(fontFamily: fontFamily), child: child),
          ),
        ),
      ),
    );
