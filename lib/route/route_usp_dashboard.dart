part of 'router_provider.dart';

final uspShellNavigatorKey = GlobalKey<NavigatorState>();

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
      onExit: (context, state) async {
        final container = ProviderScope.containerOf(context);
        return !container.read(firmwareUpdateNotifierProvider).isUpdating;
      },
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
    LinksysRoute(
      name: RouteNamed.uspStatistics,
      path: RoutePath.uspStatistics,
      builder: (context, state) {
        final tabParam = state.uri.queryParameters['tab'];
        final initialTab = int.tryParse(tabParam ?? '') ?? 0;
        return UspStatisticsView(initialTab: initialTab);
      },
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
          path: RouteNamed.uspLocalNetwork,
          builder: (context, state) => const UspLocalNetworkView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspLocalNetworkProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspFirewall,
          path: RouteNamed.uspFirewall,
          builder: (context, state) => const UspFirewallView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspFirewallProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspDmz,
          path: RouteNamed.uspDmz,
          builder: (context, state) => const UspDmzView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspDmzProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspPortForwardingDetail,
          path: RouteNamed.uspPortForwardingDetail,
          builder: (context, state) => const UspPortForwardingDetailView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspPortForwardingPageProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspStaticRouting,
          path: RouteNamed.uspStaticRouting,
          builder: (context, state) => const UspStaticRoutingView(),
          enableDirtyCheck: true,
          preservableProvider: preservableUspStaticRoutingProvider,
        ),
        LinksysRoute(
          name: RouteNamed.uspIpv6PortService,
          path: RouteNamed.uspIpv6PortService,
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
      builder: (context, state) => const UspWifiSettingsView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspApps,
      path: RoutePath.uspApps,
      builder: (context, state) => const UspAppsView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspSpeedTest,
      path: RoutePath.uspSpeedTest,
      builder: (context, state) => const SpeedTestView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspAiAssistant,
      path: RoutePath.uspAiAssistant,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => const RouterAssistantView(),
    ),
  ],
);
