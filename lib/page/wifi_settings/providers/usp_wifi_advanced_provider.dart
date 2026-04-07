import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

final uspWifiAdvancedProvider = AsyncNotifierProvider.autoDispose<
    UspWifiAdvancedNotifier, UspWifiAdvancedState>(
  UspWifiAdvancedNotifier.new,
);

class UspWifiAdvancedNotifier
    extends AutoDisposeAsyncNotifier<UspWifiAdvancedState> {
  UspWifiAdvancedService get _svc => ref.read(uspWifiAdvancedServiceProvider);

  @override
  Future<UspWifiAdvancedState> build() async {
    logger.d('[USP][WiFi][Advanced]Fetching advanced settings...');

    try {
      final ieee80211h = await _svc.fetchIeee80211h();
      logger.d('[USP][WiFi][Advanced]radios=${ieee80211h.length}');
      return UspWifiAdvancedState(ieee80211hByRadio: ieee80211h);
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi][Advanced] Fetch failed', error: e);
      rethrow;
    }
  }

  /// Toggles IEEE 802.11h (DFS + TPC) on ALL known radios simultaneously.
  Future<void> setIeee80211hEnabled(bool enabled) async {
    final paths = state.requireValue.ieee80211hByRadio.keys.toList();
    if (paths.isEmpty) return;

    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.setIeee80211hEnabled(radioPaths: paths, enabled: enabled);
      });

      state = AsyncData(state.requireValue.copyWith(
        ieee80211hByRadio: {for (final path in paths) path: enabled},
      ));
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi][Advanced] Set IEEE80211h failed', error: e);
      rethrow;
    }
  }
}
