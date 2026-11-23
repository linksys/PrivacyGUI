part of 'router_provider.dart';

final cloudLoginAuthRoute = LinksysRoute(
  name: RouteNamed.cloudLoginAuth,
  path: RoutePath.cloudLoginAuth,
  config: const LinksysRouteConfig(noNaviRail: true),
  builder: (context, state) => LoginCloudAuthView(
      args: state.extra as Map<String, dynamic>? ?? {}
        ..addAll(state.extra as Map<String, dynamic>? ?? <String, dynamic>{})
        ..addAll(state.uri.queryParameters)),
);
