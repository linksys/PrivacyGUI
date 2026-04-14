import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/wifi_client_enricher.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspWifiDataServiceProvider = Provider<UspWifiDataService>(
  (ref) {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
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
  final UspService _usp;

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
        fetchWifiClients(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final radios = results[0] as WiFiRadios;
    final ssids = results[1] as WiFiSsids;
    final accessPoints = results[2] as WiFiAccessPoints;
    final rawWifiClientMap = results[3] as Map<String, WifiClient>;

    // Cross-reference AP → SSID → Radio to get band + SSID name per client
    final connectionDetailMap = buildConnectionDetailMap(
      wifiClientMap: rawWifiClientMap,
      accessPoints: accessPoints,
      ssids: ssids,
      radios: radios,
    );

    // Convert raw codegen → UI model at the service boundary
    final wifiClientMap = toWifiClientUIModels(rawWifiClientMap);

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
  List<WifiRadioUIModel> _buildWifiRadioUIModels({
    required WiFiRadios radios,
    required WiFiSsids ssids,
    required WiFiAccessPoints accessPoints,
  }) {
    final ssidByPath = {
      for (final s in ssids.items) _ensureTrailingDot(s.instancePath): s,
    };

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
      return WifiRadioUIModel(
        instancePath: radio.instancePath,
        band: radio.operatingFrequencyBand,
        enable: radio.enable,
        transmitPower: radio.transmitPower,
        maxBitRate: radio.maxBitRate,
        channel: radio.channel,
        autoChannelEnable: radio.autoChannelEnable,
        channelBandwidth: radio.operatingChannelBandwidth,
        supportedStandards: radio.supportedStandards,
        accessPoints: radioAps
            .map((a) => WifiAccessPointUIModel(
                  enable: a.ap.enable,
                  ssidName:
                      a.ssid.ssid.isNotEmpty ? a.ssid.ssid : a.ap.ssidReference,
                  securityMode: a.ap.securityModeEnabled,
                  encryptionMode: a.ap.encryptionMode,
                ))
            .toList(),
      );
    }).toList();
  }

  static String _ensureTrailingDot(String path) {
    if (path.isEmpty) return path;
    return path.endsWith('.') ? path : '$path.';
  }
}
