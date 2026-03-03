import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';

/// State for the standalone USP Dashboard.
///
/// Contains all data fetched directly via USP (no JNAP polling dependency).
class UspDashboardState extends Equatable {
  final SystemInfo systemInfo;
  final ConnectedDevices connectedDevices;
  final WiFiRadios wifiRadios;
  final WiFiSsids wifiSsids;
  final WiFiAccessPoints wifiAccessPoints;
  final TimeSettings timeSettings;
  final DhcpReservations dhcpReservations;
  final PortForwarding portForwarding;
  final bool isAuthenticated;

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
      ];
}

