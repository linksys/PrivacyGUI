import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/card_grid_geometry.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

import '../models/usp_widget_specs.dart';
import 'package:privacy_gui/page/admin/cards/usp_device_info_card.dart';
import 'package:privacy_gui/page/admin/cards/usp_time_settings_card.dart';
import 'package:privacy_gui/page/devices/cards/usp_connected_devices_card.dart';
import 'package:privacy_gui/page/firewall/cards/usp_firewall_overview_card.dart';
import 'package:privacy_gui/page/internet_settings/cards/usp_network_status_card.dart';
import 'package:privacy_gui/page/local_network/cards/usp_dhcp_reservations_card.dart';
import 'package:privacy_gui/page/local_network/cards/usp_ethernet_ports_card.dart';
import 'package:privacy_gui/page/local_network/cards/usp_lan_info_card.dart';
import 'package:privacy_gui/page/port_forwarding/cards/usp_port_forwarding_card.dart';
import 'package:privacy_gui/page/topology/cards/usp_network_topology_card.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_performance_card.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_networks_card.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_status_card.dart';
// import 'package:privacy_gui/page/unified_diagnostics/cards/usp_speed_test_card.dart'; // disabled: #857

import '../views/components/_components.dart';

/// Unified USP Dashboard Widget Factory.
///
/// Maps widget IDs to card widgets. All cards are constructed with no
/// arguments — they read data from domain-specific data providers internally.
class UspWidgetFactory {
  /// Build a card widget by its spec ID, for a box [cardWidth] pixels wide.
  ///
  /// The card is wrapped in a [CardDensityHost], which publishes the
  /// `CardDensity` that width selects to its subtree (#1232). Wrapping happens
  /// here because this method is the single place both production and the #1183
  /// overflow gate construct cards — anywhere else and the form under test could
  /// differ from the form users see.
  ///
  /// [cardWidth] is required and nullable for the reason given on
  /// [CardDensityHost.cardWidth]: a caller that has no box has to say so. The two
  /// that have one are the dashboard grid, which computes it as part of laying the
  /// tile out (#1401), and `dashboard_card_probe.dart`, which computes it from the
  /// same grid formula before it pumps.
  Widget? buildWidget(String id, {required double? cardWidth}) {
    final card = _buildCard(id);
    if (card == null) return null;
    return CardDensityHost(
      cardId: id,
      normalAbove: getSpec(id)?.normalAbove,
      cardWidth: cardWidth,
      normalHeight: _normalHeightOf(id),
      child: card,
    );
  }

  /// The density band a box [width] pixels wide puts card [id] in, before any
  /// pick or override is applied.
  ///
  /// The grid's `breakpointResolver` (#1401): what the dashboard hands
  /// `DashboardItemBreakpointBuilder` so the package knows when a resize has
  /// actually changed the form a card renders in, and can hold the cached subtree
  /// for every width that has not.
  ///
  /// Deliberately blind to [cardDensityOverrideProvider] and [cardFormsProvider],
  /// which are read one level down inside [CardDensityHost]. A resolver that saw
  /// them would be answering a different question — "which form is on screen"
  /// rather than "has the width changed the form" — and it has no `ref` to see
  /// them with anyway, being called from the package's layout path.
  ///
  /// Agrees with what the host publishes by construction: both read the threshold
  /// from `getSpec(id)?.normalAbove` and both resolve through
  /// [densityForSuppliedWidth]. They have to agree — a resolver that reported no
  /// transition where the host wanted one would leave the card in its old form
  /// until something else invalidated the tile. Pinned by test.
  CardDensity densityBandFor(String id, double? width) =>
      densityForSuppliedWidth(
        width: width,
        normalAbove: getSpec(id)?.normalAbove,
      );

  /// Pixel height the card's whole form needs, from its spec's row count.
  ///
  /// The conversion belongs on this side of the boundary: the spec declares rows
  /// and only the dashboard knows what a row is worth, so `_shared` is handed a
  /// height it can use without knowing there is a grid (constitution Article V
  /// §5.3).
  ///
  /// The rows are the *preferred* ones — the same call
  /// `layout_item_factory.dart` makes when it places a card on the grid, so the
  /// presentation is the height the dashboard would have given the card. It used
  /// to be `minHeightRows`, which is the floor the grid enforces rather than the
  /// box the card is laid out in: eleven of the eighteen specs prefer more than
  /// their floor, topology by two whole rows (a floor of 3, `strict(5)`), so its
  /// presentation was 392px of a card that fills 664 — measured in the built app
  /// as "obviously too small". `maxHeightRows` is the other wrong end: the ceiling
  /// a user may drag to, not a claim about the content.
  ///
  /// No `columns` argument: it only changes the answer for
  /// `AspectRatioHeightStrategy`, which no spec in `usp_widget_specs.dart` uses,
  /// and the presentation's width is a constant rather than a span
  /// ([kCardPresentationWidth]) so there would be no span to pass.
  double? _normalHeightOf(String id) {
    final constraints = getSpec(id)?.getConstraints(DisplayMode.normal);
    return constraints == null
        ? null
        : dashboardRowsToHeight(constraints.getPreferredHeightCells());
  }

  Widget? _buildCard(String id) {
    return switch (id) {
      'stats_panel' => UspStatsPanel(),
      'device_info' => UspDeviceInfoCard(),
      'network_status' => UspNetworkStatusCard(),
      'topology' => UspNetworkTopologyCard(),
      'lan_info' => UspLanInfoCard(),
      'ethernet_ports' => UspEthernetPortsCard(),
      'system_status' => UspSystemStatusCard(),
      'connected_devices' => UspConnectedDevicesCard(),
      'wifi_status' => UspWifiStatusCard(),
      'wifi_networks' => UspWifiNetworksCard(),
      'time_settings' => UspTimeSettingsCard(),
      'dhcp_reservations' => UspDhcpReservationsCard(),
      'port_forwarding' => UspPortForwardingCard(),
      'traffic_analysis' => UspTrafficAnalysisCard(),
      'device_analytics' => UspDeviceAnalyticsCard(),
      'network_health' => UspNetworkHealthCard(),
      'firewall_overview' => UspFirewallOverviewCard(),
      'wifi_performance' => UspWifiPerformanceCard(),
      // 'speed_test' => UspSpeedTestCard(), // disabled: blocked by FW support (#857)
      _ => null,
    };
  }

  /// USP cards wrap themselves in AppCard — no extra wrapping needed.
  bool shouldWrapInCard(String id) => false;

  /// Get widget spec by ID.
  WidgetSpec? getSpec(String id) => UspWidgetSpecs.getById(id);
}

/// Riverpod provider for [UspWidgetFactory].
final uspWidgetFactoryProvider = Provider((_) => UspWidgetFactory());
