import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/utils/wifi.dart';

/// WiFi connection details for a client device.
///
/// Encapsulates signal strength, band, SSID, and throughput metrics.
/// Null fields indicate data not available (e.g., wired device or no enrichment).
class WifiConnectionInfo with EquatableMixin {
  /// Signal strength in dBm (RSSI). Typically -30 to -90.
  final int? signalStrength;

  /// WiFi band: "2.4GHz", "5GHz", or "6GHz".
  final String? band;

  /// SSID name the client is connected to.
  final String? ssidName;

  /// Downlink data rate in kbps.
  final int? downlinkRate;

  /// Uplink data rate in kbps.
  final int? uplinkRate;

  const WifiConnectionInfo({
    this.signalStrength,
    this.band,
    this.ssidName,
    this.downlinkRate,
    this.uplinkRate,
  });

  /// Signal quality as a normalized value (0.0–1.0).
  ///
  /// -30 dBm (excellent) → 1.0, -90 dBm (poor) → 0.0.
  double get signalQuality {
    if (signalStrength == null) return 0;
    return ((signalStrength! + 90) / 60).clamp(0.0, 1.0);
  }

  /// Signal level (0–3) using standard RSSI thresholds.
  ///
  /// 3 = Excellent (>= -65), 2 = Good, 1 = Fair, 0 = Poor.
  int get signalLevel {
    if (signalStrength == null) return 0;
    return switch (getWifiSignalLevel(signalStrength)) {
      NodeSignalLevel.excellent => 3,
      NodeSignalLevel.good => 2,
      NodeSignalLevel.fair => 1,
      NodeSignalLevel.poor || NodeSignalLevel.none => 0,
      NodeSignalLevel.wired => 0,
    };
  }

  /// Total throughput in kbps (downlink + uplink).
  int get totalThroughput => (downlinkRate ?? 0) + (uplinkRate ?? 0);

  /// Whether any WiFi data is available.
  bool get hasData =>
      signalStrength != null ||
      band != null ||
      ssidName != null ||
      downlinkRate != null ||
      uplinkRate != null;

  @override
  List<Object?> get props => [
        signalStrength,
        band,
        ssidName,
        downlinkRate,
        uplinkRate,
      ];
}
