part of 'router_provider.dart';

final homeRoute = GoRoute(
  name: RouteNamed.home,
  path: RoutePath.home,
  builder: (context, state) => const HomeView(),
  routes: [
    GoRoute(
      name: RouteNamed.debug,
      path: RoutePath.debug,
      builder: (context, state) => const DebugToolsView(),
    ),
    loginRoute,
    GoRoute(
      name: RouteNamed.localLoginPassword,
      path: RoutePath.localLoginPassword,
      builder: (context, state) => EnterRouterPasswordView(
        args: state.uri.queryParameters,
      ),
    ),
    //setupRoute
  ],
);
