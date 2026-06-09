import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/utils/wifi.dart';

/// Device health score calculated from signal strength and data rate.
class DeviceScoreUIModel extends Equatable {
  final String macAddress;
  final String name;
  final int? rssiDbm;
  final int? downlinkKbps;
  final int? uplinkKbps;
  final bool isWireless;

  const DeviceScoreUIModel({
    required this.macAddress,
    required this.name,
    this.rssiDbm,
    this.downlinkKbps,
    this.uplinkKbps,
    this.isWireless = true,
  });

  DeviceScoreUIModel copyWith({
    String? macAddress,
    String? name,
    int? rssiDbm,
    int? downlinkKbps,
    int? uplinkKbps,
    bool? isWireless,
  }) {
    return DeviceScoreUIModel(
      macAddress: macAddress ?? this.macAddress,
      name: name ?? this.name,
      rssiDbm: rssiDbm ?? this.rssiDbm,
      downlinkKbps: downlinkKbps ?? this.downlinkKbps,
      uplinkKbps: uplinkKbps ?? this.uplinkKbps,
      isWireless: isWireless ?? this.isWireless,
    );
  }

  /// Signal strength score (0-100).
  /// Wired devices get 100 (no signal issues).
  int get signalScore =>
      !isWireless ? 100 : (rssiDbm == null ? 100 : _rssiToScore(rssiDbm!));

  /// Data rate score (0-100).
  int get dataRateScore =>
      downlinkKbps == null ? 100 : _rateToScore(downlinkKbps!);

  /// Overall device health score (average of signal and data rate).
  int get overallScore => (signalScore + dataRateScore) ~/ 2;

  /// Whether this device has potential issues (score < 50).
  bool get hasIssue => isWireless && overallScore < 50;

  /// Whether signal is weak (below rssiGood threshold).
  bool get hasWeakSignal =>
      isWireless && rssiDbm != null && rssiDbm! < rssiGood;

  /// Whether data rate is low (< 20 Mbps).
  bool get hasLowDataRate =>
      downlinkKbps != null && downlinkKbps! < 20000; // 20 Mbps

  /// Convert RSSI (dBm) to score (0-100) using wifi.dart thresholds.
  static int _rssiToScore(int rssi) {
    if (rssi >= rssiExcellent) return 100; // Excellent
    if (rssi >= rssiGood) return 80; // Good
    if (rssi >= rssiFair) return 60; // Fair
    return 40; // Weak
  }

  /// Convert data rate (kbps) to score (0-100).
  static int _rateToScore(int kbps) {
    final mbps = kbps / 1000;
    if (mbps >= 100) return 100; // Excellent
    if (mbps >= 50) return 80; // Good
    if (mbps >= 20) return 60; // Fair
    if (mbps >= 10) return 40; // Slow
    return 20; // Very slow
  }

  /// Human-readable signal strength label using wifi.dart thresholds.
  String get signalLabel {
    if (!isWireless) return 'Wired';
    if (rssiDbm == null) return 'Unknown';
    if (rssiDbm! >= rssiExcellent) return 'Excellent';
    if (rssiDbm! >= rssiGood) return 'Good';
    if (rssiDbm! >= rssiFair) return 'Fair';
    return 'Weak';
  }

  /// Human-readable data rate label.
  String get dataRateLabel {
    if (downlinkKbps == null) return 'Unknown';
    final mbps = downlinkKbps! / 1000;
    if (mbps >= 100) return 'Fast';
    if (mbps >= 50) return 'Good';
    if (mbps >= 20) return 'Moderate';
    if (mbps >= 10) return 'Slow';
    return 'Very Slow';
  }

  @override
  List<Object?> get props => [
        macAddress,
        name,
        rssiDbm,
        downlinkKbps,
        uplinkKbps,
        isWireless,
      ];
}
