part of 'router_provider.dart';

final homeRoute = LinksysRoute(
  name: RouteNamed.home,
  path: RoutePath.home,
  config: LinksysRouteConfig(
    column: ColumnGrid(column: 9, centered: true),
  ),
  // The router redirects every visit to `/` (the local login, the Guardian
  // login, PnP or the dashboard), so this never shows (#1849).
  builder: (context, state) => const SizedBox.shrink(),
);
