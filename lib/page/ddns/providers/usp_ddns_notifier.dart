import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/ddns/models/ddns_feature_state.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';
import 'package:privacy_gui/page/ddns/providers/ddns_status_data_provider.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_service.dart';

/// L2 of the DDNS page (Type A form): the editable provider, account and host
/// name, saved in one Set.
final uspDdnsProvider =
    AutoDisposeNotifierProvider<UspDdnsNotifier, DdnsFeatureState>(
  UspDdnsNotifier.new,
);

class UspDdnsNotifier extends AutoDisposeNotifier<DdnsFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<DdnsSettings, DdnsStatus,
            DdnsFeatureState> {
  UspDdnsService get _svc => ref.read(uspDdnsServiceProvider);

  @override
  DdnsFeatureState build() {
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return DdnsFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  /// Reads the settings, and has the status re-read with them.
  ///
  /// The status is the L1's, and nothing else re-reads it: it is not on the
  /// dashboard, so a re-login, a recovery or a push missed while the stream
  /// was down would leave it stale. The page's reads — opening it, pulling to
  /// refresh, and the read after a save — are the moments it should be
  /// current, so each one invalidates it. The page watches it, so it reads
  /// again at once.
  @override
  Future<(DdnsSettings?, DdnsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final (settings, status) = await _svc.fetch();
      ref.invalidate(ddnsStatusDataProvider);
      logger.d('[USP][DDNS]: Fetched — $settings');
      return (settings, status);
    } on ServiceError catch (e) {
      logger.e('[USP][DDNS]: Fetch failed', error: e);
      return (null, DdnsStatus(isLoading: false, error: e));
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(status: state.status.copyWith(isSaving: true));
    try {
      final pending = state.settings.current;
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.save(pending);
      });
      logger.d('[USP][DDNS]: Saved — provider: ${pending.providerPath}, '
          'password ${pending.password.isEmpty ? 'kept' : 'sent'}');
    } on ServiceError catch (e) {
      logger.e('[USP][DDNS]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(status: state.status.copyWith(isSaving: false));
    }
  }

  // ---------------------------------------------------------------------------
  // UI mutations (synchronous — no network call)
  // ---------------------------------------------------------------------------

  /// Chooses a provider, or "Disabled" with null.
  ///
  /// "Disabled" puts the account and the host name back to what the router
  /// holds: it writes `Enable` alone, so an edit left in the hidden fields
  /// would be dropped by the save that reports "Changes saved". Choosing a
  /// provider again shows the router's values.
  ///
  /// The field errors on screen stay only where the field still fails under
  /// the new choice ("Disabled" has none); a choice shows no new error before
  /// a field loses focus.
  void selectProvider(String? providerPath) {
    final next = providerPath == null
        ? state.settings.original
            .copyWith(clientEnabled: false, clearProviderPath: true)
        : state.settings.current
            .copyWith(clientEnabled: true, providerPath: providerPath);
    state = state.copyWith(
      settings: state.settings.update(next),
      status: state.status.copyWith(
        fieldErrors:
            state.status.fieldErrors.intersection(invalidDdnsFields(next)),
      ),
    );
  }

  /// Updates a field WITHOUT re-checking it.
  ///
  /// Use this for onChanged handlers: a field error appearing mid-typing
  /// rebuilds the field and can take its focus on Web. Call [validateField]
  /// when the field loses focus.
  void updateSetting(DdnsSettings Function(DdnsSettings) updater) {
    state = state.copyWith(
      settings: state.settings.update(updater(state.settings.current)),
    );
  }

  /// Re-checks [field] alone, as it loses focus, and shows or clears its
  /// error. The other fields keep what they show: one the user has not
  /// reached yet does not turn red because an earlier one was left.
  void validateField(DdnsField field) {
    final fails = invalidDdnsFields(state.settings.current).contains(field);
    final errors = {...state.status.fieldErrors}..remove(field);
    if (fails) errors.add(field);
    state = state.copyWith(status: state.status.copyWith(fieldErrors: errors));
  }

  /// Re-checks every field and shows the ones that fail.
  void validate() {
    state = state.copyWith(
      status: state.status.copyWith(
        fieldErrors: invalidDdnsFields(state.settings.current),
      ),
    );
  }

  /// Puts back what the router holds, and the errors shown for the edit go
  /// with it.
  @override
  void revert() {
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
      status: state.status.copyWith(fieldErrors: const {}),
    );
  }
}
