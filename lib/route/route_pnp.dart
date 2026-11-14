part of 'router_provider.dart';

final _pnpRouteConfig = LinksysRouteConfig(
  column: ColumnGrid(column: 9, centered: true),
  noNaviRail: true,
);

/// Whether the user may leave the setup wizard — `/pnp/pnpConfig`'s `onExit`.
///
/// It fires only when the user leaves the **whole** wizard: `pnpConfig` stays
/// matched while the steps under it change (spike S1). Where the user is going
/// is the shell's back policy's to judge (`pnpBackPolicy`, which sees the
/// destination); this guard, which does not, decides by the flow's phase:
///
/// - **The firmware stage — locked (REQ-B2).** `WizardUpdatingFirmware` is the
///   flash. `WizardCheckingFirmware` is here for a race rather than a screen:
///   leaving during the check would end the flow while `_checkFirmware` may
///   still be about to dispatch a flash. Keyed on the PnP phase, not on
///   `firmwareUpdateNotifierProvider.isUpdating` like `_firmwareExitGuard`: an
///   update the user started on the dashboard before entering setup must not
///   lock the wizard.
/// - **In flight — refused** (`WizardSaving`, `WizardSaved`,
///   `WizardTestingReconnect`): a write or a reconnect is out, and leaving now
///   would end the flow under it (D7).
/// - **Editing — leaving the setup is logging out** (#1511 P4; Austin,
///   2026-11-13). Back from the first step lands here. It asks; on "Log out"
///   the drafts are reverted — the flow-level dirty guard's revert — and the
///   user is signed out and sent to the login page.
/// - **Anything else** — the completion screen's Done above all — leaves, and
///   then the flow-level dirty guard (`preservableProvider`) asks only if a
///   draft is still dirty, which after a save that landed none is.
///
/// **No `loggedOut` escape for the lock**, unlike `_firmwareExitGuard`: the
/// `/pnp*` redirect passes every location through, and the only wiring of
/// `listenForCoreSessionExit` is in `usp_dashboard_shell.dart`, so nothing signs
/// a user out from under the firmware stage. The editing branch lets one
/// navigation through without asking, its own to the login page
/// ([_pnpLeavingForLoginProvider]).
Future<bool> _pnpWizardExitGuard(
    BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  // Exhaustive on purpose: a phase added later must be decided here, not let
  // out by a `default`.
  switch (container.read(pnpProvider).phase) {
    case WizardUpdatingFirmware() || WizardCheckingFirmware():
      return false;
    case WizardSaving() || WizardSaved() || WizardTestingReconnect():
      return false;
    case WizardConfiguring():
      return _leaveSetupByLoggingOut(context, container);
    case AdminCheckingInternet() ||
          AdminInternetConnected() ||
          AdminReadFailure() ||
          NoInternet() ||
          WizardInitializing() ||
          WizardNeedsReconnect() ||
          WizardWifiReady() ||
          WizardError():
      return true;
  }
}

/// Set just before the editing branch's own `go` to the login page, and taken
/// back by the guard that lets it through.
///
/// A flag rather than "signed out": the session can be gone before the user
/// leaves (the demo build's auth always reads signed out), and a Back from the
/// first step then went straight to the entry, which shows only a spinner for a
/// flow past its checks (real browser, 2026-11-13).
final _pnpLeavingForLoginProvider = StateProvider<bool>((ref) => false);

/// The editing branch of [_pnpWizardExitGuard]: ask, and on "Log out" sign the
/// user out to the login page.
///
/// Always refuses the navigation it was asked about and goes to the login page
/// itself, after this one has been settled: a `go` started while go_router is
/// still waiting on this guard would race it. That `go` comes back through
/// here, and [_pnpLeavingForLoginProvider] is what lets it pass.
Future<bool> _leaveSetupByLoggingOut(
  BuildContext context,
  ProviderContainer container,
) async {
  final leaving = container.read(_pnpLeavingForLoginProvider.notifier);
  if (leaving.state) {
    leaving.state = false;
    return true;
  }
  final logOut = await showPnpLeaveSetupAlert(context);
  if (logOut != true) return false;
  container.read(pnpWizardDraftsProvider).revert();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await container
        .read(authProvider.notifier)
        .logout(cause: EndCause.userRequested);
    leaving.state = true;
    container.read(routerProvider).go(RoutePath.localLoginPassword);
  });
  return false;
}

