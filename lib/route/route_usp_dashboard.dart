part of 'router_provider.dart';

final uspShellNavigatorKey = GlobalKey<NavigatorState>();

final uspDashboardRoute = ShellRoute(
  navigatorKey: uspShellNavigatorKey,
  builder: (BuildContext context, GoRouterState state, Widget child) =>
      UspDashboardShell(child: child),
  routes: [
    LinksysRoute(
      name: RouteNamed.uspDashboard,
      path: RoutePath.uspDashboard,
      builder: (context, state) => const UspDashboardView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspMenu,
      path: RoutePath.uspMenu,
      builder: (context, state) => const UspMenuView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspSupport,
      path: RoutePath.uspSupport,
      builder: (context, state) => const UspSupportView(),
    ),
  ],
);
