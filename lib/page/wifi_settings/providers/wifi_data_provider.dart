import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart';

// Re-export so existing consumers can still import WifiCodegenContext from here.
export 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart'
    show WifiCodegenContext;

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
    final svc = ref.read(uspWifiDataServiceProvider);
    final result = await svc.fetch();

    logger.d('[USP][WifiData]: Fetched — '
        'clients: ${result.wifiClientMap.length}, '
        'radios: ${result.radioModels.length}');

    return WifiData(
      codegenContext: result.codegenContext,
      wifiClientMap: result.wifiClientMap,
      connectionDetailMap: result.connectionDetailMap,
      radioModels: result.radioModels,
    );
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
