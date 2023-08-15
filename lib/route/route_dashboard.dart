part of 'router_provider.dart';

final dashboardRoute = ShellRoute(
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
          ),
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
            routes: [
              GoRoute(
                name: RouteNamed.wifiShareDetails,
                path: RoutePath.wifiShareDetails,
                builder: (context, state) => ShareWifiView(
                  args: state.uri.queryParameters,
                ),
              ),
            ],
          ),
        ]),
    GoRoute(
        name: RouteNamed.dashboardDevices,
        path: RoutePath.dashboardDevices,
        builder: (context, state) => DashboardDevices(),
        routes: [
          GoRoute(
            name: RouteNamed.deviceDetails,
            path: RoutePath.deviceDetails,
            builder: (context, state) => DeviceDetailView(),
          ),
        ]),
    GoRoute(
        name: RouteNamed.dashboardSettings,
        path: RoutePath.dashboardSettings,
        builder: (context, state) => DashboardSettingsView(),
        routes: settings)
  ],
);
