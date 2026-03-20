import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';

/// Fetches WiFi clients and returns a map keyed by uppercase MAC → [WifiClient].
///
/// Delegates to codegen-generated [WifiClients.fetch] which handles the nested
/// multi-instance parsing (AccessPoint.{i}.AssociatedDevice.{j}).
///
/// If the selective-get wildcard paths return empty (possible USP agent
/// limitation), falls back to a broader parent-path fetch and manual parse.
Future<Map<String, WifiClient>> fetchWifiClients(UspService client) async {
  final result = await WifiClients.fetch(client);
  logger.d('[USP][Dashboard]WifiClients raw: ${result.items.length} items');

  if (result.items.isNotEmpty) {
    return {
      for (final c in result.items)
        if (c.macAddress.isNotEmpty) c.macAddress.toUpperCase(): c,
    };
  }

  // Fallback: selective-get with nested wildcards may not be supported by
  // some USP agents. Try fetching the whole AssociatedDevice subtree instead.
  logger.d(
      '[USP][Dashboard]WifiClients selective-get empty, trying parent-path fallback');
  try {
    final fallback = await _fetchWifiClientsFallback(client);
    if (fallback.isNotEmpty) {
      logger.d(
          '[USP][Dashboard]WifiClients fallback: ${fallback.length} clients');
    }
    return fallback;
  } catch (e) {
    logger.d('[USP][Dashboard]WifiClients fallback failed: $e');
    return {};
  }
}

/// Fallback fetch using parent object path (non-selective).
///
/// Requests `Device.WiFi.AccessPoint.*.AssociatedDevice.` which returns
/// ALL parameters under each AssociatedDevice instance. Then manually
/// parses the response map into [WifiClient] objects.
Future<Map<String, WifiClient>> _fetchWifiClientsFallback(
    UspService client) async {
  final response = await client.get([
    'Device.WiFi.AccessPoint.*.AssociatedDevice.',
  ]);
  logger.d(
      '[USP][Dashboard]WifiClients fallback response: ${response.length} keys');
  if (response.isEmpty) return {};

  // Parse response keys to find AP and AssociatedDevice instance IDs.
  // Key format: Device.WiFi.AccessPoint.{apId}.AssociatedDevice.{devId}.{Param}
  const basePath = 'Device.WiFi.AccessPoint.';
  final apIds = <String>{};
  for (final key in response.keys) {
    if (key.startsWith(basePath)) {
      final rest = key.substring(basePath.length);
      final dot = rest.indexOf('.');
      if (dot > 0) apIds.add(rest.substring(0, dot));
    }
  }

  final result = <String, WifiClient>{};
  for (final apId in apIds) {
    final childBase = '$basePath$apId.AssociatedDevice.';
    final childIds = <String>{};
    for (final key in response.keys) {
      if (key.startsWith(childBase)) {
        final rest = key.substring(childBase.length);
        final dot = rest.indexOf('.');
        if (dot > 0) childIds.add(rest.substring(0, dot));
      }
    }

    for (final devId in childIds) {
      final cp = '$childBase$devId.';
      final mac = (response['${cp}MACAddress'] ?? '').toString();
      if (mac.isEmpty) continue;

      final wc = WifiClient(
        instancePath: cp,
        parentPath: '$basePath$apId.',
        macAddress: mac,
        signalStrength:
            int.tryParse(response['${cp}SignalStrength']?.toString() ?? '') ??
                0,
        noise: int.tryParse(response['${cp}Noise']?.toString() ?? '') ?? 0,
        lastDataDownlinkRate: int.tryParse(
                response['${cp}LastDataDownlinkRate']?.toString() ?? '') ??
            0,
        lastDataUplinkRate: int.tryParse(
                response['${cp}LastDataUplinkRate']?.toString() ?? '') ??
            0,
        active: response['${cp}Active'] == true ||
            response['${cp}Active'] == 'true' ||
            response['${cp}Active'] == '1',
      );

      result[mac.toUpperCase()] = wc;
    }
  }
  return result;
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

  logger.d('[USP][Dashboard]Connection detail: '
      '${apByPath.length} APs, ${ssidByPath.length} SSIDs, ${bandByRadioPath.length} radios');

  final result = <String, ClientConnectionDetail>{};
  for (final entry in wifiClientMap.entries) {
    final mac = entry.key;
    final client = entry.value;

    // parentPath = "Device.WiFi.AccessPoint.1." (from codegen, always has dot)
    final ap = apByPath[_ensureTrailingDot(client.parentPath)];
    if (ap == null) {
      logger.d(
          '[USP][Dashboard]Connection detail: no AP for parentPath=${client.parentPath}');
      continue;
    }

    // ssidReference may be "Device.WiFi.SSID.1" or "Device.WiFi.SSID.1."
    final ssid = ssidByPath[_ensureTrailingDot(ap.ssidReference)];
    final ssidName = ssid?.ssid ?? '';

    // lowerLayers may be "Device.WiFi.Radio.1" or "Device.WiFi.Radio.1."
    final band = ssid != null
        ? (bandByRadioPath[_ensureTrailingDot(ssid.lowerLayers)] ?? '')
        : '';

    logger.d('[USP][Dashboard]Connection detail: $mac → '
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

/// Converts a raw codegen [WifiClient] map to [WifiClientUIModel] map.
///
/// Call this after [buildConnectionDetailMap] (which needs raw parentPath)
/// to produce the UI-safe type for storage in [WifiData].
Map<String, WifiClientUIModel> toWifiClientUIModels(
    Map<String, WifiClient> raw) {
  return raw.map((mac, c) => MapEntry(
        mac,
        WifiClientUIModel(
          macAddress: c.macAddress,
          signalStrength: c.signalStrength,
          noise: c.noise,
          lastDataDownlinkRate: c.lastDataDownlinkRate,
          lastDataUplinkRate: c.lastDataUplinkRate,
          active: c.active,
        ),
      ));
}
