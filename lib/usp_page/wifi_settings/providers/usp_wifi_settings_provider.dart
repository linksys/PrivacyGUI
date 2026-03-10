import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/usp_page/wifi_settings/services/usp_wifi_settings_service.dart';

final uspWifiSettingsProvider = AsyncNotifierProvider.autoDispose<
    UspWifiSettingsNotifier, UspWifiSettingsState>(
  UspWifiSettingsNotifier.new,
);

class UspWifiSettingsNotifier
    extends AutoDisposeAsyncNotifier<UspWifiSettingsState> {
  bool _mutating = false;

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

  UspWifiSettingsService get _svc => ref.read(uspWifiSettingsServiceProvider);

  @override
  Future<UspWifiSettingsState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        throw StateError('USP not authenticated');
      }
    }

    logger.d('[WiFiSettings] Fetching WiFi data...');

    // Parallel fetch of all three collections
    final results = await Future.wait([
      WiFiSsids.fetch(usp),
      WiFiAccessPoints.fetch(usp),
      WiFiRadios.fetch(usp),
    ]);

    final ssids = results[0] as WiFiSsids;
    final accessPoints = results[1] as WiFiAccessPoints;
    final radios = results[2] as WiFiRadios;

    final networks = _svc.buildWifiNetworks(
      ssids: ssids,
      accessPoints: accessPoints,
      radios: radios,
    );

    logger.d('[WiFiSettings] Loaded ${networks.length} networks');

    return UspWifiSettingsState(
      ssids: ssids,
      accessPoints: accessPoints,
      radios: radios,
      networks: networks,
    );
  }

  /// Guards against concurrent mutations (WASM sequential access requirement).
  Future<T> _withLock<T>(Future<T> Function() action) async {
    if (_mutating) throw StateError('Another mutation is in progress');
    _mutating = true;
    try {
      return await action();
    } finally {
      _mutating = false;
    }
  }

  /// Refreshes all WiFi data from the router.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Toggles a WiFi network on or off via SSID.Enable.
  Future<void> toggleNetwork(String ssidInstancePath, bool enabled) async {
    await _withLock(() async {
      await WiFiSsids.update(
        _usp,
        WiFiSsidUpdate(instancePath: ssidInstancePath, enable: enabled),
      );
      await _refetchAndUpdateState();
    });
  }

  /// Toggles MAC address control (allow-list) for an AccessPoint.
  Future<void> toggleMacAddressControl(
      String apInstancePath, bool enabled) async {
    await _withLock(() async {
      await WiFiAccessPoints.update(
        _usp,
        WiFiAccessPointUpdate(
            instancePath: apInstancePath, macAddressControlEnabled: enabled),
      );
      await _refetchAndUpdateState();
    });
  }

  /// Re-fetches raw data and rebuilds UI models, updating state in-place.
  Future<void> _refetchAndUpdateState() async {
    final results = await Future.wait([
      WiFiSsids.fetch(_usp),
      WiFiAccessPoints.fetch(_usp),
      WiFiRadios.fetch(_usp),
    ]);

    final ssids = results[0] as WiFiSsids;
    final accessPoints = results[1] as WiFiAccessPoints;
    final radios = results[2] as WiFiRadios;

    final networks = _svc.buildWifiNetworks(
      ssids: ssids,
      accessPoints: accessPoints,
      radios: radios,
    );

    state = AsyncData(state.requireValue.copyWith(
      ssids: ssids,
      accessPoints: accessPoints,
      radios: radios,
      networks: networks,
    ));
  }
}
