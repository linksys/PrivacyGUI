part of 'router_provider.dart';

final _pnpRouteConfig = LinksysRouteConfig(
  column: ColumnGrid(column: 9, centered: true),
  noNaviRail: true,
);

/// Refuses to leave the setup wizard while the firmware stage owns it (REQ-B2).
///
/// **This is the whole lock, and the only one.** `PnpSetupView` renders with
/// `appBarStyle: UiKitAppBarStyle.none`, and `UiKitPageView._buildAppBarConfig()`
/// returns null for that style before it reaches the one line that consumes
/// `onBackTap` — so the page's `onBackTap` closure never runs, and a phase check
/// added there would be dead code. What makes the phase unleavable is this guard
/// (browser Back and any `go`, both of which consult `onExit`) plus the fact that
/// `_buildFirmwareUpdate` renders no button at all.
///
/// **Two phases, not one.** `WizardUpdatingFirmware` is the flash. The reason
/// `WizardCheckingFirmware` is here too is a race rather than a screen: a pop
/// during the check lands on `PnpEntryView`, whose `initState` calls
/// `startPostLoginFlow()` and overwrites `state.phase` — while `_checkFirmware` is
/// still awaiting an answer that may be "an update is available", at which point it
/// writes `WizardUpdatingFirmware` over that flow and dispatches a flash. Two
/// writers, one phase, and a router being written to with the locked screen never
/// shown. The window is bounded by `pnpFirmwareCheckDeadlineProvider` (15 s) and
/// the phase renders a spinner with nothing to press, so what is being refused is
/// a Back press during a wait the user cannot shorten either way.
///
/// Keyed on the **PnP phase**, not on `firmwareUpdateNotifierProvider.isUpdating`
/// like `_firmwareExitGuard` is. The two answer different questions: the firmware
/// pages ask "is an install running", whereas this asks "is this wizard the thing
/// running it" — an update the user started on the dashboard before entering setup
/// must not lock the wizard, and `isUpdating` cannot tell the two apart.
Future<bool> _pnpFirmwareExitGuard(
    BuildContext context, GoRouterState state) async {
  final phase = ProviderScope.containerOf(context).read(pnpProvider).phase;
  return phase is! WizardUpdatingFirmware && phase is! WizardCheckingFirmware;
}

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
      onExit: _pnpFirmwareExitGuard,
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