/// The shell's `redirect`: the back policy, [pnpBackPolicy], over every
/// navigation into the `/pnp` tree.
///
/// Reads the flow only when there is one (spike S3). With none, the answer is
/// the policy's "no plan yet" row, and reading the `autoDispose` provider just
/// to find that out would create an instance Riverpod then drops — harmless
/// while `PnpNotifier.build()` stays side-effect free, but nothing to rely on.
String? _pnpShellRedirect(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context);
  final flow = container.exists(pnpProvider)
      ? container.read(pnpProvider)
      : PnpState.initial();
  return pnpBackPolicy(flow, state.uri);
}

/// One shell over the PnP flow (#1511 P2) — the `/pnp` tree, and only it.
///
/// [PnpFlowShell] owns the flow's phase→page mapping, its lifetime (#1511 P3)
/// and the frame around its pages — top bar, stepper, status screens (P4) —
/// and its `redirect` is the back policy. A shell's widget is not rebuilt while
/// the user moves between its children, so it sees every phase change for as
/// long as the user is in the flow. The no-internet troubleshooting tree
/// ([pnpNoInternetRoute]) is deliberately outside it: it has state of its own
/// and more than one caller (#1511 P1).
///
/// No `navigatorKey`, unlike `uspDashboardRoute`: what is pushed over the
/// wizard (adding nodes) goes to the root navigator.
final pnpShellRoute = ShellRoute(
  redirect: _pnpShellRedirect,
  builder: (context, state, child) =>
      PnpFlowShell(location: state.uri, child: child),
  routes: [pnpRoute],
);

final pnpRoute = LinksysRoute(
  name: RouteNamed.pnp,
  path: RoutePath.pnp,
  config: _pnpRouteConfig,
  builder: (context, state) => const PnpEntryView(),
  routes: [
    // The wizard: the steps are its children, so it stays matched while they
    // change, and its `onExit` fires only when the user leaves the wizard
    // (spike S1). Its own page is an empty placeholder under the steps — go_router
    // asserts that a route with `onExit` builds one, and its builder runs again
    // on every move between steps.
    LinksysRoute(
      name: RouteNamed.pnpConfig,
      path: RoutePath.pnpConfig,
      config: _pnpRouteConfig,
      builder: (context, state) => const SizedBox.shrink(),
      onExit: _pnpWizardExitGuard,
      preservableProvider: pnpWizardDraftsProvider,
      routes: [
        // The setting steps, from the step list (#1511 P4): a step added there
        // gets its route here without an edit.
        for (final page in pnpSettingStepPages)
          LinksysRoute(
            name: RouteNamed.pnpStep(page.id),
            path: page.id,
            config: _pnpRouteConfig,
            builder: (context, state) => page.view(),
          ),
        LinksysRoute(
          name: RouteNamed.pnpStep(PnpFlowPlan.yourNetworkStepId),
          path: PnpFlowPlan.yourNetworkStepId,
          config: _pnpRouteConfig,
          builder: (context, state) => const PnpYourNetworkStepView(),
          routes: [
            // Pushed over the whole shell, onto the root navigator, and pops
            // back to Your Network (#1734). Named pnpAddNodes, which
            // idleCheckWhiteList exempts: a session can outlast the idle
            // window.
            LinksysRoute(
              name: RouteNamed.pnpAddNodes,
              path: RoutePath.pnpAddNodes,
              parentNavigatorKey: routerKey,
              config: _pnpRouteConfig,
              builder: (context, state) => const PnpAddNodesView(),
              onExit: _pnpAddNodesExit,
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Leaving add nodes, however it is left: Your Network, under it, reads the
/// nodes again so it shows the ones that joined (#1734).
///
/// Here rather than after Your Network's `push`. On web, Done is the browser's
/// Back (`browserHistoryBack`), and so is the browser's own button: the step's
/// URL comes in as a new route list, which drops the pushed page without
/// completing its push future (go_router 17.5.0, `setNewRoutePath`), so a
/// re-read waiting on that future never ran. `onExit` runs both on a pop and
/// on that replacement. The read is not awaited: leaving never waits on it.
bool _pnpAddNodesExit(BuildContext context, GoRouterState state) {
  unawaited(ProviderScope.containerOf(context)
      .read(pnpProvider.notifier)
      .refreshMeshNodes());
  return true;
}

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
