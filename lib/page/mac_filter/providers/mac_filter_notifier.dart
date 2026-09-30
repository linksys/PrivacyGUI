import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

final uspMacFilterProvider =
    AutoDisposeNotifierProvider<UspMacFilterNotifier, MacFilterState>(
  UspMacFilterNotifier.new,
);

/// Save-based notifier for the MAC Filter page (Deny/Disabled).
///
/// Edits mutate `settings.current` only; [save] is the sole writer, via
/// [UspMacFilterService.setMacFilter] (a whole-list replacement). The page is
/// dirty-guarded through the Preservable mixin, so leaving with unsaved edits
/// prompts. Instant Privacy is the same backend in Allow mode
/// ([UspInstantPrivacyNotifier]); the two are mutually exclusive because the
/// device holds one mode + one list.
class UspMacFilterNotifier extends AutoDisposeNotifier<MacFilterState>
    with
        PreservableAutoDisposeNotifierMixin<MacFilterSettings, MacFilterStatus,
            MacFilterState> {
  UspMacFilterService get _svc => ref.read(uspMacFilterServiceProvider);

  @override
  MacFilterState build() {
    Future.microtask(() => fetch());
    return MacFilterState.initial();
  }

  @override
  Future<(MacFilterSettings?, MacFilterStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final result = await _svc.fetchAll();
      final settings = MacFilterSettings(mode: result.mode, macs: result.macs);
      final status = MacFilterStatus(
        isLoading: false,
        connectedDevices: result.connectedDevices,
      );
      return (settings, status);
    } catch (e, st) {
      final error = e is ServiceError ? e : UnexpectedError(originalError: e);
      logger.e('[USP][MacFilter]: fetch failed', error: e, stackTrace: st);
      return (null, MacFilterStatus(isLoading: false, error: error));
    }
  }

  @override
  Future<void> performSave() async {
    final settings = state.settings.current;
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _svc.setMacFilter(settings.mode, settings.macs);
    });
    logger.d('[USP][MacFilter]: saved — mode: ${settings.mode}, '
        'count: ${settings.macs.length}');
  }

  @override
  Future<MacFilterState> save() async {
    if (!isDirty()) return state;
    state = state.copyWith(status: state.status.copyWith(isSaving: true));
    try {
      final result = await super.save();
      final refetchError = result.status.error;
      if (refetchError != null) {
        state = state.copyWith(status: state.status.copyWith(clearError: true));
        throw refetchError;
      }
      return result;
    } finally {
      state = state.copyWith(status: state.status.copyWith(isSaving: false));
    }
  }

  // ---------------------------------------------------------------------------
  // Local mutations (synchronous — no network)
  // ---------------------------------------------------------------------------

  /// Toggle the filter on (Deny) or off.
  ///
  /// Turning on starts an empty block list — the MAC Filter page does not
  /// pre-populate, and when the device is in Instant Privacy's `Allow` its allow
  /// list must not become this page's block list. Turning back off returns to the
  /// mode as last read: from `Allow`, on-then-off is no change rather than a Save
  /// that switches Instant Privacy off. Off from an applied `Deny` is `Disabled`.
  void setEnabled(bool enabled) {
    final original = state.settings.original;
    final MacFilterSettings next;
    if (enabled) {
      next = original.mode == MacFilterMode.deny
          ? original
          : const MacFilterSettings(mode: MacFilterMode.deny, macs: []);
    } else if (original.mode == MacFilterMode.deny) {
      next = const MacFilterSettings(mode: MacFilterMode.disabled, macs: []);
    } else {
      next = original;
    }
    state = state.copyWith(settings: state.settings.update(next));
  }

  void addMac(String mac) {
    final normalized = UspMacFilterService.normalizeMac(mac);
    final current = state.settings.current;
    if (current.macs
        .map((m) => m.toUpperCase())
        .contains(normalized.toUpperCase())) {
      return;
    }
    state = state.copyWith(
      settings: state.settings
          .update(current.copyWith(macs: [...current.macs, normalized])),
    );
  }

  void removeMac(String mac) {
    final current = state.settings.current;
    final target = mac.toUpperCase();
    state = state.copyWith(
      settings: state.settings.update(current.copyWith(
        macs: current.macs.where((m) => m.toUpperCase() != target).toList(),
      )),
    );
  }
}
