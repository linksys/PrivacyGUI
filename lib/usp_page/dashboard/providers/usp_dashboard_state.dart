import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/time_settings_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';

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
  final DhcpReservations dhcpReservations;
  final PortForwarding portForwarding;
  final bool isAuthenticated;
  final Map<String, WifiClient> wifiClientMap;
  final MeshTopologyInfo meshTopology;
  final Map<String, ClientConnectionDetail> connectionDetailMap;

  // ─── Presentation Layer UI Models (used by views) ───
  final SystemInfoUIModel systemInfoModel;
  final List<DeviceUIModel> deviceModels;
  final List<WifiRadioUIModel> wifiRadioModels;
  final TimeSettingsUIModel timeSettingsModel;
  final List<DhcpReservationUIModel> dhcpReservationModels;
  final List<PortForwardingRuleUIModel> portForwardingRuleModels;

  const UspDashboardState({
    required this.systemInfo,
    required this.connectedDevices,
    required this.wifiRadios,
    required this.wifiSsids,
    required this.wifiAccessPoints,
    required this.timeSettings,
    required this.dhcpReservations,
    required this.portForwarding,
    required this.isAuthenticated,
    this.wifiClientMap = const {},
    this.meshTopology = MeshTopologyInfo.empty,
    this.connectionDetailMap = const {},
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
    this.dhcpReservationModels = const [],
    this.portForwardingRuleModels = const [],
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
    DhcpReservations? dhcpReservations,
    PortForwarding? portForwarding,
    bool? isAuthenticated,
    Map<String, WifiClient>? wifiClientMap,
    MeshTopologyInfo? meshTopology,
    Map<String, ClientConnectionDetail>? connectionDetailMap,
    SystemInfoUIModel? systemInfoModel,
    List<DeviceUIModel>? deviceModels,
    List<WifiRadioUIModel>? wifiRadioModels,
    TimeSettingsUIModel? timeSettingsModel,
    List<DhcpReservationUIModel>? dhcpReservationModels,
    List<PortForwardingRuleUIModel>? portForwardingRuleModels,
  }) {
    return UspDashboardState(
      systemInfo: systemInfo ?? this.systemInfo,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      wifiRadios: wifiRadios ?? this.wifiRadios,
      wifiSsids: wifiSsids ?? this.wifiSsids,
      wifiAccessPoints: wifiAccessPoints ?? this.wifiAccessPoints,
      timeSettings: timeSettings ?? this.timeSettings,
      dhcpReservations: dhcpReservations ?? this.dhcpReservations,
      portForwarding: portForwarding ?? this.portForwarding,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      wifiClientMap: wifiClientMap ?? this.wifiClientMap,
      meshTopology: meshTopology ?? this.meshTopology,
      connectionDetailMap: connectionDetailMap ?? this.connectionDetailMap,
      systemInfoModel: systemInfoModel ?? this.systemInfoModel,
      deviceModels: deviceModels ?? this.deviceModels,
      wifiRadioModels: wifiRadioModels ?? this.wifiRadioModels,
      timeSettingsModel: timeSettingsModel ?? this.timeSettingsModel,
      dhcpReservationModels:
          dhcpReservationModels ?? this.dhcpReservationModels,
      portForwardingRuleModels:
          portForwardingRuleModels ?? this.portForwardingRuleModels,
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
        dhcpReservations.items.length,
        portForwarding.items.length,
        isAuthenticated,
        wifiClientMap.length,
        meshTopology.nodes.length,
        connectionDetailMap.length,
        systemInfoModel,
        deviceModels.length,
        wifiRadioModels.length,
        timeSettingsModel,
        dhcpReservationModels.length,
        portForwardingRuleModels.length,
      ];
}
