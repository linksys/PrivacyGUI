import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

Widget testableRouter({
  required GoRouter router,
  ProviderContainer? provider,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? theme,
  ThemeData? darkTheme,
  Locale? locale,
}) {
  final appLightTheme = ThemeJsonConfig.defaultConfig().createLightTheme();
  final appDarkTheme = ThemeJsonConfig.defaultConfig().createDarkTheme();

  return ProviderScope(
    overrides: overrides,
    parent: provider,
    child: MaterialApp.router(
      theme: theme ?? appLightTheme,
      darkTheme: darkTheme ?? appDarkTheme,
      locale: locale,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Material(
        child: DesignSystem.init(
          context,
          AppResponsiveLayout(
            mobile: child ?? const SizedBox(),
            desktop: child ?? const SizedBox(),
          ),
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
