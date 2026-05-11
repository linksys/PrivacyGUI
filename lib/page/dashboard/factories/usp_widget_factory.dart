import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

import '../views/components/_components.dart';

/// Unified USP Dashboard Widget Factory.
///
/// Maps widget IDs to card widgets. All cards are constructed with no
/// arguments — they read data from domain-specific data providers internally.
class UspWidgetFactory {
  /// Build a card widget by its spec ID.
  Widget? buildWidget(String id) {
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
