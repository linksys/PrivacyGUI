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
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => WiFiMainView(
            args: state.extra as Map<String, dynamic>? ?? const {},
          ),
      routes: [
        LinksysRoute(
          name: RouteNamed.macFilteringInput,
          path: RoutePath.macFilteringInput,
          builder: (context, state) => FilteredDevicesView(),
        ),
      ]),
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
            LinksysRoute(
              config: LinksysRouteConfig(pageWidth: SpecificPageWidth(width: 600)),
              name: RouteNamed.firmwareUpdateDetail,
              path: RoutePath.firmwareUpdateDetail,
              builder: (context, state) => const FirmwareUpdateDetailView(),
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
      name: RouteNamed.settingsNetworkAdmin,
      path: RoutePath.settingsNetworkAdmin,
      builder: (context, state) => NetworkAdminView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.settingsTimeZone,
          path: RoutePath.settingsTimeZone,
          builder: (context, state) => TimezoneView(),
        ),
      ]),
  LinksysRoute(
    name: RouteNamed.devicePicker,
    path: RoutePath.devicePicker,
    builder: (context, state) => SelectDeviceView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
];
