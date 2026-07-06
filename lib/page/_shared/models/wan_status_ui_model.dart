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

  const WanStatusUIModel({
    required this.isUp,
    required this.ipAddress,
    required this.subnetMask,
    required this.addressingType,
    required this.mtu,
    this.gateway = '',
    this.ipv6Enabled = false,
    this.ipv6Addresses = const [],
  });

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
      };
}
