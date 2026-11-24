import 'package:equatable/equatable.dart';

enum WanIpStatus { unavailable, firstObservation, unchanged, changed }

/// A comparison with a browser-local reference for one router, not a public-IP
/// lookup or proof that an upstream service has blocked this address.
class WanIpComparison extends Equatable {
  final WanIpStatus status;
  final String? currentAddress;
  final String? referenceAddress;

  const WanIpComparison({
    this.status = WanIpStatus.unavailable,
    this.currentAddress,
    this.referenceAddress,
  });

  bool get hasChanged => status == WanIpStatus.changed;
  bool get canCompare =>
      status == WanIpStatus.changed || status == WanIpStatus.unchanged;

  @override
  List<Object?> get props => [status, currentAddress, referenceAddress];
}
