import 'package:equatable/equatable.dart';

/// Presentation Layer Model for LAN configuration info.
///
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class LanInfoUIModel extends Equatable {
  final String hostName;
  final String ipAddress;
  final String subnetMask;
  final bool dhcpEnabled;
  final String minAddress;
  final String maxAddress;
  final int leaseTimeMinutes;
  final String dnsServers;
  final bool ipv6Enabled;
  final List<String> ipv6Addresses;

  const LanInfoUIModel({
    this.hostName = '',
    required this.ipAddress,
    required this.subnetMask,
    required this.dhcpEnabled,
    required this.minAddress,
    required this.maxAddress,
    this.leaseTimeMinutes = 0,
    this.dnsServers = '',
    this.ipv6Enabled = false,
    this.ipv6Addresses = const [],
  });

  /// Formatted DHCP range for display (e.g. "192.168.1.100 ~ 192.168.1.199").
  String get dhcpRange => (minAddress.isNotEmpty && maxAddress.isNotEmpty)
      ? '$minAddress ~ $maxAddress'
      : 'N/A';

  @override
  List<Object?> get props => [
        ipAddress,
        subnetMask,
        dhcpEnabled,
        minAddress,
        maxAddress,
        dnsServers,
        ipv6Enabled,
        ipv6Addresses,
      ];
}
