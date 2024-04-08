part of 'router_provider.dart';

final settings = [
  LinksysRoute(
    name: RouteNamed.settingsNotification,
    path: RoutePath.settingsNotification,
    builder: (context, state) => NotificationSettingsView(),
  ),
  LinksysRoute(
    name: RouteNamed.settingsWifi,
    path: RoutePath.settingsWifi,
    builder: (context, state) => WifiSelectSettingsView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.wifiSettingsReview,
        path: RoutePath.wifiSettingsReview,
        builder: (context, state) => WifiSettingsReviewView(),
        routes: [
          LinksysRoute(
            name: RouteNamed.channelFinderOptimize,
            path: RoutePath.channelFinderOptimize,
            builder: (context, state) => WifiSettingsChannelFinderView(),
          )
        ],
      ),
    ],
  ),
  LinksysRoute(
    name: RouteNamed.wifiAdvancedSettings,
    path: RoutePath.wifiAdvancedSettings,
    builder: (context, state) => WifiAdvancedSettingsView(),
  ),
  LinksysRoute(
      name: RouteNamed.settingsNodes,
      path: RoutePath.settingsNodes,
      builder: (context, state) => TopologyView(
            args: state.uri.queryParameters,
          ),
      routes: [
        LinksysRoute(
          name: RouteNamed.nodeDetails,
          path: RoutePath.nodeDetails,
          builder: (context, state) => NodeDetailView(),
          routes: [
            LinksysRoute(
              name: RouteNamed.changeNodeName,
              path: RoutePath.changeNodeName,
              builder: (context, state) => const ChangeNodeNameView(),
            ),
            LinksysRoute(
              name: RouteNamed.nodeLightSettings,
              path: RoutePath.nodeLightSettings,
              builder: (context, state) => const NodeSwitchLightView(),
            ),
          ],
        ),
        LinksysRoute(
          name: RouteNamed.nodeLight,
          path: RoutePath.nodeLight,
          builder: (context, state) => NodeLightGuideView(),
        ),
      ]),
  LinksysRoute(
    name: RouteNamed.settingsRouterPassword,
    path: RoutePath.settingsRouterPassword,
    builder: (context, state) => RouterPasswordView(),
  ),
  LinksysRoute(
    name: RouteNamed.settingsTimeZone,
    path: RoutePath.settingsTimeZone,
    builder: (context, state) => TimezoneView(),
  ),
];
