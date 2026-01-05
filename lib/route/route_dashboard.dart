part of 'router_provider.dart';

final shellNavigatorKey = GlobalKey<NavigatorState>();
final dashboardRoute = ShellRoute(
  navigatorKey: shellNavigatorKey,
  observers: const [],
  builder: (BuildContext context, GoRouterState state, Widget child) =>
      DashboardShell(
    child: child,
  ),
  routes: [
    LinksysRoute(
        name: RouteNamed.dashboardMenu,
        path: RoutePath.dashboardMenu,
        builder: (context, state) => DashboardMenuView(),
        routes: [
          ...menus,
        ]),
    LinksysRoute(
      name: RouteNamed.dashboardHome,
      path: RoutePath.dashboardHome,
      builder: (context, state) => DashboardHomeView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.speedTestSelection,
          path: RoutePath.speedTestSelection,
          builder: (context, state) => SpeedTestSelectionView(),
        ),
        LinksysRoute(
          name: RouteNamed.dashboardSpeedTest,
          path: RoutePath.dashboardSpeedTest,
          builder: (context, state) => SpeedTestView(),
        ),
        LinksysRoute(
          name: RouteNamed.speedTestExternal,
          path: RoutePath.speedTestExternal,
          builder: (context, state) => SpeedTestExternalView(),
        ),
        LinksysRoute(
          name: RouteNamed.settingsDDNS,
          path: RoutePath.settingsDDNS,
          builder: (context, state) => DDNSSettingsView(),
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.dashboardSupport,
      path: RoutePath.dashboardSupport,
      builder: (context, state) => const FaqListView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.faqList,
          path: RoutePath.faqList,
          builder: (context, state) => const FaqListView(),
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.dashboardAiAssistant,
      path: RoutePath.dashboardAiAssistant,
      builder: (context, state) => const RouterAssistantView(),
    ),
  ],
);
