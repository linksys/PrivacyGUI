part of 'router_provider.dart';

final loginRoute = GoRoute(
  name: RouteNamed.cloudLoginAccount,
  path: RoutePath.cloudLoginAccount,
  builder: (context, state) => const CloudLoginAccountView(),
  routes: [
    GoRoute(
        name: RouteNamed.cloudLoginPassword,
        path: RoutePath.cloudLoginPassword,
        builder: (context, state) => CloudLoginPasswordView(
              args: state.uri.queryParameters,
            ),
        routes: [
          ...otpRoutes,
        ]),
  ],
);
