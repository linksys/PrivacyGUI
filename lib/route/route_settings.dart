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
    builder: (context, state) => WifiSettingsView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.wifiSettingsReview,
        path: RoutePath.wifiSettingsReview,
        builder: (context, state) => WifiSettingsReviewView(),
        routes: [
          LinksysRoute(
            name: RouteNamed.wifiEditSSID,
            path: RoutePath.wifiEditSSID,
            builder: (context, state) => EditWifiNamePasswordView(),
          ),
          LinksysRoute(
            name: RouteNamed.wifiEditSecurity,
            path: RoutePath.wifiEditSecurity,
            builder: (context, state) => EditWifiSecurityView(
              args: state.uri.queryParameters,
            ),
          ),
          LinksysRoute(
            name: RouteNamed.wifiEditMode,
            path: RoutePath.wifiEditMode,
            builder: (context, state) => EditWifiModeView(),
          ),
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
          name: RouteNamed.nodeOffline,
          path: RoutePath.nodeOffline,
          builder: (context, state) => NodeOfflineCheckView(),
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
  LinksysRoute(
      name: RouteNamed.settingsInternet,
      path: RoutePath.settingsInternet,
      builder: (context, state) => InternetSettingsView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.itemPicker,
          path: RoutePath.itemPicker,
          builder: (context, state) => SimpleItemPickerView(
            args: state.uri.queryParameters,
          ),
        ),
        LinksysRoute(
          name: RouteNamed.mtuPicker,
          path: RoutePath.mtuPicker,
          builder: (context, state) => MTUPickerView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
        LinksysRoute(
          name: RouteNamed.macClone,
          path: RoutePath.macClone,
          builder: (context, state) => MACCloneView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
        LinksysRoute(
          name: RouteNamed.connectionType,
          path: RoutePath.connectionType,
          builder: (context, state) => ConnectionTypeSelectionView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ]),
  LinksysRoute(
    name: RouteNamed.settingsIpDetails,
    path: RoutePath.settingsIpDetails,
    builder: (context, state) => IpDetailsView(),
  ),
  LinksysRoute(
    name: RouteNamed.settingsLocalNetwork,
    path: RoutePath.settingsLocalNetwork,
    builder: (context, state) => LANView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.dhcpReservation,
        path: RoutePath.dhcpReservation,
        builder: (context, state) => DHCPReservationsView(
          args: state.uri.queryParameters,
        ),
      ),
    ],
  ),
  LinksysRoute(
    name: RouteNamed.settingsMacFiltering,
    path: RoutePath.settingsMacFiltering,
    builder: (context, state) => MacFilteringView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.macFilteringInput,
        path: RoutePath.macFilteringInput,
        builder: (context, state) => MacFilteringEnterDeviceView(
          args: state.uri.queryParameters,
        ),
      ),
    ],
  ),
  LinksysRoute(
    name: RouteNamed.settingsPort,
    path: RoutePath.settingsPort,
    builder: (context, state) => PortForwardingView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.selectDevice,
        path: RoutePath.selectDevice,
        builder: (context, state) => SelectOnlineDeviceView(
          args: state.uri.queryParameters,
        ),
      ),
      LinksysRoute(
        name: RouteNamed.selectProtocol,
        path: RoutePath.selectProtocol,
        builder: (context, state) => SelectProtocolView(
          args: state.uri.queryParameters,
        ),
      ),
      LinksysRoute(
        name: RouteNamed.singlePortForwardingList,
        path: RoutePath.singlePortForwardingList,
        builder: (context, state) => SinglePortForwardingListView(
          args: state.uri.queryParameters,
        ),
      ),
      LinksysRoute(
        name: RouteNamed.singlePortForwardingRule,
        path: RoutePath.singlePortForwardingRule,
        builder: (context, state) => SinglePortForwardingRuleView(
          args: state.uri.queryParameters,
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeForwardingList,
        path: RoutePath.portRangeForwardingList,
        builder: (context, state) => PortRangeForwardingListView(
          args: state.uri.queryParameters,
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeForwardingRule,
        path: RoutePath.portRangeForwardingRule,
        builder: (context, state) => PortRangeForwardingRuleView(
          args: state.uri.queryParameters,
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeTriggeringList,
        path: RoutePath.portRangeTriggeringList,
        builder: (context, state) => PortRangeTriggeringListView(
          args: state.uri.queryParameters,
        ),
      ),
    ],
  ),
];
