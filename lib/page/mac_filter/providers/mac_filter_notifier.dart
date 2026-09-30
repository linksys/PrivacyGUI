import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

final uspMacFilterProvider =
    AsyncNotifierProvider<UspMacFilterNotifier, MacFilterState>(
  UspMacFilterNotifier.new,
);

/// Drives the MAC Filter page. Reads through the shared [UspMacFilterService]
/// and writes every change as a whole-list replacement (the firmware contract),
/// under the USP mutation lock, then refetches so the state reflects the device.
class UspMacFilterNotifier extends AsyncNotifier<MacFilterState> {
  UspMacFilterService get _svc => ref.read(uspMacFilterServiceProvider);

  @override
  Future<MacFilterState> build() async {
    try {
      final result = await _svc.fetchAll();
      return MacFilterState(
        mode: result.mode,
        macs: result.macs,
        connectedDevices: result.connectedDevices,
      );
    } on ServiceError catch (e) {
      logger.e('[MacFilter]: build failed: $e');
      rethrow;
    }
  }

  /// Change the mode, keeping the current list. Allow with an empty list is
  /// rejected by the service, surfaced to the caller.
  Future<void> setMode(MacFilterMode mode) =>
      _write(mode, state.value?.macs ?? const []);

  /// Add a MAC to the list and re-write.
  Future<void> addMac(String mac) {
    final current = state.value?.macs ?? const <String>[];
    final normalized = UspMacFilterService.normalizeMac(mac);
    if (current
        .map((m) => m.toUpperCase())
        .contains(normalized.toUpperCase())) {
      return Future.value();
    }
    return _write(
        state.value?.mode ?? MacFilterMode.disabled, [...current, normalized]);
  }

  /// Remove a MAC from the list and re-write.
  Future<void> removeMac(String mac) {
    final current = state.value?.macs ?? const <String>[];
    final target = mac.toUpperCase();
    return _write(state.value?.mode ?? MacFilterMode.disabled,
        current.where((m) => m.toUpperCase() != target).toList());
  }

  Future<void> _write(MacFilterMode mode, List<String> macs) async {
    final busy = state.value;
    if (busy != null) state = AsyncData(busy.copyWith(isBusy: true));
    try {
      await ref
          .read(uspMutationLockProvider)
          .withLock(() => _svc.setMacFilter(mode, macs));
      ref.invalidateSelf();
    } on ServiceError {
      // Restore the un-busy state so the page stays interactive, and let the
      // view surface the error (a SnackBar) — the write did not take.
      if (busy != null) state = AsyncData(busy.copyWith(isBusy: false));
      rethrow;
    }
  }
}
