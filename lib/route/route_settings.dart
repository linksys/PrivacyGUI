part of 'router_provider.dart';

final settings = [
  LinksysRoute(
      name: RouteNamed.settingsWifi,
      path: RoutePath.settingsWifi,
      config:
          LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: true),
      builder: (context, state) => WiFiMainView(
            args: state.extra as Map<String, dynamic>? ?? const {},
          ),
      routes: [
        LinksysRoute(
          name: RouteNamed.macFilteringInput,
          path: RoutePath.macFilteringInput,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => FilteredDevicesView(),
        ),
      ]),
  LinksysRoute(
    name: RouteNamed.wifiAdvancedSettings,
    path: RoutePath.wifiAdvancedSettings,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
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
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
          ),
          builder: (context, state) => NodeDetailView(),
          routes: [
            LinksysRoute(
              config: LinksysRouteConfig(column: ColumnGrid(column: 12)),
              name: RouteNamed.firmwareUpdateDetail,
              path: RoutePath.firmwareUpdateDetail,
              builder: (context, state) => const FirmwareUpdateDetailView(),
            ),
          ],
        ),
      ]),
  LinksysRoute(
      name: RouteNamed.settingsNetworkAdmin,
      path: RoutePath.settingsNetworkAdmin,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      builder: (context, state) => NetworkAdminView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.settingsTimeZone,
          path: RoutePath.settingsTimeZone,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => TimezoneView(),
        ),
      ]),
  LinksysRoute(
    name: RouteNamed.devicePicker,
    path: RoutePath.devicePicker,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => SelectDeviceView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
];
