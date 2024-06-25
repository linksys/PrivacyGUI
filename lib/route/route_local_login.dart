part of 'router_provider.dart';

final localLoginRoute = LinksysRoute(
  name: RouteNamed.localLoginPassword,
  path: RoutePath.localLoginPassword,
  config: const LinksysRouteConfig(noNaviRail: true),
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
          builder: (context, state) => LocalResetRouterPasswordView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ],
    ),
  ],
);
