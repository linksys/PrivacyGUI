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

  /// Legacy single-RSSI field (kept for backward compat). Prefer [backhaulApRssi].
  final int? backhaulRssi;

  /// Estimated backhaul throughput in Mbps (from GetBackhaulInfo2 → speedMbps).
  final int? backhaulSpeedMbps;

  /// Signal seen by the parent (AP) → child direction (GetBackhaulInfo2 apRSSI).
  final int? backhaulApRssi;

  /// Signal seen by the child (station) → parent direction (GetBackhaulInfo2 stationRSSI).
  final int? backhaulStationRssi;

  /// Operating channel of the backhaul radio (GetBackhaulInfo2 channel).
  final int? backhaulChannel;

  /// Radio used for backhaul (e.g. "5GL", "5GH") from GetBackhaulInfo2 radioID.
  final String? backhaulRadioId;

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
    this.backhaulApRssi,
    this.backhaulStationRssi,
    this.backhaulChannel,
    this.backhaulRadioId,
  });

  /// Signal quality of the worst direction (parent→child or child→parent).
  /// Uses [backhaulApRssi] when available, falls back to [backhaulRssi].
  int? get _effectiveRssi =>
      backhaulApRssi ?? backhaulRssi;

  bool get hasWeakBackhaul =>
      _effectiveRssi != null && _effectiveRssi! < -70 && !isController;

  bool get hasWiredBackhaul => backhaulType == 'Wired';

  /// Four-tier health classification used for customer-facing display.
  BackhaulHealth get backhaulHealth {
    if (isController) return BackhaulHealth.unknown;
    if (hasWiredBackhaul) return BackhaulHealth.strong;
    final speed = backhaulSpeedMbps;
    final signal = _effectiveRssi;
    if (speed == null && signal == null) return BackhaulHealth.unknown;
    // Critical: very poor — definitely causing issues
    if ((speed != null && speed < 30) || (signal != null && signal < -82)) {
      return BackhaulHealth.critical;
    }
    // Weak: likely causing slowness, jitter, or drops
    if ((speed != null && speed < 80) || (signal != null && signal < -72)) {
      return BackhaulHealth.weak;
    }
    // Moderate: ok but may cause occasional slowness under load
    if ((speed != null && speed < 150) || (signal != null && signal < -62)) {
      return BackhaulHealth.moderate;
    }
    return BackhaulHealth.strong;
  }

  String get backhaulLabel {
    if (isController) return 'Main Router';
    if (backhaulType == 'Wired') return 'Wired backhaul';
    if (_effectiveRssi != null) return 'Wireless ${_effectiveRssi} dBm';
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
        backhaulApRssi,
        backhaulStationRssi,
        backhaulChannel,
        backhaulRadioId,
      ];
}

enum BackhaulHealth {
  unknown,   // no data yet
  strong,    // ≥ 150 Mbps and signal ≥ -62 dBm
  moderate,  // 80-150 Mbps or signal -62 to -72 — may cause occasional slowness
  weak,      // 30-80 Mbps or signal -72 to -82 — likely causing issues
  critical,  // < 30 Mbps or signal < -82 — definitely causing problems
}
