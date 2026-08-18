import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
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
  /// Build a card widget by its spec ID.
  ///
  /// The card is wrapped in a [CardDensityHost], which measures the width the
  /// grid gave it and publishes the resulting `CardDensity` to its subtree
  /// (#1232). Wrapping happens here because this method is the single place both
  /// production and the #1183 overflow gate construct cards — anywhere else and
  /// the form under test could differ from the form users see.
  Widget? buildWidget(String id) {
    final card = _buildCard(id);
    if (card == null) return null;
    return CardDensityHost(
      cardId: id,
      normalAbove: getSpec(id)?.normalAbove,
      normalHeight: _normalHeightOf(id),
      child: card,
    );
  }

  /// Pixel height the card's whole form needs, from its spec's row count.
  ///
  /// The conversion belongs on this side of the boundary: the spec declares rows
  /// and only the dashboard knows what a row is worth, so `_shared` is handed a
  /// height it can use without knowing there is a grid (constitution Article V
  /// §5.3). `minHeightRows` rather than `maxHeightRows` because it is the floor
  /// the grid enforces — the smallest box the card is ever laid out in, hence the
  /// one its content is built to survive.
  double? _normalHeightOf(String id) {
    final rows = getSpec(id)?.getConstraints(DisplayMode.normal).minHeightRows;
    return rows == null ? null : dashboardRowsToHeight(rows);
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
