import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/pdf_report_data.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/services/usp_pdf_service.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

final pdfReportProvider = Provider<PdfReport>(PdfReport.new);

/// The dashboard's PDF report: what it says, and opening it.
///
/// [snapshot] reads every source again on each call. It used to be a
/// `Provider<PdfReportData?>` built with `ref.read`, which Riverpod computes
/// once and then caches, so every export after the first printed the first
/// export's data.
class PdfReport {
  final Ref _ref;

  PdfReport(this._ref);

  /// Generate the report from the data as it is now and open it.
  Future<void> open() async => UspPdfService.generatePdf(await snapshot());

  /// Aggregates the current state of every domain provider the report shows.
  Future<PdfReportData> snapshot() async {
    // Static routes and IPv6 rules have no L1 provider, so they are read from
    // their services. Not from the pages' notifiers: those are autoDispose
    // working copies, so a bare read got the empty initial state (both sections
    // never printed), and fetching through them would reset an open page's
    // unsaved edits.
    final (staticRoutes, ipv6Rules) = await (
      _readOrSkip('static routes',
          () => _ref.read(uspStaticRoutingServiceProvider).fetch()),
      _readOrSkip('IPv6 port rules',
          () => _ref.read(uspIpv6PortServiceServiceProvider).fetch()),
    ).wait;

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
      staticRoutes: staticRoutes,
      ipv6PortRules: ipv6Rules,
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

  /// A section the router cannot read is left out of the report, as every
  /// other section is when its data is not there, rather than failing the
  /// whole export.
  static Future<List<T>?> _readOrSkip<T>(
      String what, Future<List<T>> Function() read) async {
    try {
      return await read();
    } on ServiceError catch (e) {
      logger.w('[PDF] Leaving $what out of the report: $e');
      return null;
    }
  }
}
