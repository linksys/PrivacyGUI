part of 'router_provider.dart';

final uspShellNavigatorKey = GlobalKey<NavigatorState>();

/// `?tab=N` for the three tab-carrying USP pages, defaulting to the first tab.
///
/// One spelling on purpose. Each view clamps this against its own `tabCount`, so
/// an unparseable or out-of-range value opens tab 0 instead of throwing — which
/// also means a typo here (`'tabs'`, or a stale clamp bound) degrades silently to
/// tab 0 for real users while every layout-gate cell stays green, because the
/// sweep passes `initialTab:` to the constructor and never goes through this file.
/// A defect with no test to catch it should at least have only one place to be.
int _uspTabQueryParam(GoRouterState state) =>
    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;

/// Refuses to leave either firmware page while an install is running.
///
/// One function referenced by both routes rather than the same closure written
/// twice. #1549 gave one install two entry points — the OTA page fetches an image
/// and the manual page uploads one — and "can I navigate away mid-flash" must not
/// depend on which of them started it. Two byte-identical copies are exactly what
/// lets a later change tighten one and forget the other, and the per-route matrix
/// in `test/route/usp_firmware_exit_guard_test.dart` would not catch that: it
/// pulls each route's own `onExit` out of the real tree, so two guards that
/// disagree are two guards it faithfully reports as disagreeing, one case at a
/// time, only if someone reads which case failed.
///
/// `pop` is what reaches this (`_handlePopPageWithRouteMatch` consults `onExit`
/// and vetoes the Navigator pop on `false`), which is the back arrow and the
/// browser's Back button. A `pushNamed` over the top does not — the pushed-over
/// match stays in the list, so the guard is deferred rather than skipped.
///
/// **A session that is over is not a navigation to argue with.** `go` consults
/// `onExit` for every match that is leaving, and the sign-out path is a `go`: the
/// router's `redirect` sends a signed-out user to the login page and the leaving
/// match is this one. Vetoing that leaves the app on a firmware page it has no
/// session to talk to, until the install phase happens to end. So
/// [AppConnectionState.loggedOut] releases the guard — it covers every sign-out,
/// the core-reported ones and auth's own (an idle timeout, a 401, the account
/// menu), which is the same reason `session_exit_sink.dart` keys on the cause
/// rather than on this state.
Future<bool> _firmwareExitGuard(
    BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  if (container.read(appConnectionStateProvider) ==
      AppConnectionState.loggedOut) {
    return true;
  }
  return !container.read(firmwareUpdateNotifierProvider).isUpdating;
}

