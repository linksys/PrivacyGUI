part of 'router_provider.dart';

final pnpRoute = LinksysRoute(
  name: RouteNamed.pnp,
  path: RoutePath.pnp,
  config: LinksysRouteConfig(
    column: ColumnGrid(column: 9, centered: true),
    noNaviRail: true,
  ),
  builder: (context, state) => const PnpAdminView(),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpConfig,
      path: RoutePath.pnpConfig,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9, centered: true),
        noNaviRail: true,
      ),
      builder: (context, state) => const PnpSetupView(),
    ),
  ],
);

final pnpNoInternetRoute = LinksysRoute(
  name: RouteNamed.pnpNoInternetConnection,
  path: RoutePath.pnpNoInternetConnection,
  config: LinksysRouteConfig(
    column: ColumnGrid(column: 9, centered: true),
    noNaviRail: true,
  ),
  builder: (context, state) => const PnpNoInternetView(),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpIspTypeSelection,
      path: RoutePath.pnpIspTypeSelection,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => const PnpIspSettingsView(),
    ),
  ],
);
