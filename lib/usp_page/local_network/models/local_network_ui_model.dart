import 'package:equatable/equatable.dart';

/// UI-facing representation of the Local Network configuration.
///
/// Combines router identity (hostname, IP, subnet) with DHCP server settings.
/// DNS servers are split into 3 individual fields for the UI; the codegen
/// model stores them as a single comma-separated string.
/// Lease time is stored in minutes (UI) while codegen uses seconds.
class LocalNetworkUIModel extends Equatable {
  // Router info
  final String hostName;
  final String ipAddress;
  final String subnetMask;

  // DHCP server settings
  final bool dhcpEnabled;
  final String minAddress;
  final String maxAddress;
  final int leaseTimeMinutes;
  final String dnsServer1;
  final String dnsServer2;
  final String dnsServer3;

  const LocalNetworkUIModel({
    required this.hostName,
    required this.ipAddress,
    required this.subnetMask,
    required this.dhcpEnabled,
    required this.minAddress,
    required this.maxAddress,
    required this.leaseTimeMinutes,
    required this.dnsServer1,
    required this.dnsServer2,
    required this.dnsServer3,
  });

  /// Default initial state (empty strings, DHCP disabled).
  const LocalNetworkUIModel.initial()
      : hostName = '',
        ipAddress = '',
        subnetMask = '',
        dhcpEnabled = false,
        minAddress = '',
        maxAddress = '',
        leaseTimeMinutes = 0,
        dnsServer1 = '',
        dnsServer2 = '',
        dnsServer3 = '';

  LocalNetworkUIModel copyWith({
    String? hostName,
    String? ipAddress,
    String? subnetMask,
    bool? dhcpEnabled,
    String? minAddress,
    String? maxAddress,
    int? leaseTimeMinutes,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
  }) {
    return LocalNetworkUIModel(
      hostName: hostName ?? this.hostName,
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      dhcpEnabled: dhcpEnabled ?? this.dhcpEnabled,
      minAddress: minAddress ?? this.minAddress,
      maxAddress: maxAddress ?? this.maxAddress,
      leaseTimeMinutes: leaseTimeMinutes ?? this.leaseTimeMinutes,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
      dnsServer3: dnsServer3 ?? this.dnsServer3,
    );
  }

  @override
  List<Object?> get props => [
        hostName,
        ipAddress,
        subnetMask,
        dhcpEnabled,
        minAddress,
        maxAddress,
        leaseTimeMinutes,
        dnsServer1,
        dnsServer2,
        dnsServer3,
      ];
}
