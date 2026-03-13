import 'package:privacy_gui/usp_page/dashboard/models/device_analytics_state.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_monitor_state.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
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
  /// Dashboard state — device info, WAN/LAN, WiFi, devices, ports, etc.
  final UspDashboardState dashboard;

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

  /// Safe browsing DNS override settings (null if not loaded).
  final SafeBrowsingUIModel? safeBrowsing;

  const PdfReportData({
    required this.dashboard,
    required this.trafficAnalysis,
    required this.deviceAnalytics,
    required this.systemMonitor,
    required this.firewallSettings,
    required this.dmzSettings,
    this.staticRoutes,
    this.ipv6PortRules,
    this.safeBrowsing,
  });
}