final uspDashboardRoute = ShellRoute(
  navigatorKey: uspShellNavigatorKey,
  builder: (BuildContext context, GoRouterState state, Widget child) =>
      UspDashboardShell(child: child),
  routes: [
    LinksysRoute(
      name: RouteNamed.uspDashboard,
      path: RoutePath.uspDashboard,
      builder: (context, state) {
        // Reset bars visibility on every route enter (including pop back)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final container = ProviderScope.containerOf(context);
          container.read(uspBarsVisibleProvider.notifier).state = true;
          container.read(uspMenuController).setMenuVisible(true);
        });
        return const UspDashboardView();
      },
      onExit: (context, state) async {
        // Cancel edit mode when navigating away from dashboard (e.g., tab
        // switch), reverting to the pre-edit snapshot.
        //
        // Intentional silent-discard policy: unlike the enableDirtyCheck routes
        // below, the dashboard does NOT prompt with showUnsavedAlert. Every
        // layout edit is stored as it is made — the grid reports its own drops
        // and resizes (#1393) — so "cancel" means restoring the snapshot captured
        // on edit-mode entry rather than dropping a buffer of pending work, and a
        // confirmation dialog on every tab switch would be noise. See #1037.
        final container = ProviderScope.containerOf(context);
        final editState = container.read(dashboardEditModeProvider);
        if (editState.isEditing) {
          try {
            await container
                .read(dashboardEditModeProvider.notifier)
                .cancelEditMode();
          } catch (e, s) {
            // Never block navigation on a revert failure; cancelEditMode resets
            // its own state in a finally block, so edit mode won't be stranded.
            logger.e('[Route]: dashboard cancelEditMode failed on exit',
                error: e, stackTrace: s);
          }
        }
        return true;
      },
    ),
    LinksysRoute(
      name: RouteNamed.uspMenu,
      path: RoutePath.uspMenu,
      builder: (context, state) => const UspMenuView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.uspUnifiedDiagnostics,
          path: RoutePath.uspUnifiedDiagnostics,
          builder: (context, state) => const UnifiedDiagnosticsView(),
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.uspSupport,
      path: RoutePath.uspSupport,
      builder: (context, state) => const UspSupportView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspDeviceList,
      path: RoutePath.uspDeviceList,
      builder: (context, state) => const UspDeviceListView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.uspDeviceDetail,
          path: RoutePath.uspDeviceDetail,
          builder: (context, state) {
            final mac = state.uri.queryParameters['mac'] ?? '';
            return UspDeviceDetailView(mac: mac);
          },
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.uspTopology,
      path: RoutePath.uspTopology,
      builder: (context, state) => const UspTopologyView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.uspNodeDetail,
          path: RoutePath.uspNodeDetail,
          builder: (context, state) {
            final deviceId = state.uri.queryParameters['deviceId'] ?? '';
            return UspNodeDetailView(deviceId: deviceId);
          },
        ),
      ],
    ),
    LinksysRoute(
      name: RouteNamed.uspInstantSafety,
      path: RoutePath.uspInstantSafety,
      builder: (context, state) => const UspInstantSafetyView(),
      enableDirtyCheck: true,
      preservableProvider: preservableUspInstantSafetyProvider,
    ),
    LinksysRoute(
      name: RouteNamed.uspInstantPrivacy,
      path: RoutePath.uspInstantPrivacy,
      builder: (context, state) =>
          const usp_instant_privacy.InstantPrivacyView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspAdmin,
      path: RoutePath.uspAdmin,
      builder: (context, state) => const UspAdminView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspFirmwareUpdate,
      path: RoutePath.uspFirmwareUpdate,
      builder: (context, state) => const FirmwareUpdateView(),
      onExit: _firmwareExitGuard,
    ),
    LinksysRoute(
      name: RouteNamed.uspFirmwareOta,
      path: RoutePath.uspFirmwareOta,
      builder: (context, state) => const FirmwareOtaView(),
      // The same guard object as the manual page above, not a second copy of it —
      // see `_firmwareExitGuard`.
      onExit: _firmwareExitGuard,
    ),
    LinksysRoute(
      name: RouteNamed.uspDhcpDetail,
      path: RoutePath.uspDhcpDetail,
      builder: (context, state) => const UspDhcpDetailView(),
      enableDirtyCheck: true,
      preservableProvider: preservableUspDhcpReservationsProvider,
    ),
    LinksysRoute(
      name: RouteNamed.uspSystemLog,
      path: RoutePath.uspSystemLog,
      builder: (context, state) => const UspSystemLogView(),
    ),
    // Registered in every mode, deliberately. The child routes of the shared
    // dashboard are one table, so a hand-typed `/uspNotificationHistory` resolves
    // locally too — #1474 phase 9 hit the mirror of this with `localLoginRoute`
    // in a remote build. The page reads `BridgeConfig.remoteReads` and renders an
    // explicit "not available in this mode" state, which beats the developer
    // error page a route that declined the location would produce. The *entry
    // point* is what the mode decides: `SurfaceStrategy
    // .notificationHistoryMenuEntry`.
    LinksysRoute(
      name: RouteNamed.uspNotificationHistory,
      path: RoutePath.uspNotificationHistory,
      builder: (context, state) => const UspNotificationHistoryView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspStatistics,
      path: RoutePath.uspStatistics,
      builder: (context, state) =>
          UspStatisticsView(initialTab: _uspTabQueryParam(state)),
    ),
    LinksysRoute(
      name: RouteNamed.uspAdvancedSettings,
      path: RoutePath.uspAdvancedSettings,
      builder: (context, state) => const UspAdvancedSettingsView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.uspInternetSettings,
          path: RoutePath.uspInternetSettings,
          config: const LinksysRouteConfig(noNaviRail: true),
          builder: (context, state) => const UspInternetSettingsView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspInternetSettingsProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspLocalNetwork,
          path: RoutePath.uspLocalNetwork,
          builder: (context, state) => const UspLocalNetworkView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspLocalNetworkProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspFirewall,
          path: RoutePath.uspFirewall,
          builder: (context, state) => const UspFirewallView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspFirewallProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspDmz,
          path: RoutePath.uspDmz,
          builder: (context, state) => const UspDmzView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspDmzProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspPortForwardingDetail,
          path: RoutePath.uspPortForwardingDetail,
          builder: (context, state) => UspPortForwardingDetailView(
            initialTab: _uspTabQueryParam(state),
          ),
          enableDirtyCheck: true,
          preservableProvider: preservableUspPortForwardingPageProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspStaticRouting,
          path: RoutePath.uspStaticRouting,
          builder: (context, state) => const UspStaticRoutingView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspStaticRoutingProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspIpv6PortService,
          path: RoutePath.uspIpv6PortService,
          builder: (context, state) => const UspIpv6PortServiceView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspIpv6PortServiceProvider,
        ),
      ],
    ),
    if (kDebugMode || GlobalConfig.feature.enableTestConsole)
      LinksysRoute(
        name: RouteNamed.uspTestConsole,
        path: RoutePath.uspTestConsole,
        builder: (context, state) => const UspTestConsoleView(),
      ),
    LinksysRoute(
      name: RouteNamed.uspWifiSettings,
      path: RoutePath.uspWifiSettings,
      preservableProvider: preservableUspWifiPageProvider,
      enableDirtyCheck: true,
      builder: (context, state) =>
          UspWifiSettingsView(initialTab: _uspTabQueryParam(state)),
    ),
    LinksysRoute(
      name: RouteNamed.uspApps,
      path: RoutePath.uspApps,
      builder: (context, state) => const UspAppsView(),
    ),
    // Speed Test route disabled: blocked by FW support (#857)
    // LinksysRoute(
    //   name: RouteNamed.uspSpeedTest,
    //   path: RoutePath.uspSpeedTest,
    //   builder: (context, state) => const SpeedTestView(),
    // ),
    LinksysRoute(
      name: RouteNamed.uspAiAssistant,
      path: RoutePath.uspAiAssistant,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => const RouterAssistantView(),
    ),
  ],
);
