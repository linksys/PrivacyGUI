part of 'router_provider.dart';

final homeRoute = GoRoute(
  name: RouteNamed.home,
  path: RoutePath.home,
  builder: (context, state) => const HomeView(),
  routes: [
    loginRoute
    //setupRoute
  ],
);
