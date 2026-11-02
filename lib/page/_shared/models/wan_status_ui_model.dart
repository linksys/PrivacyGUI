import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for WAN interface status.
///
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class WanStatusUIModel extends Equatable with DiagnosticLoggable {
  final bool isUp;
  final String ipAddress;
  final String subnetMask;
  final String addressingType;
  final int mtu;
  final String gateway;
  final bool ipv6Enabled;
  final List<String> ipv6Addresses;

  /// The IPv4 DNS servers the WAN is using, from `Device.DNS.Client.Server.*`
  /// (#1702). Empty when there are none or they could not be read; the card
  /// then hides its DNS row.
  final List<String> dnsServers;

  const WanStatusUIModel({
    required this.isUp,
    required this.ipAddress,
    required this.subnetMask,
    required this.addressingType,
    required this.mtu,
    this.gateway = '',
    this.ipv6Enabled = false,
    this.ipv6Addresses = const [],
    this.dnsServers = const [],
  });

  @override
  String get diagnosticName => 'WanStatusUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'isUp': isUp,
        'ipAddress': ipAddress,
        'subnetMask': subnetMask,
        'addressingType': addressingType,
        'mtu': mtu,
        'gateway': gateway,
        'ipv6Enabled': ipv6Enabled,
        'ipv6Addresses': ipv6Addresses,
        'dnsServers': dnsServers,
      };
}
