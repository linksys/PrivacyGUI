import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/lan_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/wan_status_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/time_settings_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/usp_page/topology/models/node_ui_model.dart';

/// State for the standalone USP Dashboard.
///
/// Contains raw codegen data (for the Notifier's mutation methods) and
/// Presentation Layer UI Models (for views).
class UspDashboardState extends Equatable {
  // ─── Raw codegen data (used by Notifier for mutations) ───
  final SystemInfo systemInfo;
  final ConnectedDevices connectedDevices;
  final WiFiRadios wifiRadios;
  final WiFiSsids wifiSsids;
  final WiFiAccessPoints wifiAccessPoints;
  final TimeSettings timeSettings;
  final DhcpClients dhcpClients;
  final DhcpReservations dhcpReservations;
  final PortForwarding portForwarding;
  final PortTriggering portTriggering;
  final bool isAuthenticated;
  final Map<String, WifiClient> wifiClientMap;
  final MeshTopologyInfo meshTopology;
  final Map<String, ClientConnectionDetail> connectionDetailMap;
  final LanNetworkInfo lanNetworkInfo;
  final EthernetInterfaces ethernetInterfaces;
  final WanStatus wanStatus;

  // ─── Presentation Layer UI Models (used by views) ───
  final SystemInfoUIModel systemInfoModel;
  final LanInfoUIModel lanInfoModel;
  final List<DeviceUIModel> deviceModels;
  final List<WifiRadioUIModel> wifiRadioModels;
  final TimeSettingsUIModel timeSettingsModel;
  final List<DhcpClientUIModel> dhcpClientModels;
  final List<DhcpReservationUIModel> dhcpReservationModels;
  final List<PortForwardingRuleUIModel> portForwardingRuleModels;
  final List<PortTriggeringRuleUIModel> portTriggeringRuleModels;
  final List<EthernetPortUIModel> ethernetPortModels;
  final List<NodeUIModel> nodeModels;
  final WanStatusUIModel wanStatusModel;

  const UspDashboardState({
    required this.systemInfo,
    required this.connectedDevices,
    required this.wifiRadios,
    required this.wifiSsids,
    required this.wifiAccessPoints,
    required this.timeSettings,
    this.dhcpClients = const DhcpClients(items: []),
    required this.dhcpReservations,
    required this.portForwarding,
    this.portTriggering = const PortTriggering(items: []),
    required this.isAuthenticated,
    this.wifiClientMap = const {},
    this.meshTopology = MeshTopologyInfo.empty,
    this.connectionDetailMap = const {},
    required this.lanNetworkInfo,
    required this.ethernetInterfaces,
    this.wanStatus = const WanStatus(
      status: '',
      ipAddress: '',
      subnetMask: '',
      addressingType: '',
      maxMtuSize: 0,
    ),
    this.ethernetPortModels = const [],
    this.lanInfoModel = const LanInfoUIModel(
      ipAddress: '',
      subnetMask: '',
      dhcpEnabled: false,
      minAddress: '',
      maxAddress: '',
    ),
    this.systemInfoModel = const SystemInfoUIModel(
      manufacturer: '',
      modelName: '',
      serialNumber: '',
      hardwareVersion: '',
      softwareVersion: '',
      uptime: 0,
      totalMemory: 0,
      freeMemory: 0,
      cpuUsage: 0,
    ),
    this.deviceModels = const [],
    this.wifiRadioModels = const [],
    this.timeSettingsModel = const TimeSettingsUIModel(
      enable: false,
      status: '',
      currentLocalTime: '',
      localTimeZone: '',
      ntpServer1: '',
      ntpServer2: '',
    ),
    this.dhcpClientModels = const [],
    this.dhcpReservationModels = const [],
    this.portForwardingRuleModels = const [],
    this.portTriggeringRuleModels = const [],
    this.nodeModels = const [],
    this.wanStatusModel = const WanStatusUIModel(
      isUp: false,
      ipAddress: '',
      subnetMask: '',
      addressingType: '',
      mtu: 0,
    ),
  });

  int get onlineDeviceCount =>
      connectedDevices.items.where((d) => d.isActive).length;

