part of 'router_provider.dart';

final homeRoute = LinksysRoute(
  name: RouteNamed.home,
  path: RoutePath.home,
  config: LinksysRouteConfig(
    pageWidth: ColumnPageWidth(column: 9),
    pageAlignment: CrossAxisAlignment.center,
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
