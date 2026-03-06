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

  const WanStatusUIModel({
    required this.isUp,
    required this.ipAddress,
    required this.subnetMask,
    required this.addressingType,
    required this.mtu,
    this.gateway = '',
  });

  @override
  List<Object?> get props => [
        isUp,
        ipAddress,
        subnetMask,
        addressingType,
        mtu,
        gateway,
      ];
}
