part of 'router_provider.dart';

final dashboardRoute = ShellRoute(
  builder: (BuildContext context, GoRouterState state, Widget child) =>
      DashboardShell(child: child),
  routes: [
    GoRoute(
      name: RouteNamed.dashboardMenu,
      path: RoutePath.dashboardMenu,
      builder: (context, state) => DashboardMenuView(),
    ),
    GoRoute(
      name: RouteNamed.dashboardHome,
      path: RoutePath.dashboardHome,
      builder: (context, state) => DashboardHomeView(),
    ),
    GoRoute(
      name: RouteNamed.dashboardDevices,
      path: RoutePath.dashboardDevices,
      builder: (context, state) => DashboardDevices(),
    ),
    GoRoute(
        name: RouteNamed.dashboardSettings,
        path: RoutePath.dashboardSettings,
        builder: (context, state) => DashboardSettingsView(),
        routes: settings)
  ],
);
