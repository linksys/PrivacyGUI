import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_advanced_state.dart';

final uspWifiAdvancedProvider = AsyncNotifierProvider.autoDispose<
    UspWifiAdvancedNotifier, UspWifiAdvancedState>(
  UspWifiAdvancedNotifier.new,
);

class UspWifiAdvancedNotifier
    extends AutoDisposeAsyncNotifier<UspWifiAdvancedState> {
  static const _ieee80211hPath = 'Device.WiFi.Radio.*.IEEE80211hEnabled';

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

  @override
  Future<UspWifiAdvancedState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) throw StateError('USP not authenticated');
    }

    logger.d('[WiFiAdvanced] Fetching advanced settings...');

    final response = await usp.get([_ieee80211hPath]);

    // Parse per-radio IEEE80211hEnabled
    final ieee80211h = <String, bool>{};
    for (final key in response.keys) {
      if (key.startsWith('Device.WiFi.Radio.') &&
          key.endsWith('.IEEE80211hEnabled')) {
        final radioPath =
            key.substring(0, key.length - 'IEEE80211hEnabled'.length);
        final val = response[key];
        ieee80211h[radioPath] = val == true || val == 'true' || val == '1';
      }
    }

    logger.d('[WiFiAdvanced] radios=${ieee80211h.length}');

    return UspWifiAdvancedState(ieee80211hByRadio: ieee80211h);
  }

  /// Toggles IEEE 802.11h (DFS + TPC) on ALL known radios simultaneously.
  Future<void> setIeee80211hEnabled(bool enabled) async {
    final paths = state.requireValue.ieee80211hByRadio.keys.toList();
    if (paths.isEmpty) return;

    final params = <String, dynamic>{
      for (final path in paths) '${path}IEEE80211hEnabled': enabled,
    };
    await _usp.set(params);

    state = AsyncData(state.requireValue.copyWith(
      ieee80211hByRadio: {for (final path in paths) path: enabled},
    ));
  }
}
