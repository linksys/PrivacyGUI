part of 'router_provider.dart';

final advancedSettings = [
  LinksysRoute(
      name: RouteNamed.settingsInternet,
      path: RoutePath.settingsInternet,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      builder: (context, state) => const InternetSettingsView(),
      routes: [
        LinksysRoute(
          name: RouteNamed.mtuPicker,
          path: RoutePath.mtuPicker,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => MTUPickerView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
        LinksysRoute(
          name: RouteNamed.macClone,
          path: RoutePath.macClone,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => MACCloneView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
        LinksysRoute(
          name: RouteNamed.connectionType,
          path: RoutePath.connectionType,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => ConnectionTypeView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
        LinksysRoute(
          name: RouteNamed.connectionTypeSelection,
          path: RoutePath.connectionTypeSelection,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 9),
          ),
          builder: (context, state) => ConnectionTypeSelectionView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ]),
  LinksysRoute(
    name: RouteNamed.settingsLocalNetwork,
    path: RoutePath.settingsLocalNetwork,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => const LocalNetworkSettingsView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.dhcpReservation,
        path: RoutePath.dhcpReservation,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => DHCPReservationsView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.dhcpReservationEdit,
        path: RoutePath.dhcpReservationEdit,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => DHCPReservationsEditView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.dhcpServer,
        path: RoutePath.dhcpServer,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => DHCPServerView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
    ],
  ),
  LinksysRoute(
    name: RouteNamed.settingsPort,
    path: RoutePath.settingsPort,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => PortForwardingView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.singlePortForwardingList,
        path: RoutePath.singlePortForwardingList,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => SinglePortForwardingListView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.singlePortForwardingRule,
        path: RoutePath.singlePortForwardingRule,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => SinglePortForwardingRuleView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeForwardingList,
        path: RoutePath.portRangeForwardingList,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => PortRangeForwardingListView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeForwardingRule,
        path: RoutePath.portRangeForwardingRule,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => PortRangeForwardingRuleView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.portRangeTriggeringList,
        path: RoutePath.portRangeTriggeringList,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => PortRangeTriggeringListView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      LinksysRoute(
        name: RouteNamed.protRangeTriggeringRule,
        path: RoutePath.protRangeTriggeringRule,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        builder: (context, state) => PortRangeTriggeringRuleView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
    ],
  ),
  LinksysRoute(
      name: RouteNamed.settingsFirewall,
      path: RoutePath.settingsFirewall,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      builder: (context, state) => FirewallView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
      routes: [
        LinksysRoute(
            name: RouteNamed.ipv6PortServiceList,
            path: RoutePath.ipv6PortServiceList,
            config: LinksysRouteConfig(
              column: ColumnGrid(column: 9),
            ),
            builder: (context, state) => Ipv6PortServiceListView(
                  args: state.extra as Map<String, dynamic>? ?? {},
                ),
            routes: [
              LinksysRoute(
                name: RouteNamed.ipv6PortServiceRule,
                path: RoutePath.ipv6PortServiceRule,
                config: LinksysRouteConfig(
                  column: ColumnGrid(column: 9),
                ),
                builder: (context, state) => Ipv6PortServiceRuleView(
                  args: state.extra as Map<String, dynamic>? ?? {},
                ),
              ),
            ]),
      ]),
  LinksysRoute(
    name: RouteNamed.settingsDMZ,
    path: RoutePath.settingsDMZ,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => DMZSettingsView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  LinksysRoute(
    name: RouteNamed.settingsAdministration,
    path: RoutePath.settingsAdministration,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => AdministrationSettingsView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
];
