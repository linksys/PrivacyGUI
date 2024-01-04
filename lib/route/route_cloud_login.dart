part of 'router_provider.dart';

final cloudLoginRoute = LinksysRoute(
  name: RouteNamed.cloudLoginAccount,
  path: RoutePath.cloudLoginAccount,
  builder: (context, state) => const CloudLoginAccountView(),
  routes: [
    LinksysRoute(
      name: RouteNamed.cloudLoginPassword,
      path: RoutePath.cloudLoginPassword,
      builder: (context, state) => CloudLoginPasswordView(
        args: state.extra as Map<String, dynamic>? ?? {},
      ),
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
    ),
  ],
);
