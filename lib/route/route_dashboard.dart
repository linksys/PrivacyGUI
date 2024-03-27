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
              name: RouteNamed.accountInfo,
              path: RoutePath.accountInfo,
              builder: (context, state) => AccountView(),
              routes: [
                LinksysRoute(
                  name: RouteNamed.twoStepVerification,
                  path: RoutePath.twoStepVerification,
                  builder: (context, state) => TwoStepVerificationView(),
                ),
              ]),
          LinksysRoute(
            name: RouteNamed.linkup,
            path: RoutePath.linkup,
            builder: (context, state) => LinkupView(),
          ),
          LinksysRoute(
            name: RouteNamed.safeBrowsing,
            path: RoutePath.safeBrowsing,
            config: const LinksysRouteConfig(pageAlignment: CrossAxisAlignment.start),
            builder: (context, state) => const SafeBrowsingView(),
          )
        ]),
    LinksysRoute(
      name: RouteNamed.dashboardHome,
      path: RoutePath.dashboardHome,
      builder: (context, state) => DashboardHomeView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.wifiShare,
          path: RoutePath.wifiShare,
          builder: (context, state) => WifiListView(),
        ),
        LinksysRoute(
          name: RouteNamed.dashboardDevices,
          path: RoutePath.dashboardDevices,
          builder: (context, state) => DashboardDevices(),
          routes: [
            LinksysRoute(
                name: RouteNamed.deviceDetails,
                path: RoutePath.deviceDetails,
                builder: (context, state) => DeviceDetailView(),
                routes: [
                  LinksysRoute(
                      name: RouteNamed.changeDeviceName,
                      path: RoutePath.changeDeviceName,
                      builder: (context, state) => ChangeDeviceNameView()),
                  LinksysRoute(
                      name: RouteNamed.changeDeviceAvatar,
                      path: RoutePath.changeDeviceAvatar,
                      builder: (context, state) => ChangeDeviceAvatarView()),
                  LinksysRoute(
                      name: RouteNamed.offlineDevices,
                      path: RoutePath.offlineDevices,
                      builder: (context, state) => OfflineDevicesView()),
                ]),
          ],
        ),
        LinksysRoute(
            name: RouteNamed.dashboardSettings,
            path: RoutePath.dashboardSettings,
            builder: (context, state) => DashboardSettingsView(),
            routes: settings),
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
          name: RouteNamed.troubleshooting,
          path: RoutePath.troubleshooting,
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
      builder: (context, state) => DashboardSupportView(),
    ),
  ],
);
