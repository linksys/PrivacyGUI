part of 'router_provider.dart';

final localLoginRoute = LinksysRoute(
  name: RouteNamed.localLoginPassword,
  path: RoutePath.localLoginPassword,
  config:  LinksysRouteConfig(pageWidth: FullPageWidth()),
  builder: (context, state) => LoginLocalView(
    args: state.extra as Map<String, dynamic>? ?? {},
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.localRouterRecovery,
      path: RoutePath.localRouterRecovery,
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