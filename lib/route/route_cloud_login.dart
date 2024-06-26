part of 'router_provider.dart';

final cloudLoginRoute = LinksysRoute(
  name: RouteNamed.cloudLoginAccount,
  path: RoutePath.cloudLoginAccount,
  config: const LinksysRouteConfig(noNaviRail: true),
  builder: (context, state) =>
      LoginCloudView(args: state.extra as Map<String, dynamic>? ?? {}),
  routes: [
    ...otpRoutes,
    LinksysRoute(
      name: RouteNamed.phoneRegionCode,
      path: RoutePath.phoneRegionCode,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) =>
          RegionPickerView(args: state.extra as Map<String, dynamic>? ?? {}),
    ),
  ],
);
