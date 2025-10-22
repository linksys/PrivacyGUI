part of 'router_provider.dart';

final advancedSettings = [
  LinksysRoute(
    name: RouteNamed.internetSettings,
    path: RoutePath.internetSettings,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 12),
    ),
    builder: (context, state) => const InternetSettingsView(),
    routes: const [],
  ),
  LinksysRoute(
    name: RouteNamed.settingsLocalNetwork,
    path: RoutePath.settingsLocalNetwork,
    preservableProvider: preservableLocalNetworkSettingsProvider,
    enableDirtyCheck: true,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 12),
    ),
    builder: (context, state) => const LocalNetworkSettingsView(),
    routes: [
      LinksysRoute(
        name: RouteNamed.dhcpReservation,
        path: RoutePath.dhcpReservation,
        preservableProvider: preservableDHCPReservationsProvider,
        enableDirtyCheck: true,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
        ),
        builder: (context, state) => DHCPReservationsView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
    ],
  ),
  LinksysRoute(
    name: RouteNamed.settingsAppsGaming,
    path: RoutePath.settingsAppsGaming,
    preservableProvider: preservableAppsAndGamingSettingsProvider,
    enableDirtyCheck: true,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 12),
    ),
    builder: (context, state) => AppsGamingSettingsView(),
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
        name: RouteNamed.portRangeTriggeringRule,
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
      preservableProvider: preservableFirewallProvider,
      enableDirtyCheck: true,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 12),
      ),
      builder: (context, state) => FirewallView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
      routes: [
        LinksysRoute(
            name: RouteNamed.ipv6PortServiceList,
            path: RoutePath.ipv6PortServiceList,
            config: LinksysRouteConfig(
              column: ColumnGrid(column: 12),
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
    preservableProvider: preservableDMZSettingsProvider,
    enableDirtyCheck: true,
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
    preservableProvider: preservableAdministrationSettingsProvider,
    enableDirtyCheck: true,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => AdministrationSettingsView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  LinksysRoute(
    name: RouteNamed.settingsStaticRouting,
    path: RoutePath.settingsStaticRouting,
    preservableProvider: preservableStaticRoutingProvider,
    enableDirtyCheck: true,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 12),
    ),
    builder: (context, state) => StaticRoutingView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
    routes: [
      LinksysRoute(
        name: RouteNamed.settingsStaticRoutingRule,
        path: RoutePath.settingsStaticRoutingRule,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6),
        ),
        builder: (context, state) => StaticRoutingRuleView(
          args: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
    ],
  ),
  LinksysRoute(
    name: RouteNamed.cardListEdit,
    path: RoutePath.cardListEdit,
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 9),
    ),
    builder: (context, state) => EditableCardListEditView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
];
