part of 'router_provider.dart';

final homeRoute = LinksysRoute(
  name: RouteNamed.home,
  path: RoutePath.home,
  config: LinksysRouteConfig(
    column: ColumnGrid(column: 9, centered: true),
  ),
  builder: (context, state) => const HomeView(),
  routes: [
    LinksysRoute(
      name: RouteNamed.debug,
      path: RoutePath.debug,
      builder: (context, state) => const DebugToolsView(),
    ),
    cloudLoginRoute,
    //setupRoute
  ],
);
