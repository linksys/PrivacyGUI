import 'package:privacy_gui/usp/services/usp_service.dart';

/// WiFi client signal info parsed from Device.WiFi.AccessPoint.{i}.AssociatedDevice.{j}.
class WifiClientInfo {
  final String macAddress;
  final int signalStrength; // RSSI in dBm (e.g. -45)
  final int noise; // Noise level in dBm
  final int lastDataDownlinkRate; // kbps
  final int lastDataUplinkRate; // kbps
  final bool active;
  final int apIndex; // Which AccessPoint instance this client is on

  const WifiClientInfo({
    required this.macAddress,
    required this.signalStrength,
    required this.noise,
    required this.lastDataDownlinkRate,
    required this.lastDataUplinkRate,
    required this.active,
    required this.apIndex,
  });
}

/// Fetches the full AccessPoint subtree and parses nested AssociatedDevice instances.
///
/// Returns a map keyed by uppercase MAC address → [WifiClientInfo].
/// Ethernet-connected devices will NOT appear here (only WiFi clients).
Future<Map<String, WifiClientInfo>> fetchWifiClients(UspService client) async {
  final response = await client.get(['Device.WiFi.AccessPoint.']);
  return parseWifiClients(response);
}

/// Parses nested AssociatedDevice instances from a flat USP response map.
///
/// The response contains keys like:
///   Device.WiFi.AccessPoint.1.AssociatedDevice.2.MACAddress = "AA:BB:CC:DD:EE:FF"
///   Device.WiFi.AccessPoint.1.AssociatedDevice.2.SignalStrength = -45
Map<String, WifiClientInfo> parseWifiClients(Map<String, dynamic> response) {
  final result = <String, WifiClientInfo>{};
  const basePath = 'Device.WiFi.AccessPoint.';

  // Step 1: Find all AP instance IDs
  final apIds = <String>{};
  for (final key in response.keys) {
    if (key.startsWith(basePath)) {
      final rest = key.substring(basePath.length);
      final dot = rest.indexOf('.');
      if (dot > 0) apIds.add(rest.substring(0, dot));
    }
  }

  // Step 2: For each AP, find nested AssociatedDevice instances
  for (final apId in apIds) {
    final adPrefix = '$basePath$apId.AssociatedDevice.';

    final adIds = <String>{};
    for (final key in response.keys) {
      if (key.startsWith(adPrefix)) {
        final rest = key.substring(adPrefix.length);
        final dot = rest.indexOf('.');
        if (dot > 0) adIds.add(rest.substring(0, dot));
      }
    }

    // Step 3: Parse each AssociatedDevice instance
    for (final adId in adIds) {
      final p = '$adPrefix$adId.';
      final mac = '${response['${p}MACAddress'] ?? ''}'.trim();
      if (mac.isEmpty) continue;

      result[mac.toUpperCase()] = WifiClientInfo(
        macAddress: mac,
        signalStrength: _parseInt(response['${p}SignalStrength']),
        noise: _parseInt(response['${p}Noise']),
        lastDataDownlinkRate: _parseInt(response['${p}LastDataDownlinkRate']),
        lastDataUplinkRate: _parseInt(response['${p}LastDataUplinkRate']),
        active: response['${p}Active'] == true ||
            response['${p}Active'] == 'true',
        apIndex: int.tryParse(apId) ?? 0,
      );
    }
  }

  return result;
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
