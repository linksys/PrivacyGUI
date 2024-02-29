part of 'router_provider.dart';

final cloudLoginRoute = LinksysRoute(
  name: RouteNamed.cloudLoginAccount,
  path: RoutePath.cloudLoginAccount,
  config: const LinksysRouteConfig(fullWidth: true),
  builder: (context, state) => const LoginCloudView(),
  routes: [
    ...otpRoutes,
    LinksysRoute(
      name: RouteNamed.cloudForgotPassword,
      path: RoutePath.cloudForgotPassword,
      builder: (context, state) => CloudForgotPasswordView(
        args: state.uri.queryParameters,
      ),
    ),
    LinksysRoute(
      name: RouteNamed.phoneRegionCode,
      path: RoutePath.phoneRegionCode,
      builder: (context, state) => RegionPickerView(
        args: state.uri.queryParameters,
      ),
    ),
  ],
);
