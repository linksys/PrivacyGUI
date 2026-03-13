import 'package:equatable/equatable.dart';

/// Presentation Layer Model for a WiFi radio with its access points.
class WifiRadioUIModel extends Equatable {
  final String instancePath;
  final String band; // "2.4GHz", "5GHz", "6GHz"
  final bool enable;
  final int transmitPower; // -1 means max
  final int maxBitRate; // Mbps
  final int channel;
  final bool autoChannelEnable;
  final String channelBandwidth;
  final String supportedStandards;

  /// Access points grouped under this radio.
  final List<WifiAccessPointUIModel> accessPoints;

  const WifiRadioUIModel({
    required this.instancePath,
    required this.band,
    required this.enable,
    required this.transmitPower,
    required this.maxBitRate,
    required this.channel,
    required this.autoChannelEnable,
    required this.channelBandwidth,
    required this.supportedStandards,
    this.accessPoints = const [],
  });

  /// Tx power display: "Max" if -1, otherwise "X%".
  int get txPowerPercent =>
      transmitPower == -1 ? 100 : transmitPower.clamp(0, 100);

  String get txPowerDisplay => transmitPower == -1 ? 'Max' : '$txPowerPercent%';

  /// Channel display: "6 (Auto)" or "6".
  String get channelDisplay => '$channel${autoChannelEnable ? ' (Auto)' : ''}';

  /// Bit rate normalized to 0–100 scale based on band max.
  double get bitRateNormalized {
    final maxForBand = band.contains('6')
        ? 9600
        : band.contains('5')
            ? 4800
            : 600;
    return (maxBitRate / maxForBand * 100).clamp(0, 100).toDouble();
  }

  @override
  List<Object?> get props => [
        instancePath,
        band,
        enable,
        transmitPower,
        maxBitRate,
        channel,
        autoChannelEnable,
        channelBandwidth,
        supportedStandards,
        accessPoints,
      ];
}

/// Presentation Layer Model for a WiFi access point.
class WifiAccessPointUIModel extends Equatable {
  final bool enable;
  final String ssidName; // Resolved from SSID reference
  final String securityMode;
  final String encryptionMode;

  const WifiAccessPointUIModel({
    required this.enable,
    required this.ssidName,
    required this.securityMode,
    required this.encryptionMode,
  });

  @override
  List<Object?> get props => [enable, ssidName, securityMode, encryptionMode];
}