  UspDashboardState copyWith({
    SystemInfo? systemInfo,
    ConnectedDevices? connectedDevices,
    WiFiRadios? wifiRadios,
    WiFiSsids? wifiSsids,
    WiFiAccessPoints? wifiAccessPoints,
    TimeSettings? timeSettings,
    DhcpClients? dhcpClients,
    DhcpReservations? dhcpReservations,
    PortForwarding? portForwarding,
    PortTriggering? portTriggering,
    bool? isAuthenticated,
    Map<String, WifiClient>? wifiClientMap,
    MeshTopologyInfo? meshTopology,
    Map<String, ClientConnectionDetail>? connectionDetailMap,
    LanNetworkInfo? lanNetworkInfo,
    EthernetInterfaces? ethernetInterfaces,
    WanStatus? wanStatus,
    List<EthernetPortUIModel>? ethernetPortModels,
    LanInfoUIModel? lanInfoModel,
    SystemInfoUIModel? systemInfoModel,
    List<DeviceUIModel>? deviceModels,
    List<WifiRadioUIModel>? wifiRadioModels,
    TimeSettingsUIModel? timeSettingsModel,
    List<DhcpClientUIModel>? dhcpClientModels,
    List<DhcpReservationUIModel>? dhcpReservationModels,
    List<PortForwardingRuleUIModel>? portForwardingRuleModels,
    List<PortTriggeringRuleUIModel>? portTriggeringRuleModels,
    List<NodeUIModel>? nodeModels,
    WanStatusUIModel? wanStatusModel,
  }) {
    return UspDashboardState(
      systemInfo: systemInfo ?? this.systemInfo,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      wifiRadios: wifiRadios ?? this.wifiRadios,
      wifiSsids: wifiSsids ?? this.wifiSsids,
      wifiAccessPoints: wifiAccessPoints ?? this.wifiAccessPoints,
      timeSettings: timeSettings ?? this.timeSettings,
      dhcpClients: dhcpClients ?? this.dhcpClients,
      dhcpReservations: dhcpReservations ?? this.dhcpReservations,
      portForwarding: portForwarding ?? this.portForwarding,
      portTriggering: portTriggering ?? this.portTriggering,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      wifiClientMap: wifiClientMap ?? this.wifiClientMap,
      meshTopology: meshTopology ?? this.meshTopology,
      connectionDetailMap: connectionDetailMap ?? this.connectionDetailMap,
      lanNetworkInfo: lanNetworkInfo ?? this.lanNetworkInfo,
      ethernetInterfaces: ethernetInterfaces ?? this.ethernetInterfaces,
      wanStatus: wanStatus ?? this.wanStatus,
      ethernetPortModels: ethernetPortModels ?? this.ethernetPortModels,
      lanInfoModel: lanInfoModel ?? this.lanInfoModel,
      systemInfoModel: systemInfoModel ?? this.systemInfoModel,
      deviceModels: deviceModels ?? this.deviceModels,
      wifiRadioModels: wifiRadioModels ?? this.wifiRadioModels,
      timeSettingsModel: timeSettingsModel ?? this.timeSettingsModel,
      dhcpClientModels: dhcpClientModels ?? this.dhcpClientModels,
      dhcpReservationModels:
          dhcpReservationModels ?? this.dhcpReservationModels,
      portForwardingRuleModels:
          portForwardingRuleModels ?? this.portForwardingRuleModels,
      portTriggeringRuleModels:
          portTriggeringRuleModels ?? this.portTriggeringRuleModels,
      nodeModels: nodeModels ?? this.nodeModels,
      wanStatusModel: wanStatusModel ?? this.wanStatusModel,
    );
  }

  @override
  List<Object?> get props => [
        systemInfo.serialNumber,
        connectedDevices.items.length,
        wifiRadios.items.length,
        wifiSsids.items.length,
        wifiAccessPoints.items.length,
        timeSettings.currentLocalTime,
        dhcpClients.items.length,
        dhcpReservations.items.length,
        portForwarding.items.length,
        portTriggering.items.length,
        isAuthenticated,
        wifiClientMap.length,
        meshTopology.nodes.length,
        connectionDetailMap.length,
        lanNetworkInfo.ipAddress,
        ethernetInterfaces.items.length,
        wanStatus.ipAddress,
        ethernetPortModels.length,
        lanInfoModel,
        systemInfoModel,
        deviceModels.length,
        wifiRadioModels.length,
        timeSettingsModel,
        dhcpClientModels.length,
        dhcpReservationModels.length,
        portForwardingRuleModels.length,
        portTriggeringRuleModels.length,
        nodeModels.length,
        wanStatusModel,
      ];
}
