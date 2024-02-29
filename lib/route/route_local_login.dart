part of 'router_provider.dart';

final localLoginRoute = LinksysRoute(
  name: RouteNamed.localLoginPassword,
  path: RoutePath.localLoginPassword,
  config: const LinksysRouteConfig(fullWidth: true),
  builder: (context, state) => LoginView(
    args: state.extra as Map<String, dynamic>? ?? {},
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.localRouterRecovery,
      path: RoutePath.localRouterRecovery,
      builder: (context, state) => LocalRouterRecoveryView(),
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
