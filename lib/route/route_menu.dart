part of 'router_provider.dart';

final menus = [
  LinksysRoute(
    name: RouteNamed.menuInstantSafety,
    path: RoutePath.safeBrowsing,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => const InstantSafetyView(),
  ),
  LinksysRoute(
    name: RouteNamed.menuInstantDevices,
    path: RoutePath.menuInstantDevices,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 12),
    ),
    builder: (context, state) => InstantDeviceView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.deviceDetails,
        path: RoutePath.deviceDetails,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
        ),
        builder: (context, state) => DeviceDetailView(),
      ),
    ],
  ),
  LinksysRoute(
    name: RouteNamed.menuAdvancedSettings,
    path: RoutePath.menuAdvancedSettings,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => const DashboardAdvancedSettingsView(),
    routes: advancedSettings,
  ),
  LinksysRoute(
      name: RouteNamed.menuInstantTopology,
      path: RoutePath.menuInstantTopology,
      builder: (context, state) => InstantTopologyView(
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
      name: RouteNamed.menuInstantAdmin,
      path: RoutePath.menuInstantAdmin,
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
    name: RouteNamed.menuIncredibleWiFi,
    path: RoutePath.menuIncredibleWiFi,
    config:
        LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: true),
    builder: (context, state) => WiFiMainView(
      args: state.extra as Map<String, dynamic>? ?? const {},
    ),
  ),
  LinksysRoute(
    name: RouteNamed.menuInstantPrivacy,
    path: RoutePath.menuInstantPrivacy,
    config: LinksysRouteConfig(column: ColumnGrid(column: 12)),
    builder: (context, state) => InstantPrivacyView(
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
    ],
  ),
  LinksysRoute(
    name: RouteNamed.menuInstantVerify,
    path: RoutePath.menuInstantVerify,
    config:
        LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: true),
    builder: (context, state) => InstantVerifyView(
      args: state.extra as Map<String, dynamic>? ?? const {},
    ),
  ),
];