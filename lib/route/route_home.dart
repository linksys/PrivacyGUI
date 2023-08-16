part of 'router_provider.dart';

final homeRoute = GoRoute(
  name: RouteNamed.home,
  path: RoutePath.home,
  builder: (context, state) => const HomeView(),
  routes: [
    GoRoute(
      name: RouteNamed.debug,
      path: RoutePath.debug,
      builder: (context, state) => const HomeView(),
    ),
    loginRoute
    //setupRoute
  ],
);
