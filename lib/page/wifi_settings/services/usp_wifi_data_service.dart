import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspWifiDataServiceProvider = Provider<UspWifiDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspWifiDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Opaque codegen context (only WiFi-domain services can consume)
// ---------------------------------------------------------------------------

/// Opaque wrapper around raw WiFi codegen data.
///
/// External consumers hold this without accessing the inner codegen types.
/// Only WiFi-domain services ([UspWifiSettingsService])
/// consume it via the typed accessor.
class WifiCodegenContext extends Equatable {
  final WiFiRadios _radios;
  final WiFiSsids _ssids;
  final WiFiAccessPoints _accessPoints;

  const WifiCodegenContext(this._radios, this._ssids, this._accessPoints);

  static const empty = WifiCodegenContext(
    WiFiRadios(items: []),
    WiFiSsids(items: []),
    WiFiAccessPoints(items: []),
  );

  /// Destructure for WiFi-domain service consumption.
  ({WiFiRadios radios, WiFiSsids ssids, WiFiAccessPoints accessPoints})
      get raw => (radios: _radios, ssids: _ssids, accessPoints: _accessPoints);

  @override
  List<Object?> get props =>
      [_radios.items.length, _ssids.items.length, _accessPoints.items.length];
}

// ---------------------------------------------------------------------------
// Fetch result
// ---------------------------------------------------------------------------

/// Result of a WiFi data fetch, returned by [UspWifiDataService.fetch].
class WifiDataFetchResult {
  final WifiCodegenContext codegenContext;
  final Map<String, WifiClientUIModel> wifiClientMap;
  final Map<String, ClientConnectionDetail> connectionDetailMap;
  final List<WifiRadioUIModel> radioModels;

