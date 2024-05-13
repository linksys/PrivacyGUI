part of 'router_provider.dart';

final pnpRoute = LinksysRoute(
  name: RouteNamed.pnp,
  path: RoutePath.pnp,
  config: LinksysRouteConfig(pageWidth: SpecificPageWidth(width: 430)),
  builder: (context, state) => PnpAdminView(
    args: state.uri.queryParameters,
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpConfig,
      path: RoutePath.pnpConfig,
      config: LinksysRouteConfig(pageWidth: SpecificPageWidth(width: 430)),
      builder: (context, state) => const PnpSetupView(),
      routes: [],
    ),
  ],
);

final pnpTroubleshootingRoute = LinksysRoute(
  name: RouteNamed.pnpNoInternetConnection,
  path: RoutePath.pnpNoInternetConnection,
  config: LinksysRouteConfig(
    pageWidth: SpecificPageWidth(width: 430),
  ),
  builder: (context, state) => PnpNoInternetConnectionView(
    args: state.extra as Map<String, dynamic>? ?? {},
  ),
  routes: [
    LinksysRoute(
      name: RouteNamed.contactSupportChoose,
      path: RoutePath.contactSupportChoose,
      config: LinksysRouteConfig(
        pageWidth: SpecificPageWidth(width: 430),
      ),
      builder: (context, state) => const ContactSupportSelectionView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.contactSupportDetails,
          path: RoutePath.contactSupportDetails,
          config: LinksysRouteConfig(
            pageWidth: SpecificPageWidth(width: 430),
          ),
          builder: (context, state) => ContactSupportDetailView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        )
      ],
    ),
    LinksysRoute(
      name: RouteNamed.pnpUnplugModem,
      path: RoutePath.pnpUnplugModem,
      config: LinksysRouteConfig(
        pageWidth: SpecificPageWidth(width: 430),
      ),
      builder: (context, state) => const PnpUnplugModemView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpMakeSureLightOff,
          path: RoutePath.pnpMakeSureLightOff,
          config: LinksysRouteConfig(
            pageWidth: SpecificPageWidth(width: 430),
          ),
          builder: (context, state) => const PnpLightsOffView(),
          routes: [
            LinksysRoute(
              name: RouteNamed.pnpWaitingModem,
              path: RoutePath.pnpWaitingModem,
              config: LinksysRouteConfig(
                pageWidth: SpecificPageWidth(width: 430),
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
        pageWidth: SpecificPageWidth(width: 430),
      ),
      builder: (context, state) => const PnpIspTypeSelectionView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpStaticIp,
          path: RoutePath.pnpStaticIp,
          config: LinksysRouteConfig(
            pageWidth: SpecificPageWidth(width: 430),
          ),
          builder: (context, state) => const PnpStaticIpView(),
          routes: [
            LinksysRoute(
              name: RouteNamed.pnpIspSettingsAuth,
              path: RoutePath.pnpIspSettingsAuth,
              config: LinksysRouteConfig(
                pageWidth: SpecificPageWidth(width: 430),
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
            pageWidth: SpecificPageWidth(width: 430),
          ),
          builder: (context, state) => PnpPPPOEView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ],
    ),
  ],
);
