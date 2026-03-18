import 'package:privacy_gui/usp_page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/usp_page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/usp_page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/usp_page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/usp_page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_ui_model.dart';

/// Aggregates all data needed for the comprehensive PDF router report.
///
/// Built at the call site by reading from Riverpod providers. The PDF service
/// receives this as a pure data object — no dependency on Riverpod.
class PdfReportData {
  /// Ethernet port UI models (from ethernetDataProvider).
  final List<EthernetPortUIModel>? ethernetPortModels;

  /// Real-time traffic rates and error/discard metrics (polling provider).
  final TrafficAnalysisState trafficAnalysis;

  /// Device distribution and hourly connection trends (polling provider).
  final DeviceAnalyticsState deviceAnalytics;

  /// CPU/Memory history snapshots (polling provider).
  final SystemMonitorState systemMonitor;

  /// Firewall settings parsed from dashboard raw chain rules.
  final FirewallUIModel firewallSettings;

  /// DMZ settings parsed from dashboard raw DMZ entries.
  final DmzUIModel dmzSettings;

  /// Static routing rules (null if feature page not visited).
  final List<StaticRouteUIModel>? staticRoutes;

  /// IPv6 port service rules (null if feature page not visited).
  final List<Ipv6PortServiceRuleUIModel>? ipv6PortRules;

  /// LAN info with IPv6 (null if not loaded).
  final LanInfoUIModel? lanInfo;

  /// Safe browsing DNS override settings (null if not loaded).
  final SafeBrowsingUIModel? safeBrowsing;

  /// Time settings (from shared timeDataProvider).
  final TimeSettingsUIModel? timeSettings;

  /// DHCP clients (from dhcpDataProvider).
  final List<DhcpClientUIModel>? dhcpClients;

  /// DHCP reservations (from dhcpDataProvider).
  final List<DhcpReservationUIModel>? dhcpReservations;

  /// Port forwarding rules (from portForwardingDataProvider).
  final List<PortForwardingRuleUIModel>? portForwardingRules;

  /// Port triggering rules (from portTriggeringDataProvider).
  final List<PortTriggeringRuleUIModel>? portTriggeringRules;

  /// WAN status (from wanDataProvider).
  final WanStatusUIModel? wanStatus;

  /// System info (from systemInfoDataProvider).
  final SystemInfoUIModel? systemInfo;

  /// WiFi radio models (from wifiDataProvider).
  final List<WifiRadioUIModel>? radioModels;

  /// Device UI models (from devicesDataProvider).
  final List<DeviceUIModel>? deviceModels;

  /// Node UI models (from devicesDataProvider).
  final List<NodeUIModel>? nodeModels;

  const PdfReportData({
    this.ethernetPortModels,
    required this.trafficAnalysis,
    required this.deviceAnalytics,
    required this.systemMonitor,
    required this.firewallSettings,
    required this.dmzSettings,
    this.staticRoutes,
    this.ipv6PortRules,
    this.lanInfo,
    this.safeBrowsing,
    this.timeSettings,
    this.dhcpClients,
    this.dhcpReservations,
    this.portForwardingRules,
    this.portTriggeringRules,
    this.wanStatus,
    this.systemInfo,
    this.radioModels,
    this.deviceModels,
    this.nodeModels,
  });
}
