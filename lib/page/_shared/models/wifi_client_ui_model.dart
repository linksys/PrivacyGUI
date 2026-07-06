import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation-layer model for a WiFi associated device.
///
/// Contains only the fields that Views and UI helpers need.
/// Decouples the UI from the codegen `WifiClient` type.
class WifiClientUIModel extends Equatable with DiagnosticLoggable {
  final String macAddress;
  final int signalStrength; // RSSI in dBm
  final int noise; // noise floor in dBm
  final int lastDataDownlinkRate; // kbps
  final int lastDataUplinkRate; // kbps
  final bool active;

  const WifiClientUIModel({
    required this.macAddress,
    required this.signalStrength,
    required this.noise,
    required this.lastDataDownlinkRate,
    required this.lastDataUplinkRate,
    required this.active,
  });

  @override
  Map<String, Object?> get namedProps => {
        'macAddress': macAddress,
        'signalStrength': signalStrength,
        'noise': noise,
        'lastDataDownlinkRate': lastDataDownlinkRate,
        'lastDataUplinkRate': lastDataUplinkRate,
        'active': active,
      };
}
