import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// WiFi connection details for a client device.
///
/// Encapsulates signal strength, band, SSID, and throughput metrics.
/// Null fields indicate data not available (e.g., wired device or no enrichment).
class WifiConnectionInfo with EquatableMixin, DiagnosticNamed {
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

  /// The bands the client is on together, when it is on MLO (#1686 item 2):
  /// for example `['2.4GHz', '5GHz']`. Null when it is not, or not known.
  ///
  /// Kept apart from [band] on purpose. [band] is the key the device filter,
  /// the analytics band split and the PDF group by, and an MLO label there
  /// would become a band of its own; it stays the band the client associated
  /// on. The view shows `MLO (…)` from this instead.
  final List<String>? mloBands;

  /// Whether the router's MLO data could not be read, so it is not known
  /// whether this client is on MLO. The view says so rather than showing the
  /// client as if it were not.
  final bool mloUnknown;

  const WifiConnectionInfo({
    this.signalStrength,
    this.band,
    this.ssidName,
    this.downlinkRate,
    this.uplinkRate,
    this.mloBands,
    this.mloUnknown = false,
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
        mloBands,
        mloUnknown,
      ];

  @override
  String get diagnosticName => 'WifiConnectionInfo';

  @override
  Map<String, Object?> get namedProps => {
        'signalStrength': signalStrength,
        'band': band,
        'ssidName': ssidName,
        'downlinkRate': downlinkRate,
        'uplinkRate': uplinkRate,
        'mloBands': mloBands,
        'mloUnknown': mloUnknown,
      };
}
