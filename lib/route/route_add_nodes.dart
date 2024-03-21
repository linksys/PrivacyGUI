part of 'router_provider.dart';

final addNodesRoute = LinksysRoute(
  name: RouteNamed.addNodes,
  path: RoutePath.addNodes,
  config: LinksysRouteConfig(
      noNaviRail: true, pageWidth: SpecificPageWidth(width: 488)),
  builder: (context, state) => AddNodesView(
    args: state.uri.queryParameters,
  ),
  routes: [],
);
