part of 'router_provider.dart';

final cloudLoginRoute = LinksysRoute(
  name: RouteNamed.cloudLoginAccount,
  path: RoutePath.cloudLoginAccount,
  builder: (context, state) =>
      LoginCloudView(args: state.extra as Map<String, dynamic>? ?? {}),
  routes: [
    ...otpRoutes,
    LinksysRoute(
      name: RouteNamed.phoneRegionCode,
      path: RoutePath.phoneRegionCode,
      builder: (context, state) =>
          RegionPickerView(args: state.extra as Map<String, dynamic>? ?? {}),
    ),
  ],
);
