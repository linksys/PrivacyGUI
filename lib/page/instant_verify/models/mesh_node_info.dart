import 'package:equatable/equatable.dart';

/// Represents a single mesh node (router or satellite) parsed from GetDevices3.
class MeshNodeInfo extends Equatable {
  final String deviceId;
  final String name;
  final String? model;
  final String? firmware;
  final String? serialNumber;
  final bool isController; // isAuthority: true = main router

  /// "Wireless" or "Wired" — how this node connects back to the controller.
  /// Null for the controller node itself.
  final String? backhaulType;

  /// Backhaul signal (wireless only). < -70 dBm = weak.
  final int? backhaulRssi;

  /// Estimated backhaul throughput in Mbps (from GetBackhaulInfo).
  final int? backhaulSpeedMbps;

  const MeshNodeInfo({
    required this.deviceId,
    required this.name,
    this.model,
    this.firmware,
    this.serialNumber,
    required this.isController,
    this.backhaulType,
    this.backhaulRssi,
    this.backhaulSpeedMbps,
  });

  bool get hasWeakBackhaul =>
      backhaulRssi != null && backhaulRssi! < -70 && !isController;

  bool get hasWiredBackhaul => backhaulType == 'Wired';

  String get backhaulLabel {
    if (isController) return 'Main Router';
    if (backhaulType == 'Wired') return 'Wired backhaul';
    if (backhaulRssi != null) return 'Wireless ${backhaulRssi} dBm';
    return 'Wireless';
  }

  @override
  List<Object?> get props => [
        deviceId,
        name,
        model,
        firmware,
        serialNumber,
        isController,
        backhaulType,
        backhaulRssi,
        backhaulSpeedMbps,
      ];
}
