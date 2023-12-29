part of 'router_provider.dart';

final shellNavigatorKey = GlobalKey<NavigatorState>();
final dashboardRoute = ShellRoute(
  navigatorKey: shellNavigatorKey,
  observers: [],
  builder: (BuildContext context, GoRouterState state, Widget child) =>
      DashboardShell(child: child),
  routes: [
    GoRoute(
        name: RouteNamed.dashboardMenu,
        path: RoutePath.dashboardMenu,
        builder: (context, state) => DashboardMenuView(),
        routes: [
          GoRoute(
              name: RouteNamed.accountInfo,
              path: RoutePath.accountInfo,
              builder: (context, state) => AccountView(),
              routes: [
                GoRoute(
                  name: RouteNamed.twoStepVerification,
                  path: RoutePath.twoStepVerification,
                  builder: (context, state) => TwoStepVerificationView(),
                ),
              ]),
          GoRoute(
            name: RouteNamed.linkup,
            path: RoutePath.linkup,
            builder: (context, state) => LinkupView(),
          )
        ]),
    GoRoute(
        name: RouteNamed.dashboardHome,
        path: RoutePath.dashboardHome,
        builder: (context, state) => DashboardHomeView(),
        routes: [
          GoRoute(
            name: RouteNamed.wifiShare,
            path: RoutePath.wifiShare,
            builder: (context, state) => WifiListView(),
          ),
          GoRoute(
            name: RouteNamed.dashboardDevices,
            path: RoutePath.dashboardDevices,
            builder: (context, state) => DashboardDevices(),
            routes: [
              GoRoute(
                  name: RouteNamed.deviceDetails,
                  path: RoutePath.deviceDetails,
                  builder: (context, state) => DeviceDetailView(),
                  routes: [
                    GoRoute(
                        name: RouteNamed.changeDeviceName,
                        path: RoutePath.changeDeviceName,
                        builder: (context, state) => ChangeDeviceNameView()),
                    GoRoute(
                        name: RouteNamed.changeDeviceAvatar,
                        path: RoutePath.changeDeviceAvatar,
                        builder: (context, state) => ChangeDeviceAvatarView()),
                    GoRoute(
                        name: RouteNamed.offlineDevices,
                        path: RoutePath.offlineDevices,
                        builder: (context, state) => OfflineDevicesView()),
                  ]),
            ],
          ),
          GoRoute(
              name: RouteNamed.dashboardSettings,
              path: RoutePath.dashboardSettings,
              builder: (context, state) => DashboardSettingsView(),
              routes: settings),
          GoRoute(
            name: RouteNamed.dashboardSpeedTest,
            path: RoutePath.dashboardSpeedTest,
            builder: (context, state) => SpeedTestView(),
          )
        ]),
  ],
);
