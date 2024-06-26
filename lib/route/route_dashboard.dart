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
          LinksysRoute(
            name: RouteNamed.linkup,
            path: RoutePath.linkup,
            builder: (context, state) => LinkupView(),
          ),
          LinksysRoute(
            name: RouteNamed.safeBrowsing,
            path: RoutePath.safeBrowsing,
            config: LinksysRouteConfig(
              column: ColumnGrid(column: 9),
            ),
            builder: (context, state) => const SafeBrowsingView(),
          ),
          LinksysRoute(
            name: RouteNamed.dashboardAdvancedSettings,
            path: RoutePath.dashboardAdvancedSettings,
            config: LinksysRouteConfig(
              column: ColumnGrid(column: 9),
            ),
            builder: (context, state) => const DashboardAdvancedSettingsView(),
            routes: advancedSettings,
          ),
        ]),
    LinksysRoute(
      name: RouteNamed.dashboardHome,
      path: RoutePath.dashboardHome,
      builder: (context, state) => DashboardHomeView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.wifiShare,
          path: RoutePath.wifiShare,
          builder: (context, state) => WiFiShareTabView(),
        ),
        LinksysRoute(
          name: RouteNamed.dashboardDevices,
          path: RoutePath.dashboardDevices,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => DashboardDevices(),
          routes: [
            LinksysRoute(
              name: RouteNamed.deviceDetails,
              path: RoutePath.deviceDetails,
              config: LinksysRouteConfig(
                column: ColumnGrid(column: 12),
              ),
              builder: (context, state) => DeviceDetailView(),
            ),
          ],
        ),
        LinksysRoute(
            name: RouteNamed.dashboardSettings,
            path: RoutePath.dashboardSettings,
            config: LinksysRouteConfig(
              column: ColumnGrid(column: 9),
            ),
            builder: (context, state) => DashboardSettingsView(),
            routes: settings),
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
      builder: (context, state) => const DashboardSupportView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.faqList,
          path: RoutePath.faqList,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => const FaqListView(),
        ),
        LinksysRoute(
          name: RouteNamed.callbackDescription,
          path: RoutePath.callbackDescription,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => const CallbackView(),
        ),
      ],
    ),
  ],
);
