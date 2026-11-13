import 'package:equatable/equatable.dart';

/// One band of a split-SSID network in the PnP wizard.
///
/// Each band (2.4GHz, 5GHz, 6GHz) can have its own SSID/password. Used when
/// the router ships with split SSIDs per band (e.g. Du ISP routers).
///
/// No "original" values of its own since #1511 P4: the band sits inside a
/// step's draft, and the draft's `Preservable` holds the band as the router
/// had it — matched by [ssidInstancePath].
class PnpWifiBand extends Equatable {
  /// Human-readable band name (e.g. "2.4 GHz", "5 GHz", "6 GHz").
  final String bandName;

  /// Operating frequency (e.g. "2.4GHz", "5GHz", "6GHz") for display/sorting.
  final String frequency;

  /// SSID (editable).
  final String ssid;

  /// Password (editable).
  final String password;

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
    required this.ssidInstancePath,
    required this.accessPointInstancePath,
    required this.radioPath,
  });

  PnpWifiBand copyWith({
    String? ssid,
    String? password,
  }) {
    return PnpWifiBand(
      bandName: bandName,
      frequency: frequency,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
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
        ssidInstancePath,
        accessPointInstancePath,
        radioPath,
      ];
}

/// [band] as [original] holds it — the same SSID row before the edits — or
/// [band] itself when [original] has no such row.
///
/// Bands are never added or removed by an edit, so the fallback only answers
/// a caller that pairs the wrong lists, and then answers "unchanged".
PnpWifiBand bandAsRead(List<PnpWifiBand> original, PnpWifiBand band) =>
    original.firstWhere(
      (b) => b.ssidInstancePath == band.ssidInstancePath,
      orElse: () => band,
    );

/// The stable key of [band] in an E2E identifier (constitution Article XVI
/// §16.3): its frequency, slugged — `2.4GHz` → `2-4ghz` — or, with no
/// frequency, the SSID row's instance number, or `unnamed`. Derived from the
/// band's data, never from its position in the list. `all` for a unified
/// network, which has one set of fields for every band.
String pnpBandIdentifierKey(PnpWifiBand? band) {
  if (band == null) return 'all';
  final slug = band.frequency
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isNotEmpty) return slug;
  final instance = RegExp(r'(\d+)\.?$').firstMatch(band.ssidInstancePath);
  return instance?.group(1) ?? 'unnamed';
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
