part of 'router_provider.dart';

final advancedSettings = [
  LinksysRoute(
      name: RouteNamed.settingsInternet,
      path: RoutePath.settingsInternet,
      builder: (context, state) => const InternetSettingsView(),
      routes: [
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
          builder: (context, state) => ConnectionTypeView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
        LinksysRoute(
          name: RouteNamed.connectionTypeSelection,
          path: RoutePath.connectionTypeSelection,
          builder: (context, state) => ConnectionTypeSelectionView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ]),
  LinksysRoute(
    name: RouteNamed.settingsLocalNetwork,
    path: RoutePath.settingsLocalNetwork,
    builder: (context, state) => const LocalNetworkSettingsView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.dhcpReservation,
        path: RoutePath.dhcpReservation,
        builder: (context, state) => DHCPReservationsView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.dhcpServer,
        path: RoutePath.dhcpServer,
        builder: (context, state) => DHCPServerView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.localNetworkEdit,
        path: RoutePath.localNetworkEdit,
        builder: (context, state) => LocalNetworkEditView(
          args: state.extra as Map<String, dynamic>? ?? {},
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
        name: RouteNamed.singlePortForwardingList,
        path: RoutePath.singlePortForwardingList,
        builder: (context, state) => SinglePortForwardingListView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.singlePortForwardingRule,
        path: RoutePath.singlePortForwardingRule,
        builder: (context, state) => SinglePortForwardingRuleView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeForwardingList,
        path: RoutePath.portRangeForwardingList,
        builder: (context, state) => PortRangeForwardingListView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeForwardingRule,
        path: RoutePath.portRangeForwardingRule,
        builder: (context, state) => PortRangeForwardingRuleView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeTriggeringList,
        path: RoutePath.portRangeTriggeringList,
        builder: (context, state) => PortRangeTriggeringListView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.protRangeTriggeringRule,
        path: RoutePath.protRangeTriggeringRule,
        builder: (context, state) => PortRangeTriggeringRuleView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
    ],
  ),
  LinksysRoute(
      name: RouteNamed.settingsFirewall,
      path: RoutePath.settingsFirewall,
      builder: (context, state) => FirewallView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
      routes: [
        LinksysRoute(
            name: RouteNamed.ipv6PortServiceList,
            path: RoutePath.ipv6PortServiceList,
            builder: (context, state) => Ipv6PortServiceListView(
                  args: state.extra as Map<String, dynamic>? ?? {},
                ),
            routes: [
              LinksysRoute(
                name: RouteNamed.ipv6PortServiceRule,
                path: RoutePath.ipv6PortServiceRule,
                builder: (context, state) => Ipv6PortServiceRuleView(
                  args: state.extra as Map<String, dynamic>? ?? {},
                ),
              ),
            ]),
      ]),
];
