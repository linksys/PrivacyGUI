import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

final uspInstantPrivacyProvider = AutoDisposeNotifierProvider<
    UspInstantPrivacyNotifier, UspInstantPrivacyState>(
  UspInstantPrivacyNotifier.new,
);

/// Save-based notifier for the Instant Privacy page (Allow/Disabled).
///
/// Instant Privacy is the shared MAC filter in Allow mode: enabling admits only
/// the listed devices and **pre-populates the list with every currently online
/// device** as the default. Edits mutate `settings.current`; only [save] writes,
/// via [UspMacFilterService.setMacFilter]. Mutually exclusive with the MAC
/// Filter page (Deny) — they share one device mode + list.
class UspInstantPrivacyNotifier
    extends AutoDisposeNotifier<UspInstantPrivacyState>
    with
        PreservableAutoDisposeNotifierMixin<MacFilterSettings, MacFilterStatus,
            UspInstantPrivacyState> {
  UspMacFilterService get _svc => ref.read(uspMacFilterServiceProvider);

  @override
  UspInstantPrivacyState build() {
    Future.microtask(() => fetch());
    return UspInstantPrivacyState.initial();
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
      logger.e('[USP][Privacy]: fetch failed', error: e, stackTrace: st);
      return (null, MacFilterStatus(isLoading: false, error: error));
    }
  }

  @override
  Future<void> performSave() async {
    final settings = state.settings.current;
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _svc.setMacFilter(settings.mode, settings.macs);
    });
    logger.d('[USP][Privacy]: saved — mode: ${settings.mode}, '
        'count: ${settings.macs.length}');
  }

  @override
  Future<UspInstantPrivacyState> save() async {
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

  /// Toggle Instant Privacy on (Allow) or off.
  ///
  /// Enabling pre-populates the list with every currently online device — the
  /// "lock the network to who's on it now" default — unless the device is
  /// already in `Allow`, where turning back on after an off is an undo and
  /// restores the saved list. Turning off returns to the mode as last read
  /// rather than to `Disabled`: when the device is in MAC Filter's `Deny`,
  /// on-then-off must be no change, not a Save that turns MAC Filter off and
  /// empties its list. Off from an applied `Allow` is `Disabled`.
  void setEnabled(bool enabled) {
    final original = state.settings.original;
    final MacFilterSettings next;
    if (enabled) {
      next = original.mode == MacFilterMode.allow
          ? original
          : MacFilterSettings(
              mode: MacFilterMode.allow,
              macs: state.status.connectedDevices.map((d) => d.mac).toList(),
            );
    } else if (original.mode == MacFilterMode.allow) {
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
