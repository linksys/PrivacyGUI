import 'package:equatable/equatable.dart';

/// Read-only WAN/IPv6 fields displayed on the Internet Settings page
/// but NOT user-editable.
///
/// Decouples the model layer from codegen types (`WanSettings`, `Ipv6Settings`).
class InternetSettingsReadOnlyInfo extends Equatable {
  /// Current WAN MAC address (may differ from configured MAC clone).
  final String currentMacAddress;

  /// PPP connection status string (e.g. 'Connected', 'Disconnected').
  final String pppConnectionStatus;

  /// DHCPv6 DUID (read-only, assigned by server).
  final String dhcpv6Duid;

  /// Current static IP address — displayed in the status banner and renew section.
  final String staticIpAddress;

  /// Router hostname (`Device.DeviceInfo.HostName`). Display-only; used to build
  /// the `https://<hostName>.local` bridge-mode management address.
  final String hostName;

  const InternetSettingsReadOnlyInfo({
    this.currentMacAddress = '',
    this.pppConnectionStatus = '',
    this.dhcpv6Duid = '',
    this.staticIpAddress = '',
    this.hostName = '',
  });

  @override
  List<Object?> get props => [
        currentMacAddress,
        pppConnectionStatus,
        dhcpv6Duid,
        staticIpAddress,
        hostName,
      ];
}
