part of 'router_provider.dart';

final pnpRoute = LinksysRoute(
  name: RouteNamed.pnp,
  path: RoutePath.pnp,
  config: LinksysRouteConfig(
    column: ColumnGrid(column: 6, centered: true),
  ),
  builder: (context, state) => PnpAdminView(
    args: state.uri.queryParameters,
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpConfig,
      path: RoutePath.pnpConfig,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
      ),
      builder: (context, state) => const PnpSetupView(),
      routes: [],
    ),
  ],
);

final pnpTroubleshootingRoute = LinksysRoute(
  name: RouteNamed.pnpNoInternetConnection,
  path: RoutePath.pnpNoInternetConnection,
  config: LinksysRouteConfig(
    column: ColumnGrid(column: 6, centered: true),
  ),
  builder: (context, state) => PnpNoInternetConnectionView(
    args: state.extra as Map<String, dynamic>? ?? {},
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.callSupportMainRegion,
      path: RoutePath.callSupportMainRegion,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 12),
      ),
      builder: (context, state) => const CallSupportMainRegionView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.callSupportMoreRegion,
          path: RoutePath.callSupportMoreRegion,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => CallSupportMoreRegionView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        )
      ],
    ),
    LinksysRoute(
      name: RouteNamed.pnpUnplugModem,
      path: RoutePath.pnpUnplugModem,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
      ),
      builder: (context, state) => const PnpUnplugModemView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpModemLightsOff,
          path: RoutePath.pnpModemLightsOff,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true),
          ),
          builder: (context, state) => const PnpModemLightsOffView(),
          routes: [
            LinksysRoute(
              name: RouteNamed.pnpWaitingModem,
              path: RoutePath.pnpWaitingModem,
              config: LinksysRouteConfig(
                column: ColumnGrid(column: 6, centered: true),
              ),
              builder: (context, state) => const PnpWaitingModemView(),
            )
          ],
        )
      ],
    ),
    LinksysRoute(
      name: RouteNamed.pnpIspTypeSelection,
      path: RoutePath.pnpIspTypeSelection,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
      ),
      builder: (context, state) => const PnpIspTypeSelectionView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpStaticIp,
          path: RoutePath.pnpStaticIp,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true),
          ),
          builder: (context, state) => const PnpStaticIpView(),
          routes: [
            LinksysRoute(
              name: RouteNamed.pnpIspSettingsAuth,
              path: RoutePath.pnpIspSettingsAuth,
              config: LinksysRouteConfig(
                column: ColumnGrid(column: 6, centered: true),
              ),
              builder: (context, state) => PnpIspSettingsAuthView(
                args: state.extra as Map<String, dynamic>? ?? {},
              ),
            )
          ],
        ),
        LinksysRoute(
          name: RouteNamed.pnpPPPOE,
          path: RoutePath.pnpPPPOE,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true),
          ),
          builder: (context, state) => PnpPPPOEView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ],
    ),
  ],
);
