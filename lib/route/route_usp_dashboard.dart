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
      builder: (context, state) => const UspDashboardView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspMenu,
      path: RoutePath.uspMenu,
      builder: (context, state) => const UspMenuView(),
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
    ),
    LinksysRoute(
      name: RouteNamed.uspAdmin,
      path: RoutePath.uspAdmin,
      builder: (context, state) => const UspAdminView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspDhcpDetail,
      path: RoutePath.uspDhcpDetail,
      builder: (context, state) => const UspDhcpDetailView(),
    ),
    LinksysRoute(
      name: RouteNamed.uspPortForwardingDetail,
      path: RoutePath.uspPortForwardingDetail,
      builder: (context, state) => const UspPortForwardingDetailView(),
    ),
  ],
);
