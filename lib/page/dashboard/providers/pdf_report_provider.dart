import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/pdf_report_data.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/services/usp_pdf_service.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/usp_ipv6_port_service_notifier.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

final pdfReportProvider = Provider<PdfReport>(PdfReport.new);

/// The dashboard's PDF report: what it says, and opening it.
///
/// [snapshot] reads every domain provider again on each call. It used to be a
/// `Provider<PdfReportData?>` built with `ref.read`, which Riverpod computes
/// once and then caches, so every export after the first printed the first
/// export's data. Watching the sources instead would have kept the static
/// routing and IPv6 page notifiers (both autoDispose working copies) alive for
/// the whole session, so they could no longer reset when the user left the
/// page.
class PdfReport {
  final Ref _ref;

  PdfReport(this._ref);

  /// Generate the report from the data as it is now and open it.
  Future<void> open() => UspPdfService.generatePdf(snapshot());

  /// Aggregates the current state of every domain provider the report shows.
  PdfReportData snapshot() {
    final fwData = _ref.read(firewallDataProvider).valueOrNull;
    final lanData = _ref.read(lanDataProvider).valueOrNull;

    return PdfReportData(
      ethernetPortModels:
          _ref.read(ethernetDataProvider).valueOrNull?.ethernetPortModels,
      trafficAnalysis: _ref.read(uspTrafficAnalysisProvider),
      deviceAnalytics: _ref.read(uspDeviceAnalyticsProvider),
      systemMonitor: _ref.read(uspSystemMonitorProvider),
      firewallSettings: fwData?.firewallModel ?? const FirewallUIModel(),
      dmzSettings: fwData?.dmzModel ?? const DmzUIModel.disabled(),
      staticRoutes: _ref.read(uspStaticRoutingProvider).settings.current.routes,
      ipv6PortRules:
          _ref.read(uspIpv6PortServiceProvider).settings.current.rules,
      // Built from L1 LAN data (DNS servers).
      safeBrowsing: lanData == null
          ? null
          : SafeBrowsingUIModel.fromDnsServers(lanData.model.dnsServers),
      lanInfo: lanData?.model,
      timeSettings: _ref.read(timeDataProvider).valueOrNull?.model,
      dhcpClients: _ref.read(dhcpDataProvider).valueOrNull?.clientModels,
      dhcpReservations:
          _ref.read(dhcpDataProvider).valueOrNull?.reservationModels,
      portForwardingRules:
          _ref.read(portForwardingDataProvider).valueOrNull?.ruleModels,
      portTriggeringRules:
          _ref.read(portTriggeringDataProvider).valueOrNull?.ruleModels,
      wanStatus: _ref.read(wanDataProvider).valueOrNull?.model,
      systemInfo: _ref.read(systemInfoDataProvider).valueOrNull?.model,
      radioModels: _ref.read(wifiDataProvider).valueOrNull?.radioModels,
      clientDevices: _ref.read(devicesDataProvider).valueOrNull?.clientDevices,
      nodes: _ref.read(devicesDataProvider).valueOrNull?.nodes,
    );
  }
}
