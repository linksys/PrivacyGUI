part of 'router_provider.dart';

final remoteAssistanceRoute = LinksysRoute(
  name: RouteNamed.remoteAssistanceConfirm,
  path: RoutePath.remoteAssistanceConfirm,
  config: LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: true),
  builder: (context, state) {
    final sessionId = state.uri.queryParameters['sessionId'] ?? '';
    return RemoteAssistanceConfirmView(sessionId: sessionId);
  },
);
