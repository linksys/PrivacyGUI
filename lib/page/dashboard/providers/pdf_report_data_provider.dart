import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/pdf_report_data.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/usp_ipv6_port_service_notifier.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

/// Aggregates all domain data providers into a single [PdfReportData].
///
/// Reads current state from each domain provider — returns `null` if the
/// essential orchestrator-driven providers are not yet ready.
final pdfReportDataProvider = Provider<PdfReportData?>((ref) {
  final fwData = ref.read(firewallDataProvider).valueOrNull;
  final lanData = ref.read(lanDataProvider).valueOrNull;

  // Build SafeBrowsingUIModel from L1 LAN data (DNS servers)
  SafeBrowsingUIModel? safeBrowsingModel;
  if (lanData != null) {
    final dnsServers = lanData.model.dnsServers;
    final isOpenDns = UspInstantSafetyService.isOpenDns(dnsServers);
    safeBrowsingModel = SafeBrowsingUIModel(
      type: isOpenDns ? SafeBrowsingType.openDNS : SafeBrowsingType.off,
      currentDnsServers: dnsServers,
    );
  }

  return PdfReportData(
    ethernetPortModels:
        ref.read(ethernetDataProvider).valueOrNull?.ethernetPortModels,
    trafficAnalysis: ref.read(uspTrafficAnalysisProvider),
    deviceAnalytics: ref.read(uspDeviceAnalyticsProvider),
    systemMonitor: ref.read(uspSystemMonitorProvider),
    firewallSettings: fwData?.firewallModel ?? const FirewallUIModel(),
    dmzSettings: fwData?.dmzModel ?? const DmzUIModel.disabled(),
    staticRoutes: ref.read(uspStaticRoutingProvider).settings.current.routes,
    ipv6PortRules: ref.read(uspIpv6PortServiceProvider).settings.current.rules,
    safeBrowsing: safeBrowsingModel,
    lanInfo: lanData?.model,
    timeSettings: ref.read(timeDataProvider).valueOrNull?.model,
    dhcpClients: ref.read(dhcpDataProvider).valueOrNull?.clientModels,
    dhcpReservations: ref.read(dhcpDataProvider).valueOrNull?.reservationModels,
    portForwardingRules:
        ref.read(portForwardingDataProvider).valueOrNull?.ruleModels,
    portTriggeringRules:
        ref.read(portTriggeringDataProvider).valueOrNull?.ruleModels,
    wanStatus: ref.read(wanDataProvider).valueOrNull?.model,
    systemInfo: ref.read(systemInfoDataProvider).valueOrNull?.model,
    radioModels: ref.read(wifiDataProvider).valueOrNull?.radioModels,
    deviceModels: ref.read(devicesDataProvider).valueOrNull?.deviceModels,
    nodeModels: ref.read(devicesDataProvider).valueOrNull?.nodeModels,
  );
});
