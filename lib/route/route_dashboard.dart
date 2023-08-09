part of 'router_provider.dart';

final dashboardRoute = ShellRoute(
  builder: (BuildContext context, GoRouterState state, Widget child) =>
      DashboardShell(child: child),
  routes: [
    GoRoute(
      name: 'dashboardHome',
      path: '/dashboardHome',
      builder: (context, state) => DashboardHomeView(),
      routes: [
        GoRoute(
          name: 'nodes1',
          path: 'nodes',
          builder: (context, state) => TopologyView(),
        ),
      ],
    ),
    GoRoute(
        name: 'dashboardSettings',
        path: '/dashboardSettings',
        builder: (context, state) => DashboardSettingsView(),
        routes: [
          GoRoute(
            name: 'wifiSettings',
            path: 'wifiSettings',
            builder: (context, state) => WifiSettingsView(),
          ),
          GoRoute(
            name: 'nodes',
            path: 'nodes',
            builder: (context, state) => TopologyView(),
          ),
          GoRoute(
            name: 'routerPassword',
            path: 'routerPassword',
            builder: (context, state) => RouterPasswordView(),
          ),
          GoRoute(
            name: 'timeZone',
            path: 'timeZone',
            builder: (context, state) => TimezoneView(),
          ),
          GoRoute(
            name: 'internetSettings',
            path: 'internetSettings',
            builder: (context, state) => InternetSettingsView(),
          ),
          GoRoute(
            name: 'ipDetails',
            path: 'ipDetails',
            builder: (context, state) => IpDetailsView(),
          ),
          GoRoute(
            name: 'localNetworkSettings',
            path: 'localNetworkSettings',
            builder: (context, state) => LANView(),
          ),
        ])
  ],
);
