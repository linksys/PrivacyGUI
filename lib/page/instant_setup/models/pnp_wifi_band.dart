import 'package:equatable/equatable.dart';

/// Per-band WiFi configuration for PnP wizard (split SSID mode).
///
/// Each band (2.4GHz, 5GHz, 6GHz) can have its own SSID/password.
/// Used when router ships with split SSIDs per band (e.g. Du ISP routers).
class PnpWifiBand extends Equatable {
  /// Human-readable band name (e.g. "2.4 GHz", "5 GHz", "6 GHz").
  final String bandName;

  /// Operating frequency (e.g. "2.4GHz", "5GHz", "6GHz") for display/sorting.
  final String frequency;

  /// Current SSID value (editable).
  final String ssid;

  /// Current password value (editable).
  final String password;

  /// Original SSID from router (for dirty detection).
  final String originalSsid;

  /// Original password from router (for dirty detection).
  final String originalPassword;

  /// TR-181 instance path for WiFi.SSID object.
  final String ssidInstancePath;

  /// TR-181 instance path for WiFi.AccessPoint object.
  final String accessPointInstancePath;

  /// Radio instance path (LowerLayers) for grouping bands.
  final String radioPath;

  const PnpWifiBand({
    required this.bandName,
    required this.frequency,
    required this.ssid,
    required this.password,
    required this.originalSsid,
    required this.originalPassword,
    required this.ssidInstancePath,
    required this.accessPointInstancePath,
    required this.radioPath,
  });

  bool get isSsidChanged => ssid != originalSsid;
  bool get isPasswordChanged => password != originalPassword;
  bool get isDirty => isSsidChanged || isPasswordChanged;

  PnpWifiBand copyWith({
    String? ssid,
    String? password,
  }) {
    return PnpWifiBand(
      bandName: bandName,
      frequency: frequency,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      originalSsid: originalSsid,
      originalPassword: originalPassword,
      ssidInstancePath: ssidInstancePath,
      accessPointInstancePath: accessPointInstancePath,
      radioPath: radioPath,
    );
  }

  @override
  List<Object?> get props => [
        bandName,
        frequency,
        ssid,
        password,
        originalSsid,
        originalPassword,
        ssidInstancePath,
        accessPointInstancePath,
        radioPath,
      ];
}

/// Determines the display band name from the radio's OperatingFrequencyBand.
String bandNameFromFrequency(String operatingFrequencyBand) {
  final freq = operatingFrequencyBand.toLowerCase();
  if (freq.contains('2.4')) return '2.4 GHz';
  if (freq.contains('5')) return '5 GHz';
  if (freq.contains('6')) return '6 GHz';
  return operatingFrequencyBand;
}

/// Returns a sortable frequency key for ordering bands (2.4 < 5 < 6).
int frequencySortKey(String frequency) {
  if (frequency.contains('2.4')) return 1;
  if (frequency.contains('5')) return 2;
  if (frequency.contains('6')) return 3;
  return 99;
}
