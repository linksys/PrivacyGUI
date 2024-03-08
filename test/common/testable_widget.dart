import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'test_localization.dart';

// Assign a globalKey in order to retrieve current Build Context
GlobalKey<NavigatorState> globalKey = GlobalKey();

GoRouter mockRouter(
        {required LinksysRoute initial,
        List<LinksysRoute> routes = const []}) =>
    GoRouter(
      navigatorKey: globalKey,
      initialLocation: initial.path,
      routes: [initial, ...routes],
    );

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
          body: CustomResponsive(
            child: child,
          ),
        ),
      ),
    );

Widget testableRouteWidget({
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? theme,
  ThemeData? darkTheme,
  Locale? locale,
}) {
  final router = mockRouter(
      initial: LinksysRoute(path: '/', builder: (context, state) => child));

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: theme ?? mockLightThemeData,
      darkTheme: darkTheme ?? mockDarkThemeData,
      locale: locale,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Material(
        child: CustomResponsive(
          child: child!,
        ),
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    ),
  );
}

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
