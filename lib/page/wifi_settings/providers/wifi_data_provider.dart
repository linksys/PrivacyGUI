import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';

// ---------------------------------------------------------------------------
// Opaque codegen context (only WiFi-domain services can consume)
// ---------------------------------------------------------------------------

/// Opaque wrapper around raw WiFi codegen data.
///
/// External consumers hold this without accessing the inner codegen types.
/// Only WiFi-domain services ([UspWifiSettingsService], [UspDeviceService])
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
// Data Model (Layer 1 — UIModel only)
// ---------------------------------------------------------------------------

class WifiData extends Equatable {
  /// Opaque codegen context for WiFi settings service consumption.
  final WifiCodegenContext codegenContext;

  // Enrichment (UI-safe types — codegen converted at boundary)
  final Map<String, WifiClientUIModel> wifiClientMap;
  final Map<String, ClientConnectionDetail> connectionDetailMap;

  // UI models (computed from raw, cached here to avoid repeated computation)
  final List<WifiRadioUIModel> radioModels;

  const WifiData({
    required this.codegenContext,
    this.wifiClientMap = const {},
    this.connectionDetailMap = const {},
    this.radioModels = const [],
  });

  const WifiData.empty()
      : codegenContext = WifiCodegenContext.empty,
        wifiClientMap = const {},
        connectionDetailMap = const {},
        radioModels = const [];

  @override
  List<Object?> get props => [
        codegenContext,
        wifiClientMap.length,
        connectionDetailMap.length,
        radioModels.length,
      ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final wifiDataProvider =
    AsyncNotifierProvider<WifiDataNotifier, WifiData>(WifiDataNotifier.new);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — persists for dashboard card lifetime)
// ---------------------------------------------------------------------------

class WifiDataNotifier extends AsyncNotifier<WifiData> {
  Timer? _debounce;

  @override
  Future<WifiData> build() async {
    // SSE: listen for WiFi domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.wifiRadios ||
          domain == InvalidationDomain.wifiSsids ||
          domain == InvalidationDomain.wifiAccessPoints ||
          domain == InvalidationDomain.wifiClients) {
        _debouncedInvalidate();
      }
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<WifiData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    // Parallel fetch all WiFi data (15s timeout prevents indefinite hang
    // when the bridge is temporarily unavailable, e.g. 503 on startup)
    final results = await Future.wait([
      WiFiRadios.fetch(usp),
      WiFiSsids.fetch(usp),
      WiFiAccessPoints.fetch(usp),
      fetchWifiClients(usp),
    ]).timeout(const Duration(seconds: 15));

    final radios = results[0] as WiFiRadios;
    final ssids = results[1] as WiFiSsids;
    final accessPoints = results[2] as WiFiAccessPoints;
    final rawWifiClientMap = results[3] as Map<String, WifiClient>;

    // Cross-reference AP → SSID → Radio to get band + SSID name per client
    // (uses raw codegen WifiClient which has parentPath for AP lookup)
    final connectionDetailMap = buildConnectionDetailMap(
      wifiClientMap: rawWifiClientMap,
      accessPoints: accessPoints,
      ssids: ssids,
      radios: radios,
    );

    // Convert raw codegen → UI model at the Layer 1 boundary
    final wifiClientMap = toWifiClientUIModels(rawWifiClientMap);

    // Build UI models
    final svc = ref.read(uspDeviceServiceProvider);
    final radioModels = svc.buildWifiRadioUIModels(
      radios: radios,
      ssids: ssids,
      accessPoints: accessPoints,
    );

    logger.d('[USP][WifiData] Fetched — '
        'radios: ${radios.items.length}, '
        'ssids: ${ssids.items.length}, '
        'aps: ${accessPoints.items.length}, '
        'clients: ${wifiClientMap.length}');

    return WifiData(
      codegenContext: WifiCodegenContext(radios, ssids, accessPoints),
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      radioModels: radioModels,
    );
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }

  // ---------------------------------------------------------------------------
  // WiFi Radio mutations
  // ---------------------------------------------------------------------------

  Future<void> toggleWifiRadio(String instancePath, bool enable) async {
    final usp = ref.read(uspServiceProvider)!;
    await ref.read(uspMutationLockProvider).withLock(() async {
      await WiFiRadios.update(
          usp, WiFiRadioUpdate(instancePath: instancePath, enable: enable));
    });
    ref.invalidateSelf();
  }

  Future<void> updateWifiRadioChannel(
      String instancePath, int channel, bool autoChannel) async {
    final usp = ref.read(uspServiceProvider)!;
    await ref.read(uspMutationLockProvider).withLock(() async {
      await WiFiRadios.update(
        usp,
        WiFiRadioUpdate(
          instancePath: instancePath,
          channel: channel,
          autoChannelEnable: autoChannel,
        ),
      );
    });
    ref.invalidateSelf();
  }
}
