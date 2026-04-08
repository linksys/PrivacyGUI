import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';

final uspInstantPrivacyProvider =
    AsyncNotifierProvider<UspInstantPrivacyNotifier, UspInstantPrivacyState>(
  UspInstantPrivacyNotifier.new,
);

class UspInstantPrivacyNotifier extends AsyncNotifier<UspInstantPrivacyState> {
  UspInstantPrivacyService get _svc =>
      ref.read(uspInstantPrivacyServiceProvider);

  @override
  Future<UspInstantPrivacyState> build() async {
    try {
      final result = await _svc.fetchAll();

      logger.d('[USP][Privacy] Fetched — '
          'activeDevices: ${result.connectedDevices.length}, '
          'isEnabled: ${result.isEnabled}');

      return UspInstantPrivacyState(
        isEnabled: result.isEnabled,
        connectedDevices: result.connectedDevices,
        allowedDevices: result.allowedDevices,
        macFilterContext: result.macFilterContext,
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Privacy] Fetch failed', error: e);
      rethrow;
    }
  }

  /// Enables Instant Privacy by snapshotting currently connected devices
  /// as the MAC whitelist across all APs.
  Future<void> enable() async {
    final s = state.valueOrNull;
    if (s == null || s.isEnabled) return;

    state = AsyncData(s.copyWith(isToggleLocked: true));
    try {
      final macs = s.connectedDevices.map((d) => d.mac).toList();
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.enable(macs, s.macFilterContext);
      });
      logger.d('[USP][Privacy] Enabled — ${macs.length} MACs');
      ref.invalidateSelf();
    } on ServiceError catch (e) {
      logger.e('[USP][Privacy] Enable failed', error: e);
      state = AsyncData(s.copyWith(isToggleLocked: false));
      rethrow;
    }
  }

  /// Disables Instant Privacy by clearing MAC filtering on all APs.
  Future<void> disable() async {
    final s = state.valueOrNull;
    if (s == null || !s.isEnabled) return;

    state = AsyncData(s.copyWith(isToggleLocked: true));
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.disable(s.macFilterContext);
      });
      logger.d('[USP][Privacy] Disabled');
      ref.invalidateSelf();
    } on ServiceError catch (e) {
      logger.e('[USP][Privacy] Disable failed', error: e);
      state = AsyncData(s.copyWith(isToggleLocked: false));
      rethrow;
    }
  }

  /// Adds [mac] to the allowed list across all APs.
  Future<void> addMac(String mac) async {
    final s = state.valueOrNull;
    if (s == null || !s.isEnabled) return;

    state = AsyncData(s.copyWith(isToggleLocked: true));
    try {
      final added = await ref.read(uspMutationLockProvider).withLock(() async {
        return await _svc.addMac(mac, s.macFilterContext);
      });
      if (!added) {
        state = AsyncData(s.copyWith(isToggleLocked: false));
        return;
      }
      logger.d('[USP][Privacy] addMac — $mac');
      ref.invalidateSelf();
    } on ServiceError catch (e) {
      logger.e('[USP][Privacy] addMac failed', error: e);
      state = AsyncData(s.copyWith(isToggleLocked: false));
      rethrow;
    }
  }
}
