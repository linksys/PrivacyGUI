part of 'router_provider.dart';

final autoParentFirstLoginRoute = LinksysRoute(
  name: RouteNamed.autoParentFirstLogin,
  path: RoutePath.autoParentFirstLogin,
  config: const LinksysRouteConfig(noNaviRail: true),
  builder: (context, state) => const AutoParentFirstLoginView(),
);

final localLoginRoute = LinksysRoute(
  name: RouteNamed.localLoginPassword,
  path: RoutePath.localLoginPassword,
  config: LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: true),
  builder: (context, state) => LoginLocalView(
    args: state.extra as Map<String, dynamic>? ?? {},
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.localRouterRecovery,
      path: RoutePath.localRouterRecovery,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => const LocalRouterRecoveryView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.localPasswordReset,
          path: RoutePath.localPasswordReset,
          config: const LinksysRouteConfig(noNaviRail: true),
          builder: (context, state) => LocalResetRouterPasswordView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ],
    ),
    
  ],
);
