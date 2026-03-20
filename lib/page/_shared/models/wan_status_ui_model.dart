import 'package:equatable/equatable.dart';

/// Presentation Layer Model for WAN interface status.
///
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class WanStatusUIModel extends Equatable {
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
  List<Object?> get props => [
        isUp,
        ipAddress,
        subnetMask,
        addressingType,
        mtu,
        gateway,
        ipv6Enabled,
        ipv6Addresses,
      ];
}
