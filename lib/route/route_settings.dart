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
          builder: (context, state) => WifiSettingsReviewView(),
          routes: [
            GoRoute(
              name: RouteNamed.wifiEditSSID,
              path: RoutePath.wifiEditSSID,
              builder: (context, state) => EditWifiNamePasswordView(),
            ),
            GoRoute(
              name: RouteNamed.wifiEditSecurity,
              path: RoutePath.wifiEditSecurity,
              builder: (context, state) => EditWifiSecurityView(
                args: state.uri.queryParameters,
              ),
            ),
            GoRoute(
              name: RouteNamed.wifiEditMode,
              path: RoutePath.wifiEditMode,
              builder: (context, state) => EditWifiModeView(),
            ),
          ],
        ),
      ]),
  GoRoute(
      name: RouteNamed.settingsNodes,
      path: RoutePath.settingsNodes,
      builder: (context, state) => TopologyView(),
      routes: [
        GoRoute(
          name: RouteNamed.nodeDetails,
          path: RoutePath.nodeDetails,
          builder: (context, state) => NodeDetailView(),
        ),
        GoRoute(
          name: RouteNamed.nodeOffline,
          path: RoutePath.nodeOffline,
          builder: (context, state) => NodeOfflineCheckView(),
        ),
        GoRoute(
          name: RouteNamed.nodeLight,
          path: RoutePath.nodeLight,
          builder: (context, state) => NodeLightGuideView(),
        ),
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
      routes: [
        GoRoute(
          name: RouteNamed.itemPicker,
          path: RoutePath.itemPicker,
          builder: (context, state) => SimpleItemPickerView(
            args: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          name: RouteNamed.mtuPicker,
          path: RoutePath.mtuPicker,
          builder: (context, state) => MTUPickerView(
            args: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          name: RouteNamed.macClone,
          path: RoutePath.macClone,
          builder: (context, state) => MACCloneView(
            args: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          name: RouteNamed.connectionType,
          path: RoutePath.connectionType,
          builder: (context, state) => ConnectionTypeSelectionView(
            args: state.uri.queryParameters,
          ),
        ),
      ]),
  GoRoute(
    name: RouteNamed.settingsIpDetails,
    path: RoutePath.settingsIpDetails,
    builder: (context, state) => IpDetailsView(),
  ),
  GoRoute(
    name: RouteNamed.settingsLocalNetwork,
    path: RoutePath.settingsLocalNetwork,
    builder: (context, state) => LANView(),
    routes: [
      GoRoute(
        name: RouteNamed.dhcpReservation,
        path: RoutePath.dhcpReservation,
        builder: (context, state) => DHCPReservationsView(
          args: state.uri.queryParameters,
        ),
      ),
    ],
  ),
  GoRoute(
    name: RouteNamed.settingsMacFiltering,
    path: RoutePath.settingsMacFiltering,
    builder: (context, state) => MacFilteringView(),
    routes: [
      GoRoute(
        name: RouteNamed.macFilteringInput,
        path: RoutePath.macFilteringInput,
        builder: (context, state) => MacFilteringEnterDeviceView(
          args: state.uri.queryParameters,
        ),
      ),
    ],
  ),
  GoRoute(
    name: RouteNamed.settingsPort,
    path: RoutePath.settingsPort,
    builder: (context, state) => PortForwardingView(),
    routes: [
      GoRoute(
        name: RouteNamed.selectDevice,
        path: RoutePath.selectDevice,
        builder: (context, state) => SelectOnlineDeviceView(
          args: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        name: RouteNamed.selectProtocol,
        path: RoutePath.selectProtocol,
        builder: (context, state) => SelectProtocolView(
          args: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        name: RouteNamed.singlePortForwardingList,
        path: RoutePath.singlePortForwardingList,
        builder: (context, state) => SinglePortForwardingListView(
          args: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        name: RouteNamed.portRangeForwardingList,
        path: RoutePath.portRangeForwardingList,
        builder: (context, state) => PortRangeForwardingListView(
          args: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        name: RouteNamed.portRangeTriggeringList,
        path: RoutePath.portRangeTriggeringList,
        builder: (context, state) => PortRangeTriggeringListView(
          args: state.uri.queryParameters,
        ),
      ),
    ],
  ),
];
