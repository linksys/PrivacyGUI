import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';

final uspWifiSettingsServiceProvider =
    Provider<UspWifiSettingsService>((_) => UspWifiSettingsService());

/// Stateless service for transforming raw USP WiFi data into [WifiNetworkUIModel] list.
///
/// Cross-references three TR-181 collections:
///   - Device.WiFi.SSID.{i}          (ssid, enable, advertisement)
///   - Device.WiFi.AccessPoint.{i}   (security mode, passphrase, MAC control)
///   - Device.WiFi.Radio.{i}         (band, channel, bandwidth)
///
/// Relationship:
///   SSID.lowerLayers  → Radio instance path
///   AccessPoint.ssidReference → SSID instance path
class UspWifiSettingsService {
  /// Builds a list of [WifiNetworkUIModel], one per SSID instance.
  ///
  /// Ordering follows the SSID instance ID sort (numeric), which matches
  /// the band ordering (e.g. SSID.1=2.4GHz, SSID.2=5GHz, SSID.3=6GHz).
  List<WifiNetworkUIModel> buildWifiNetworks({
    required WiFiSsids ssids,
    required WiFiAccessPoints accessPoints,
    required WiFiRadios radios,
  }) {
    // Build lookup maps with normalized trailing-dot paths
    final apBySsidRef = <String, WiFiAccessPoint>{};
    for (final ap in accessPoints.items) {
      final key = _ensureTrailingDot(ap.ssidReference);
      if (key.isNotEmpty) apBySsidRef[key] = ap;
    }

    final radioByPath = <String, WiFiRadio>{};
    for (final r in radios.items) {
      radioByPath[_ensureTrailingDot(r.instancePath)] = r;
    }

    logger.d('[WiFiSettings] Building networks: '
        '${ssids.items.length} SSIDs, '
        '${accessPoints.items.length} APs, '
        '${radios.items.length} radios');

    final networks = <WifiNetworkUIModel>[];
    for (final ssid in ssids.items) {
      final ssidPath = _ensureTrailingDot(ssid.instancePath);

      // Find matching AccessPoint via ssidReference
      final ap = apBySsidRef[ssidPath];

      // Find matching Radio via SSID.lowerLayers
      final radioPath = _ensureTrailingDot(ssid.lowerLayers);
      final radio = radioByPath[radioPath];

      logger.d('[WiFiSettings] SSID ${ssid.ssid}: '
          'AP=${ap?.instancePath ?? "none"}, '
          'radio=${radio?.operatingFrequencyBand ?? "none"}');

      networks.add(WifiNetworkUIModel(
        ssidInstancePath: ssid.instancePath,
        accessPointInstancePath: ap?.instancePath,
        radioInstancePath: radio?.instancePath,
        ssid: ssid.ssid,
        enabled: ssid.enable,
        ssidAdvertisementEnabled: ssid.ssidAdvertisementEnabled,
        securityMode: ap?.securityModeEnabled ?? '',
        keyPassphrase: ap?.keyPassphrase ?? '',
        macAddressControlEnabled: ap?.macAddressControlEnabled ?? false,
        band: _normalizeBand(radio?.operatingFrequencyBand ?? ''),
        channel: radio?.channel ?? 0,
        channelBandwidth: radio?.operatingChannelBandwidth ?? '',
        autoChannelEnable: radio?.autoChannelEnable ?? true,
      ));
    }

    return networks;
  }
}

/// Ensures a TR-181 path ends with a dot.
String _ensureTrailingDot(String path) {
  if (path.isEmpty) return path;
  return path.endsWith('.') ? path : '$path.';
}

/// Normalizes TR-181 OperatingFrequencyBand to display string.
String _normalizeBand(String rawBand) {
  final lower = rawBand.toLowerCase();
  if (lower.contains('6g') || lower.contains('6 g')) return '6GHz';
  if (lower.contains('5g') || lower.contains('5 g')) return '5GHz';
  if (lower.contains('2.4') || lower.contains('2_4')) return '2.4GHz';
  return rawBand;
}
