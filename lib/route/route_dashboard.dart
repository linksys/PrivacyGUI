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
        config: LinksysRouteConfig(
            pageWidth: ColumnPageWidth(column: 9),
            pageAlignment: CrossAxisAlignment.start),
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
                pageWidth: ColumnPageWidth(column: 9),
                pageAlignment: CrossAxisAlignment.start),
            builder: (context, state) => const SafeBrowsingView(),
          ),
          LinksysRoute(
            name: RouteNamed.dashboardAdvancedSettings,
            path: RoutePath.dashboardAdvancedSettings,
            config: LinksysRouteConfig(
                pageWidth: ColumnPageWidth(column: 9),
                pageAlignment: CrossAxisAlignment.start),
            builder: (context, state) => const DashboardAdvancedSettingsView(),
            routes: advancedSettings,
          ),
        ]),
    LinksysRoute(
      name: RouteNamed.dashboardHome,
      path: RoutePath.dashboardHome,
      config: LinksysRouteConfig(
          pageWidth: ColumnPageWidth(column: 12),
          pageAlignment: CrossAxisAlignment.start),
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
              pageWidth: ColumnPageWidth(column: 9),
              pageAlignment: CrossAxisAlignment.start),
          builder: (context, state) => DashboardDevices(),
          routes: [
            LinksysRoute(
              name: RouteNamed.deviceDetails,
              path: RoutePath.deviceDetails,
              config: LinksysRouteConfig(
                  pageWidth: ColumnPageWidth(column: 9),
                  pageAlignment: CrossAxisAlignment.start),
              builder: (context, state) => DeviceDetailView(),
            ),
          ],
        ),
        LinksysRoute(
            name: RouteNamed.dashboardSettings,
            path: RoutePath.dashboardSettings,
            config: LinksysRouteConfig(
                pageWidth: ColumnPageWidth(column: 9),
                pageAlignment: CrossAxisAlignment.start),
            builder: (context, state) => DashboardSettingsView(),
            routes: settings),
        LinksysRoute(
          name: RouteNamed.speedTestSelection,
          path: RoutePath.speedTestSelection,
          config: LinksysRouteConfig(
              pageWidth: ColumnPageWidth(column: 9),
              pageAlignment: CrossAxisAlignment.start),
          builder: (context, state) => SpeedTestSelectionView(),
        ),
        LinksysRoute(
          name: RouteNamed.dashboardSpeedTest,
          path: RoutePath.dashboardSpeedTest,
          config: LinksysRouteConfig(
              pageWidth: ColumnPageWidth(column: 9),
              pageAlignment: CrossAxisAlignment.start),
          builder: (context, state) => SpeedTestView(),
        ),
        LinksysRoute(
          name: RouteNamed.speedTestExternal,
          path: RoutePath.speedTestExternal,
          config: LinksysRouteConfig(
              pageWidth: ColumnPageWidth(column: 9),
              pageAlignment: CrossAxisAlignment.start),
          builder: (context, state) => SpeedTestExternalView(),
        ),
        LinksysRoute(
          name: RouteNamed.troubleshooting,
          path: RoutePath.troubleshooting,
          config: LinksysRouteConfig(
              pageWidth: ColumnPageWidth(column: 9),
              pageAlignment: CrossAxisAlignment.start),
          builder: (context, state) => TroubleshootingView(),
          routes: [
            LinksysRoute(
                name: RouteNamed.troubleshootingPing,
                path: RoutePath.troubleshootingPing,
                builder: (context, state) => TroubleshootingPingView()),
          ],
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
      config: LinksysRouteConfig(
        pageWidth: ColumnPageWidth(column: 9),
        pageAlignment: CrossAxisAlignment.start,
      ),
      builder: (context, state) => const DashboardSupportView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.faqList,
          path: RoutePath.faqList,
          config: LinksysRouteConfig(
            pageWidth: ColumnPageWidth(column: 9),
            pageAlignment: CrossAxisAlignment.start,
          ),
          builder: (context, state) => const FaqListView(),
        ),
        LinksysRoute(
          name: RouteNamed.callbackDescription,
          path: RoutePath.callbackDescription,
          config: LinksysRouteConfig(
            pageWidth: ColumnPageWidth(column: 9),
            pageAlignment: CrossAxisAlignment.start,
          ),
          builder: (context, state) => const CallbackView(),
        ),
      ],
    ),
  ],
);
