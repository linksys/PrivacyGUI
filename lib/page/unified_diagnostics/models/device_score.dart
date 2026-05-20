import 'package:equatable/equatable.dart';

/// Device health score calculated from signal strength and data rate.
class DeviceScore extends Equatable {
  final String macAddress;
  final String name;
  final int? rssiDbm;
  final int? downlinkKbps;
  final int? uplinkKbps;
  final bool isWireless;

  const DeviceScore({
    required this.macAddress,
    required this.name,
    this.rssiDbm,
    this.downlinkKbps,
    this.uplinkKbps,
    this.isWireless = true,
  });

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

  /// Whether signal is weak (< -70 dBm).
  bool get hasWeakSignal => isWireless && rssiDbm != null && rssiDbm! < -70;

  /// Whether data rate is low (< 20 Mbps).
  bool get hasLowDataRate =>
      downlinkKbps != null && downlinkKbps! < 20000; // 20 Mbps

  /// Convert RSSI (dBm) to score (0-100).
  static int _rssiToScore(int rssi) {
    if (rssi >= -50) return 100; // Excellent
    if (rssi >= -60) return 80; // Good
    if (rssi >= -70) return 60; // Fair
    if (rssi >= -80) return 40; // Weak
    return 20; // Very weak
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

  /// Human-readable signal strength label.
  String get signalLabel {
    if (!isWireless) return 'Wired';
    if (rssiDbm == null) return 'Unknown';
    if (rssiDbm! >= -50) return 'Excellent';
    if (rssiDbm! >= -60) return 'Good';
    if (rssiDbm! >= -70) return 'Fair';
    if (rssiDbm! >= -80) return 'Weak';
    return 'Very Weak';
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