  const WifiDataFetchResult({
    required this.codegenContext,
    required this.wifiClientMap,
    required this.connectionDetailMap,
    required this.radioModels,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching WiFi domain data.
///
/// Owns all codegen calls and error mapping for the WiFi data provider.
/// The provider delegates to this service instead of calling codegen directly.
class UspWifiDataService {
  final UspClient _usp;

  UspWifiDataService(this._usp);

  /// Fetches all WiFi data in parallel and returns a [WifiDataFetchResult].
  ///
  /// Calls codegen fetch methods for radios, SSIDs, access points, and clients.
  /// Builds enrichment maps (connection detail, radio UI models) from the
  /// raw codegen data before returning.
  Future<WifiDataFetchResult> fetch() async {
    final List<Object> results;
    try {
      results = await Future.wait([
        WiFiRadios.fetch(_usp),
        WiFiSsids.fetch(_usp),
        WiFiAccessPoints.fetch(_usp),
        _fetchWifiClients(),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final radios = results[0] as WiFiRadios;
    final ssids = results[1] as WiFiSsids;
    final accessPoints = results[2] as WiFiAccessPoints;
    final rawWifiClientMap = results[3] as Map<String, WifiClient>;

    // Cross-reference AP → SSID → Radio to get band + SSID name per client
    final connectionDetailMap = _buildConnectionDetailMap(
      wifiClientMap: rawWifiClientMap,
      accessPoints: accessPoints,
      ssids: ssids,
      radios: radios,
    );

    // Convert raw codegen → UI model at the service boundary
    final wifiClientMap = _toWifiClientUIModels(rawWifiClientMap);

    // Build radio UI models
    final radioModels = _buildWifiRadioUIModels(
      radios: radios,
      ssids: ssids,
      accessPoints: accessPoints,
    );

    return WifiDataFetchResult(
      codegenContext: WifiCodegenContext(radios, ssids, accessPoints),
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      radioModels: radioModels,
    );
  }

  // ---------------------------------------------------------------------------
  // WiFi Radio UI Models
  // ---------------------------------------------------------------------------

  /// Builds [WifiRadioUIModel] list from raw codegen collections.
  ///
  /// Cross-references three TR-181 collections:
  ///   Radio → (via SSID.lowerLayers) ← SSID ← (via AP.ssidReference) ← AP
  ///
  /// Guest detection: Per-radio instance ordering. Within each radio group,
  /// the lowest-index SSID is Main; all subsequent are Guest.
  List<WifiRadioUIModel> _buildWifiRadioUIModels({
    required WiFiRadios radios,
    required WiFiSsids ssids,
    required WiFiAccessPoints accessPoints,
  }) {
    final ssidByPath = {
      for (final s in ssids.items) _ensureTrailingDot(s.instancePath): s,
    };

    // Determine guest SSIDs: per-radio, lowest instance index is Main
    final guestSsidPaths = <String>{};
    {
      final ssidsByRadio = <String, List<WiFiSsid>>{};
      for (final ssid in ssids.items) {
        final radioKey = _ensureTrailingDot(ssid.lowerLayers);
        (ssidsByRadio[radioKey] ??= []).add(ssid);
      }
      logger.d('[USP][WiFi] ssidsByRadio groups: ${ssidsByRadio.length}');
      for (final entry in ssidsByRadio.entries) {
        final group = entry.value;
        group.sort((a, b) => _ssidInstanceIndex(a.instancePath)
            .compareTo(_ssidInstanceIndex(b.instancePath)));
        logger.d('[USP][WiFi] Radio ${entry.key}: '
            '${group.map((s) => "${s.ssid}(${s.instancePath})").join(", ")}');
        for (final ssid in group.skip(1)) {
          guestSsidPaths.add(_ensureTrailingDot(ssid.instancePath));
          logger.d(
              '[USP][WiFi] Marked as guest: ${ssid.ssid} (${ssid.instancePath})');
        }
      }
    }
    logger.d('[USP][WiFi] Total guest SSID paths: ${guestSsidPaths.length}');

    // Group APs by radio: AP.ssidReference → SSID.lowerLayers → Radio
    final apsByRadioPath =
        <String, List<({WiFiAccessPoint ap, WiFiSsid ssid})>>{};
    for (final ap in accessPoints.items) {
      final ssid = ssidByPath[_ensureTrailingDot(ap.ssidReference)];
      if (ssid == null) continue;
      final radioPath = _ensureTrailingDot(ssid.lowerLayers);
      apsByRadioPath.putIfAbsent(radioPath, () => []).add((ap: ap, ssid: ssid));
    }

    return radios.items.map((radio) {
      final radioAps =
          apsByRadioPath[_ensureTrailingDot(radio.instancePath)] ?? [];
      final apModels = radioAps.map((a) {
        final isGuest =
            guestSsidPaths.contains(_ensureTrailingDot(a.ssid.instancePath));
        // Use SSID.enable as the canonical enabled state (matches toggle mutation)
        return WifiAccessPointUIModel(
          enable: a.ssid.enable,
          ssidName: a.ssid.ssid.isNotEmpty ? a.ssid.ssid : a.ap.ssidReference,
          securityMode: a.ap.securityModeEnabled,
          encryptionMode: a.ap.encryptionMode,
          isGuest: isGuest,
        );
      }).toList();
      return WifiRadioUIModel(
        instancePath: radio.instancePath,
        band: _normalizeBand(radio.operatingFrequencyBand),
        enable: radio.enable,
        transmitPower: radio.transmitPower,
        maxBitRate: radio.maxBitRate,
        channel: radio.channel,
        autoChannelEnable: radio.autoChannelEnable,
        channelBandwidth: radio.operatingChannelBandwidth,
        supportedStandards: radio.supportedStandards,
        possibleChannels: _parsePossibleChannels(radio.possibleChannels),
        accessPoints: apModels,
      );
    }).toList();
  }

  /// Extracts the numeric instance index from a TR-181 SSID path.
  int _ssidInstanceIndex(String instancePath) {
    final match = RegExp(r'Device\.WiFi\.SSID\.(\d+)').firstMatch(instancePath);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  // ---------------------------------------------------------------------------
  // WiFi Clients
  // ---------------------------------------------------------------------------

  /// Fetches WiFi clients and returns a map keyed by uppercase MAC.
  ///
  /// If the selective-get wildcard paths return empty (possible USP agent
  /// limitation), falls back to a broader parent-path fetch and manual parse.
  Future<Map<String, WifiClient>> _fetchWifiClients() async {
    final result = await WifiClients.fetch(_usp);
    logger.d('[USP][Dashboard]: WifiClients raw: ${result.items.length} items');

    if (result.items.isNotEmpty) {
      return {
        for (final c in result.items)
          if (c.macAddress.isNotEmpty) c.macAddress.toUpperCase(): c,
      };
    }

    logger.d(
        '[USP][Dashboard]WifiClients selective-get empty, trying parent-path fallback');
    try {
      final fallback = await _fetchWifiClientsFallback();
      if (fallback.isNotEmpty) {
        logger.d(
            '[USP][Dashboard]WifiClients fallback: ${fallback.length} clients');
      }
      return fallback;
    } catch (e) {
      logger.d('[USP][Dashboard]: WifiClients fallback failed: $e');
      return {};
    }
  }

  Future<Map<String, WifiClient>> _fetchWifiClientsFallback() async {
    final response = await _usp.get(
      ['Device.WiFi.AccessPoint.*.AssociatedDevice.'],
      priority: RequestPriority.low,
    );
    logger.d(
        '[USP][Dashboard]WifiClients fallback response: ${response.length} keys');
    if (response.isEmpty) return {};

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

  // ---------------------------------------------------------------------------
  // Connection Detail Map
  // ---------------------------------------------------------------------------

  /// Builds a lookup map: uppercase MAC → [ClientConnectionDetail].
  ///
  /// Cross-references:
  ///   WifiClient.parentPath → AccessPoint.ssidReference → SSID.ssid
  ///                         → SSID.lowerLayers → Radio.operatingFrequencyBand
  Map<String, ClientConnectionDetail> _buildConnectionDetailMap({
    required Map<String, WifiClient> wifiClientMap,
    required WiFiAccessPoints accessPoints,
    required WiFiSsids ssids,
    required WiFiRadios radios,
  }) {
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

    logger.d('[USP][Dashboard]: Connection detail: '
        '${apByPath.length} APs, ${ssidByPath.length} SSIDs, ${bandByRadioPath.length} radios');

    final result = <String, ClientConnectionDetail>{};
    for (final entry in wifiClientMap.entries) {
      final mac = entry.key;
      final client = entry.value;

      final ap = apByPath[_ensureTrailingDot(client.parentPath)];
      if (ap == null) {
        logger.d(
            '[USP][Dashboard]Connection detail: no AP for parentPath=${client.parentPath}');
        continue;
      }

      final ssid = ssidByPath[_ensureTrailingDot(ap.ssidReference)];
      final ssidName = ssid?.ssid ?? '';

      final band = ssid != null
          ? (bandByRadioPath[_ensureTrailingDot(ssid.lowerLayers)] ?? '')
          : '';

      result[mac] = ClientConnectionDetail(band: band, ssidName: ssidName);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // WiFi Client UI Model conversion
  // ---------------------------------------------------------------------------

  /// Converts raw codegen [WifiClient] map to [WifiClientUIModel] map.
  Map<String, WifiClientUIModel> _toWifiClientUIModels(
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _ensureTrailingDot(String path) {
    if (path.isEmpty) return path;
    return path.endsWith('.') ? path : '$path.';
  }

  static String _normalizeBand(String rawBand) {
    final lower = rawBand.toLowerCase();
    if (lower.contains('6g') || lower.contains('6 g')) return '6GHz';
    if (lower.contains('5g') || lower.contains('5 g')) return '5GHz';
    if (lower.contains('2.4') || lower.contains('2_4')) return '2.4GHz';
    return rawBand;
  }

  /// Parses a TR-181 `PossibleChannels` string into a sorted list of channel
  /// numbers. Handles comma-separated values and range notation.
  /// e.g. "1-13,36,40,44,48" → [1,2,3,4,5,6,7,8,9,10,11,12,13,36,40,44,48]
  static List<int> _parsePossibleChannels(String raw) {
    if (raw.isEmpty) return const [];
    final result = <int>[];
    for (final part in raw.split(',')) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        // Skip malformed range tokens (e.g. "1-2-3").
        if (bounds.length != 2) continue;
        final start = int.tryParse(bounds[0].trim());
        final end = int.tryParse(bounds[1].trim());
        if (start != null && end != null) {
          // Inverted ranges (start > end) naturally yield nothing.
          for (var i = start; i <= end; i++) {
            result.add(i);
          }
        }
      } else {
        final ch = int.tryParse(trimmed);
        if (ch != null) result.add(ch);
      }
    }
    // Drop non-positive channels: TR-181 PossibleChannels "0" is an
    // auto/any sentinel, not a real channel, and channel 0 must never
    // reach the dropdown or be sent to firmware.
    result.removeWhere((ch) => ch <= 0);
    result.sort();
    return result;
  }

  /// Builds a BSSID → band mapping from WiFi SSID and Radio data.
  ///
  /// Used by [MeshTopologyBuilder] to determine band for clients on slave nodes
  /// (via DataElements BSS.BSSID → this map → band).
  ///
  /// The mapping is: SSID.BSSID + SSID.LowerLayers → Radio.OperatingFrequencyBand
  static Map<String, String> buildBssidToBandMap({
    required WiFiSsids ssids,
    required WiFiRadios radios,
  }) {
    // Build Radio path → band lookup
    final bandByRadioPath = <String, String>{};
    for (final radio in radios.items) {
      final path = _ensureTrailingDot(radio.instancePath);
      bandByRadioPath[path] = _normalizeBand(radio.operatingFrequencyBand);
    }

    // Build BSSID → band mapping via SSID.LowerLayers → Radio
    final result = <String, String>{};
    for (final ssid in ssids.items) {
      final bssid = ssid.bssid.trim().toUpperCase();
      if (bssid.isEmpty) continue;

      final radioPath = _ensureTrailingDot(ssid.lowerLayers);
      final band = bandByRadioPath[radioPath];
      if (band != null && band.isNotEmpty) {
        result[bssid] = band;
      }
    }
    return result;
  }
}
