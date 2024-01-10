part of 'router_provider.dart';

final pnpRoute = LinksysRoute(
  name: RouteNamed.pnp,
  path: RoutePath.pnp,
  builder: (context, state) => const PnpSetupView(),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpNoInternetConnection,
      path: RoutePath.pnpNoInternetConnection,
      builder: (context, state) => const PnpNoInternetConnectionView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpUnplugModem,
          path: RoutePath.pnpUnplugModem,
          builder: (context, state) => const PnpUnplugModemView(),
          routes: [
            LinksysRoute(
              name: RouteNamed.pnpMakeSureLightOff,
              path: RoutePath.pnpMakeSureLightOff,
              builder: (context, state) => const PnpLightsOffView(),
              routes: [
                LinksysRoute(
                  name: RouteNamed.pnpWaitingModem,
                  path: RoutePath.pnpWaitingModem,
                  builder: (context, state) => const PnpWaitingModemView(),
                )
              ],
            )
          ],
        )
      ],
    ),
  ],
);
