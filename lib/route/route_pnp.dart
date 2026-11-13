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
/// **No `loggedOut` escape, unlike `_firmwareExitGuard`.** That guard releases on
/// a sign-out because the router's `redirect` `go`es a signed-out user to the login
/// page and the leaving match is a `/usp*` one. Nothing does that here, measured
/// twice: `redirect` returns `state.uri.toString()` for every `/pnp*` location — the
/// wizard is not auth-gated — and the only wiring of `listenForCoreSessionExit` is
/// in `usp_dashboard_shell.dart`, so while the wizard is on screen a
/// core-reported session exit is not even carried out. The same condition written
/// here would be a check that never fires, which is the mistake this file's
/// `onBackTap` note already records once.
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

/// One shell over the PnP flow (#1511 P2) — the `/pnp` tree, and only it.
///
/// [PnpFlowShell] owns the flow's phase→page mapping, and a shell's widget is not
/// rebuilt while the user moves between its children, so it sees every phase
/// change for as long as the user is in the flow. The no-internet troubleshooting
/// tree ([pnpNoInternetRoute]) is deliberately outside it: it has state of its own
/// and more than one caller (#1511 P1).
///
/// No `navigatorKey`, unlike `uspDashboardRoute`: nothing pushes onto this
/// navigator from outside, so go_router's own key is enough.
final pnpShellRoute = ShellRoute(
  builder: (context, state, child) => PnpFlowShell(child: child),
  routes: [pnpRoute],
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
      onExit: _pnpFirmwareExitGuard,
      routes: [
        // A child of the wizard, so it is pushed over it and pops back to the
        // step it was opened from (#1734). Named pnpAddNodes, which
        // idleCheckWhiteList exempts: a session can outlast the idle window.
        LinksysRoute(
          name: RouteNamed.pnpAddNodes,
          path: RoutePath.pnpAddNodes,
          config: _pnpRouteConfig,
          builder: (context, state) => const PnpAddNodesView(),
        ),
      ],
    ),
  ],
);

/// The dashboard's ending: back to the dashboard, and no "continue without
/// internet" — there is no setup to acknowledge (#1511 P1).
///
/// Declared here rather than beside a dashboard entry because none ships yet; the
/// route accepts the caller so that a second caller exists and is tested. It moves
/// to the dashboard with that entry.
const _dashboardTroubleshootingEnding = TroubleshootingEnding(
  exitLocation: RoutePath.uspDashboard,
);

/// The ending the URL's `:caller` names, or `null` for a caller nobody supplies.
///
/// The one place a caller id becomes behaviour, so the troubleshooting pages are
/// handed an ending and never see the id. Two pages take one: the hub, which sits
/// under every other page of the tree and so is the one that hands a finished run
/// over, and Auto-IPoE, whose "continue" ends the run without a phase change.
TroubleshootingEnding? _troubleshootingEnding(
  BuildContext context,
  GoRouterState state,
) =>
    switch (state.pathParameters[TroubleshootingCaller.param]) {
      TroubleshootingCaller.pnp => ProviderScope.containerOf(context)
          .read(pnpTroubleshootingEndingProvider),
      TroubleshootingCaller.dashboard => _dashboardTroubleshootingEnding,
      _ => null,
    };

/// [_troubleshootingEnding] for a page builder. Non-null by construction: the
/// tree's root redirects an unknown caller before any page in it is built, and
/// route-level redirects run for every match, parents first.
TroubleshootingEnding _endingOf(BuildContext context, GoRouterState state) =>
    _troubleshootingEnding(context, state)!;

Future<bool> _pnpAutoIPoEExitGuard(
    BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  if (!container
      .read(deviceCapabilitiesProvider)
      .has(DeviceCapability.autoIPoE)) return true;
  final guard = container.read(autoIPoEPnpExitGuardProvider);
  return await guard.onExit?.call() ?? false;
}

final pnpNoInternetRoute = LinksysRoute(
  name: RouteNamed.pnpNoInternetConnection,
  path: RoutePath.pnpNoInternetConnection,
  config: _pnpRouteConfig,
  // A caller nobody supplies has no ending to hand over to, so the app starts
  // again from its own entry, which decides where this router belongs.
  redirect: (context, state) =>
      _troubleshootingEnding(context, state) == null ? '/' : null,
  builder: (context, state) =>
      PnpNoInternetView(ending: _endingOf(context, state)),
  routes: [
    LinksysRoute(
      name: RouteNamed.pnpIspTypeSelection,
      path: RoutePath.pnpIspTypeSelection,
      config: _pnpRouteConfig,
      builder: (context, state) => const PnpIspSettingsView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.pnpAutoIPoE,
          path: RoutePath.pnpAutoIPoE,
          config: _pnpRouteConfig,
          redirect: (context, state) {
            final capabilities = ProviderScope.containerOf(context)
                .read(deviceCapabilitiesProvider);
            return capabilities.has(DeviceCapability.autoIPoE)
                ? null
                : context.namedLocation(
                    RouteNamed.pnpIspTypeSelection,
                    pathParameters: state.pathParameters,
                  );
          },
          builder: (context, state) =>
              PnpIPoEView(ending: _endingOf(context, state)),
          onExit: _pnpAutoIPoEExitGuard,
          preservableProvider: autoIPoEPageProvider.notifier,
        ),
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
