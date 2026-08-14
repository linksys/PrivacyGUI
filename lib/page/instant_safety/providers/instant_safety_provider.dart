import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_feature_state.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_settings.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_status.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspInstantSafetyProvider = AutoDisposeNotifierProvider<
    UspInstantSafetyNotifier, InstantSafetyFeatureState>(
  UspInstantSafetyNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspInstantSafetyProvider = AutoDisposeProvider<
    PreservableContract<InstantSafetySettings, InstantSafetyStatus>>(
  (ref) => ref.watch(uspInstantSafetyProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspInstantSafetyNotifier
    extends AutoDisposeNotifier<InstantSafetyFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<InstantSafetySettings,
            InstantSafetyStatus, InstantSafetyFeatureState> {
  UspInstantSafetyService get _svc => ref.read(uspInstantSafetyServiceProvider);

  @override
  InstantSafetyFeatureState build() {
    Future.microtask(() => fetch());
    return InstantSafetyFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(InstantSafetySettings?, InstantSafetyStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final uiModel = await _svc.fetch();

      logger.d('[USP][Safety]: Fetched — type: ${uiModel.type}');

      final newSettings = InstantSafetySettings(type: uiModel.type);
      const newStatus = InstantSafetyStatus(isLoading: false);

      return (newSettings, newStatus);
    } catch (e, st) {
      // The service maps every USP failure to ServiceError, so a non-ServiceError
      // here came from outside that contract (e.g. the uspClientProvider null
      // assertion in the service provider). It still has to become a status —
      // escaping build()'s unawaited microtask is the exact hang this guards.
      //
      // The raw error goes on originalError, never into detail: for
      // UnexpectedError alone, localizeServiceError surfaces detail to the user
      // verbatim (service_error_localizations.dart:47), and a Dart
      // "Bad state: ..." is neither localized nor actionable.
      final error = e is ServiceError ? e : UnexpectedError(originalError: e);

      // Log the raw `e`, not the wrapped one: a detail-less UnexpectedError
      // stringifies to a bare "Unexpected error", which would drop the only
      // text identifying the failure. Same object when e is a ServiceError.
      logger.e('[USP][Safety]: Fetch failed (forceRemote: $forceRemote)',
          error: e, stackTrace: st);
      // Returning a status rather than throwing is right for the two display
      // paths (initial load, pull-to-refresh) but wrong for the post-save
      // re-fetch — save() below converts it back into a throw.
      //
      // isLoading stays spelled out even though it now defaults to false: the
      // view checks it before error, so this line is what makes the error view
      // reachable at all.
      return (
        null,
        InstantSafetyStatus(isLoading: false, error: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // save — override to manage isSaving flag and invalidate L1
  // ---------------------------------------------------------------------------

  @override
  Future<InstantSafetyFeatureState> save() async {
    if (!isDirty()) return state;

    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );
    try {
      final result = await super.save();

      // Invalidate L1 LAN data to refresh applied state for menu badge.
      //
      // Unconditional, and before the refetchError check below: the mixin runs
      // performSave() + markAsSaved() before its post-save re-fetch, so by the
      // time we get here the SET has landed and L1 is stale no matter how the
      // confirming read went. Skipping this on a failed re-fetch would leave
      // the badge on the pre-save value with no second chance to converge —
      // markAsSaved() has already cleaned the state, so the isDirty() guard
      // above turns a user's retry into a no-op.
      ref.invalidate(lanDataProvider);

      // performFetch turns a failed re-fetch into status.error instead of
      // throwing (it has to, for the initial load). super.save() therefore
      // returns normally even when the post-save re-fetch failed, which would
      // show the "settings saved" snackbar and a full-page ServiceErrorView at
      // once. Restore the mixin's documented contract: the SET succeeded, but
      // the caller must still hear about the re-fetch failure.
      final refetchError = result.status.error;
      if (refetchError != null) {
        // Only the refresh failed, so the page must not turn into a full-page
        // error: settings already hold the value that was written. Clear the
        // status and let the caller report the failure as a snackbar.
        //
        // The View localizes this the same way it localizes a genuine save
        // failure, so the toast reads "save failed" for a write that landed.
        // Distinguishing the two needs a dedicated error type; tracked in
        // #1279 with the rest of the save-contract work.
        state = state.copyWith(status: state.status.copyWith(clearError: true));
        throw refetchError;
      }

      return result;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _svc.save(state.settings.current.type);
    });
    logger.d('[USP][Safety]: Saved — type: ${state.settings.current.type}');
  }

  // ---------------------------------------------------------------------------
  // UI setter methods
  // ---------------------------------------------------------------------------

  /// Toggle safe browsing on/off.
  void setEnabled(bool enabled) {
    final newType = enabled ? SafeBrowsingType.openDNS : SafeBrowsingType.off;
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(current.copyWith(type: newType)),
    );
  }
}
