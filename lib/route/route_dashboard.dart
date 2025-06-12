part of 'router_provider.dart';

final shellNavigatorKey = GlobalKey<NavigatorState>();
final dashboardRoute = ShellRoute(
  navigatorKey: shellNavigatorKey,
  observers: [],
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
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => SpeedTestSelectionView(),
        ),
        LinksysRoute(
          name: RouteNamed.dashboardSpeedTest,
          path: RoutePath.dashboardSpeedTest,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => SpeedTestView(),
        ),
        LinksysRoute(
          name: RouteNamed.speedTestExternal,
          path: RoutePath.speedTestExternal,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => SpeedTestExternalView(),
        ),
        LinksysRoute(
          name: RouteNamed.troubleshooting,
          path: RoutePath.troubleshooting,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => TroubleshootingView(),
          routes: [
            LinksysRoute(
                name: RouteNamed.troubleshootingPing,
                path: RoutePath.troubleshootingPing,
                config: LinksysRouteConfig(
                  column: ColumnGrid(column: 9),
                ),
                builder: (context, state) => TroubleshootingPingView()),
          ],
        ),
        LinksysRoute(
          name: RouteNamed.settingsDDNS,
          path: RoutePath.settingsDDNS,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => DDNSSettingsView(),
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.dashboardSupport,
      path: RoutePath.dashboardSupport,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 12),
      ),
      builder: (context, state) => const FaqListView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.faqList,
          path: RoutePath.faqList,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => const FaqListView(),
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.dashboardModularApps,
      path: RoutePath.dashboardModularApps,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 12),
      ),
      builder: (context, state) => const ModularAppListView(),
    ),
  ],
);
