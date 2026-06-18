import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/static_routing/models/static_route_list.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_status.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

// ---------------------------------------------------------------------------
// Sample route models
// ---------------------------------------------------------------------------

const route1 = StaticRouteUIModel(
  instancePath: 'Device.Routing.Router.1.IPv4Forwarding.1.',
  enabled: true,
  name: 'Corporate LAN',
  destIpAddress: '10.0.0.0',
  destSubnetMask: '255.0.0.0',
  gatewayIpAddress: '192.168.1.1',
  interfaceName: 'WAN',
  interfacePath: 'Device.IP.Interface.1.',
);

const route2 = StaticRouteUIModel(
  instancePath: 'Device.Routing.Router.1.IPv4Forwarding.2.',
  enabled: true,
  name: 'Guest Network',
  destIpAddress: '172.16.0.0',
  destSubnetMask: '255.240.0.0',
  gatewayIpAddress: '192.168.1.254',
  interfaceName: 'LAN',
  interfacePath: 'Device.IP.Interface.2.',
);

const disabledRoute = StaticRouteUIModel(
  instancePath: 'Device.Routing.Router.1.IPv4Forwarding.3.',
  enabled: false,
  name: 'VPN Subnet',
  destIpAddress: '10.8.0.0',
  destSubnetMask: '255.255.255.0',
  gatewayIpAddress: '192.168.1.100',
  interfaceName: 'WAN',
  interfacePath: 'Device.IP.Interface.1.',
);

// ---------------------------------------------------------------------------
// State builders
// ---------------------------------------------------------------------------

StaticRoutingFeatureState dataState(List<StaticRouteUIModel> routes) {
  final settings = StaticRouteList(routes: routes);
  return StaticRoutingFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const StaticRoutingStatus(),
  );
}

StaticRoutingFeatureState emptyState() {
  return StaticRoutingFeatureState(
    settings: Preservable(
      original: const StaticRouteList(),
      current: const StaticRouteList(),
    ),
    status: const StaticRoutingStatus(),
  );
}

StaticRoutingFeatureState dirtyState({bool isSaving = false}) {
  const original = StaticRouteList(routes: [route1, route2]);
  const current = StaticRouteList(routes: [route1, route2, disabledRoute]);
  return StaticRoutingFeatureState(
    settings: Preservable(original: original, current: current),
    status: StaticRoutingStatus(isSaving: isSaving),
  );
}

StaticRoutingFeatureState get errorState => StaticRoutingFeatureState(
      settings: Preservable(
        original: const StaticRouteList(),
        current: const StaticRouteList(),
      ),
      status: const StaticRoutingStatus(
        errorMessage: 'Connection failed',
      ),
    );
