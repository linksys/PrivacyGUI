part of 'router_provider.dart';

final _pnpRouteConfig = LinksysRouteConfig(
  column: ColumnGrid(column: 9, centered: true),
  noNaviRail: true,
);

final pnpRoute = LinksysRoute(
  name: RouteNamed.pnp,
  path: RoutePath.pnp,
  config: _pnpRouteConfig,
  builder: (context, state) => const PnpEntryView(),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpConfig,
      path: RoutePath.pnpConfig,
      config: _pnpRouteConfig,
      builder: (context, state) => const PnpSetupView(),
    ),
  ],
);

final pnpNoInternetRoute = LinksysRoute(
  name: RouteNamed.pnpNoInternetConnection,
  path: RoutePath.pnpNoInternetConnection,
  config: _pnpRouteConfig,
  builder: (context, state) => const PnpNoInternetView(),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpIspTypeSelection,
      path: RoutePath.pnpIspTypeSelection,
      config: _pnpRouteConfig,
      builder: (context, state) => const PnpIspSettingsView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpPPPOE,
          path: RoutePath.pnpPPPOE,
          config: _pnpRouteConfig,
          builder: (context, state) => const PnpPppoeView(),
        ),
        LinksysRoute(
          name: RouteNamed.pnpStaticIp,
          path: RoutePath.pnpStaticIp,
          config: _pnpRouteConfig,
          builder: (context, state) => const PnpStaticIpView(),
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.pnpUnplugModem,
      path: RoutePath.pnpUnplugModem,
      config: _pnpRouteConfig,
      builder: (context, state) => const PnpUnplugModemView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpModemLightsOff,
          path: RoutePath.pnpModemLightsOff,
          config: _pnpRouteConfig,
          builder: (context, state) => const PnpModemLightsOffView(),
          routes: [
            LinksysRoute(
              name: RouteNamed.pnpWaitingModem,
              path: RoutePath.pnpWaitingModem,
              config: _pnpRouteConfig,
              builder: (context, state) => const PnpWaitingModemView(),
            ),
          ],
        ),
      ],
    ),
  ],
);
