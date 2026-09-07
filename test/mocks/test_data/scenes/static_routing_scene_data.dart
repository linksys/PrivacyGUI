/// Composed scenes for `usp_static_routing_view` — the golden suite's four states and
/// the gate's one.
///
/// Moved here from
/// `test/golden_test/page/static_routing/fixtures/static_routing_test_data.dart` by
/// #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate may
/// not import from `test/golden_test/` (#1361), and one fixture read by both suites
/// beats two that can disagree.
library;

import 'package:privacy_gui/core/errors/service_error.dart';
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
        error: ConnectivityError(detail: 'Connection failed'),
      ),
    );

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The two routes the gate sweeps, and the reasoning is
/// `ipv6_port_service_scene_data.dart`'s at the same card shape — a switch, an
/// `Expanded` three-line column and two icon buttons in one `Row`.
///
/// [route1] as it stands, plus a second route that is the same card at its widest:
///
/// - an **empty name**, so `_buildRouteCard`'s `loc(context).unnamed` fallback is
///   rendered. Unlike `ipv6_port_service` this card has a second localized string —
///   `gatewayLabel(gateway, interface)` is a template, not raw router data — so the
///   fallback is not the only thing making these cells differ by locale, but it is
///   still the widest of the two in most locales.
/// - a **disabled** switch, so both switch states are measured.
/// - the longest destination pair the page can show: `255.255.255.255` is 15
///   characters against [route1]'s `255.0.0.0`, and the middle line renders
///   `dest / mask` as one string, so this is the line that decides whether the
///   `Expanded` column fits beside two icon buttons at 320px.
const _gateRoutes = [
  route1,
  StaticRouteUIModel(
    instancePath: 'Device.Routing.Router.1.IPv4Forwarding.4.',
    enabled: false,
    name: '',
    destIpAddress: '198.51.100.128',
    destSubnetMask: '255.255.255.255',
    gatewayIpAddress: '192.168.1.254',
    interfaceName: 'WAN',
    interfacePath: 'Device.IP.Interface.1.',
  ),
];

/// The router shape every `page.static_routing` cell is measured against.
///
/// Clean and non-empty, for the two reasons `kPortForwardingPageCase` gives:
/// `emptyState()` renders one [DetailEmptyBlock] instead of any card, and
/// `dirtyState()` adds the `UiKitBottomBarConfig` save bar, which is ui_kit's own
/// chrome and out of scope for #1380.
final gateStaticRoutingState = dataState(_gateRoutes);
