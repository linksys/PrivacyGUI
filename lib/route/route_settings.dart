part of 'router_provider.dart';

final settings = [
  GoRoute(
      name: RouteNamed.settingsWifi,
      path: RoutePath.settingsWifi,
      builder: (context, state) => WifiSettingsView(),
      routes: [
        GoRoute(
            name: RouteNamed.wifiSettingsReview,
            path: RoutePath.wifiSettingsReview,
            builder: (context, state) => WifiSettingsReviewView()),
      ]),
  GoRoute(
      name: RouteNamed.settingsNodes,
      path: RoutePath.settingsNodes,
      builder: (context, state) => TopologyView(),
      routes: [
        GoRoute(
            name: RouteNamed.nodeDetails,
            path: RoutePath.nodeDetails,
            builder: (context, state) => NodeDetailView()),
        GoRoute(
            name: RouteNamed.nodeOffline,
            path: RoutePath.nodeOffline,
            builder: (context, state) => NodeOfflineCheckView()),
      ]),
  GoRoute(
    name: RouteNamed.settingsRouterPassword,
    path: RoutePath.settingsRouterPassword,
    builder: (context, state) => RouterPasswordView(),
  ),
  GoRoute(
    name: RouteNamed.settingsTimeZone,
    path: RoutePath.settingsTimeZone,
    builder: (context, state) => TimezoneView(),
  ),
  GoRoute(
    name: RouteNamed.settingsInternet,
    path: RoutePath.settingsInternet,
    builder: (context, state) => InternetSettingsView(),
  ),
  GoRoute(
    name: RouteNamed.settingsIpDetails,
    path: RoutePath.settingsIpDetails,
    builder: (context, state) => IpDetailsView(),
  ),
  GoRoute(
    name: RouteNamed.settingsLocalNetwork,
    path: RoutePath.settingsLocalNetwork,
    builder: (context, state) => LANView(),
  ),
];
