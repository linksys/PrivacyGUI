part of 'router_provider.dart';

final settings = [
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
