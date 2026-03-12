import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

export 'package:privacy_gui/generated/wifi_clients.g.dart' show WifiClient;

/// Fetches WiFi clients and returns a map keyed by uppercase MAC → [WifiClient].
///
/// Delegates to codegen-generated [WifiClients.fetch] which handles the nested
/// multi-instance parsing (AccessPoint.{i}.AssociatedDevice.{j}).
Future<Map<String, WifiClient>> fetchWifiClients(UspService client) async {
  final result = await WifiClients.fetch(client);
  return {
    for (final c in result.items)
      if (c.macAddress.isNotEmpty) c.macAddress.toUpperCase(): c,
  };
}

/// Connection detail for a WiFi client: band + SSID name.
class ClientConnectionDetail {
  final String band; // "2.4GHz", "5GHz", "6GHz", or ""
  final String ssidName; // The network name

  const ClientConnectionDetail({required this.band, required this.ssidName});
}

/// Builds a lookup map: uppercase MAC → [ClientConnectionDetail].
///
/// Cross-references:
///   WifiClient.parentPath → AccessPoint.ssidReference → SSID.ssid
///                                                     → SSID.lowerLayers → Radio.operatingFrequencyBand
Map<String, ClientConnectionDetail> buildConnectionDetailMap({
  required Map<String, WifiClient> wifiClientMap,
  required WiFiAccessPoints accessPoints,
  required WiFiSsids ssids,
  required WiFiRadios radios,
}) {
  // Build lookup maps with normalized paths (ensure trailing dot)
  // Codegen instancePath always has trailing dot, but SSIDReference and
  // LowerLayers from the router may or may not include it.
  final apByPath = {
    for (final ap in accessPoints.items)
      _ensureTrailingDot(ap.instancePath): ap,
  };
  final ssidByPath = {
    for (final s in ssids.items) _ensureTrailingDot(s.instancePath): s,
  };
  final bandByRadioPath = {
    for (final r in radios.items)
      _ensureTrailingDot(r.instancePath):
          _normalizeBand(r.operatingFrequencyBand),
  };

  logger.d('[USP] Connection detail: '
      '${apByPath.length} APs, ${ssidByPath.length} SSIDs, ${bandByRadioPath.length} radios');

  final result = <String, ClientConnectionDetail>{};
  for (final entry in wifiClientMap.entries) {
    final mac = entry.key;
    final client = entry.value;

    // parentPath = "Device.WiFi.AccessPoint.1." (from codegen, always has dot)
    final ap = apByPath[_ensureTrailingDot(client.parentPath)];
    if (ap == null) {
      logger.d(
          '[USP] Connection detail: no AP for parentPath=${client.parentPath}');
      continue;
    }

    // ssidReference may be "Device.WiFi.SSID.1" or "Device.WiFi.SSID.1."
    final ssid = ssidByPath[_ensureTrailingDot(ap.ssidReference)];
    final ssidName = ssid?.ssid ?? '';

    // lowerLayers may be "Device.WiFi.Radio.1" or "Device.WiFi.Radio.1."
    final band = ssid != null
        ? (bandByRadioPath[_ensureTrailingDot(ssid.lowerLayers)] ?? '')
        : '';

    logger.d('[USP] Connection detail: $mac → '
        'AP=${ap.instancePath}, ssidRef=${ap.ssidReference}, '
        'ssid=$ssidName, lowerLayers=${ssid?.lowerLayers}, band=$band');

    result[mac] = ClientConnectionDetail(band: band, ssidName: ssidName);
  }
  return result;
}

/// Ensures a TR-181 path ends with a dot.
///
/// Router responses may return references like "Device.WiFi.SSID.1"
/// while codegen instancePaths always include the trailing dot.
String _ensureTrailingDot(String path) {
  if (path.isEmpty) return path;
  return path.endsWith('.') ? path : '$path.';
}

/// Normalizes TR-181 OperatingFrequencyBand to a display string.
String _normalizeBand(String rawBand) {
  final lower = rawBand.toLowerCase();
  if (lower.contains('6g') || lower.contains('6 g')) return '6GHz';
  if (lower.contains('5g') || lower.contains('5 g')) return '5GHz';
  if (lower.contains('2.4') || lower.contains('2_4')) return '2.4GHz';
  return rawBand;
}
