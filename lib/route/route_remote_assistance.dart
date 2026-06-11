part of 'router_provider.dart';

final remoteAssistanceRoute = LinksysRoute(
  name: RouteNamed.remoteAssistanceConfirm,
  path: RoutePath.remoteAssistanceConfirm,
  config: LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: true),
  builder: (context, state) {
    // Accept both sessionId and sessionID (case-insensitive)
    final sessionId = state.uri.queryParameters['sessionId'] ??
        state.uri.queryParameters['sessionID'] ??
        '';
    final token = state.uri.queryParameters['token'] ?? '';
    final ended = state.uri.queryParameters['ended'] == 'true';
    return RemoteAssistanceConfirmView(
      sessionId: sessionId,
      token: token,
      sessionEnded: ended,
    );
  },
);
