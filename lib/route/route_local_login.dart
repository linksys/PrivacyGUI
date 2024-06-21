part of 'router_provider.dart';

final localLoginRoute = LinksysRoute(
  name: RouteNamed.localLoginPassword,
  path: RoutePath.localLoginPassword,
  config: LinksysRouteConfig(
    pageWidth: FullPageWidth(),
    pageAlignment: CrossAxisAlignment.center,
  ),
  builder: (context, state) => LoginLocalView(
    args: state.extra as Map<String, dynamic>? ?? {},
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.localRouterRecovery,
      path: RoutePath.localRouterRecovery,
      config: LinksysRouteConfig(
        pageWidth: FullPageWidth(),
        pageAlignment: CrossAxisAlignment.center,
      ),
      builder: (context, state) => const LocalRouterRecoveryView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.localPasswordReset,
          path: RoutePath.localPasswordReset,
          config: LinksysRouteConfig(
            pageWidth: FullPageWidth(),
            pageAlignment: CrossAxisAlignment.center,
          ),
          builder: (context, state) => LocalResetRouterPasswordView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ],
    ),
  ],
);
