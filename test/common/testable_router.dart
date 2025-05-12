import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/theme/custom_responsive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'testable_widget.dart';
import 'theme.dart';

Widget testableRouter({
  required GoRouter router,
  ProviderContainer? provider,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? theme,
  ThemeData? darkTheme,
  Locale? locale,
}) {
  return ProviderScope(
    overrides: overrides,
    parent: provider,
    child: MaterialApp.router(
      theme: theme ?? linksysLightThemeData,
      darkTheme: darkTheme ?? linksysDarkThemeData,
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

Widget testableSingleRoute({
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? theme,
  ThemeData? darkTheme,
  LinksysRouteConfig? config,
  Locale? locale,
  ProviderContainer? provider,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final router = GoRouter(
    navigatorKey: navigatorKey ?? shellNavigatorKey,
    initialLocation: '/',
    routes: [
      LinksysRoute(
        path: '/',
        config: config,
        builder: (context, state) => child,
      ),
    ],
  );

  return testableRouter(
    router: router,
    overrides: overrides,
    themeMode: themeMode,
    theme: theme,
    darkTheme: darkTheme,
    locale: locale,
    provider: provider,
  );
}

Widget testableRouteShellWidget({
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  LinksysRouteConfig? config,
  ThemeData? theme,
  ThemeData? darkTheme,
  Locale? locale,
}) {
  final router = GoRouter(
    navigatorKey: shellNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) =>
              DashboardShell(child: child),
          routes: [
            LinksysRoute(
              name: '/',
              path: '/',
              config: config,
              builder: (context, state) => child,
            ),
          ])
    ],
  );

  return testableRouter(
    router: router,
    overrides: overrides,
    themeMode: themeMode,
    theme: theme,
    darkTheme: darkTheme,
    locale: locale,
  );
}
