part of 'router_provider.dart';

final addNodesRoute = LinksysRoute(
  name: RouteNamed.addNodes,
  path: RoutePath.addNodes,
  config: LinksysRouteConfig(
      noNaviRail: true, column: ColumnGrid(column: 6, centered: true)),
  builder: (context, state) => AddNodesView(
    args: state.extra as Map<String, dynamic>? ?? {},
  ),
  routes: [],
);

