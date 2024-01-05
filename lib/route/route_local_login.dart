part of 'router_provider.dart';

final localLoginRoute = GoRoute(
  name: RouteNamed.localLoginPassword,
  path: RoutePath.localLoginPassword,
  builder: (context, state) => EnterRouterPasswordView(
    args: state.uri.queryParameters,
  ),
  routes: [
    GoRoute(
      name: RouteNamed.localRouterRecovery,
      path: RoutePath.localRouterRecovery,
      builder: (context, state) => LocalRouterRecoveryView(),
      routes: [
        GoRoute(
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
