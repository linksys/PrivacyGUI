import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/administration/models/administration_feature_state.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/models/administration_status.dart';
import 'package:privacy_gui/page/administration/services/usp_administration_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspAdministrationProvider = AutoDisposeNotifierProvider<
    UspAdministrationNotifier, AdministrationFeatureState>(
  UspAdministrationNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// L2 working copy for Advanced Settings → Administration (#1660).
///
/// Type A form: the UPnP switch is buffered and written by Save; the route
/// passes this notifier as its `preservableProvider`, which is the dirty guard.
class UspAdministrationNotifier
    extends AutoDisposeNotifier<AdministrationFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<AdministrationSettings,
            AdministrationStatus, AdministrationFeatureState> {
  UspAdministrationService get _svc =>
      ref.read(uspAdministrationServiceProvider);

  @override
  AdministrationFeatureState build() {
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return AdministrationFeatureState.initial();
  }

  @override
  Future<(AdministrationSettings?, AdministrationStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final settings = await _svc.fetch();
      logger.d('[USP][Administration]: Fetched — '
          'upnpEnabled=${settings.upnpEnabled}');
      return (settings, const AdministrationStatus());
    } on ServiceError catch (e) {
      logger.e('[USP][Administration]: Fetch failed', error: e);
      return (null, AdministrationStatus(error: e));
    }
  }

  @override
  Future<AdministrationFeatureState> save() async {
    state = state.copyWith(status: state.status.copyWith(isSaving: true));
    try {
      return await super.save();
    } on ServiceError catch (e) {
      logger.e('[USP][Administration]: Save failed', error: e);
      await _rereadAfterFailure();
      rethrow;
    } finally {
      state = state.copyWith(status: state.status.copyWith(isSaving: false));
    }
  }

  @override
  Future<void> performSave() async {
    final enabled = state.settings.current.upnpEnabled;
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _svc.setUpnpEnabled(enabled);
    });
    logger.d('[USP][Administration]: UPnP saved — enabled=$enabled');
  }

  /// After a refused or unanswered Set, show what the device holds rather than
  /// the value that was not written, and leave nothing pending.
  ///
  /// If that read fails too, the edit is kept: nobody knows what the router
  /// holds, and the user can press Save again. The Set's error is the one the
  /// caller reports either way.
  Future<void> _rereadAfterFailure() async {
    try {
      final now = await _svc.fetch();
      state = state.copyWith(
        settings: Preservable(original: now, current: now),
      );
    } on ServiceError catch (e) {
      logger.w(
          '[USP][Administration]: Re-read after a failed save also '
          'failed',
          error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — buffers, no network call)
  // ---------------------------------------------------------------------------

  /// Toggle UPnP. Updates [settings.current] only; save() writes it.
  void setUpnpEnabled(bool enabled) {
    state = state.copyWith(
      settings: state.settings
          .update(state.settings.current.copyWith(upnpEnabled: enabled)),
    );
  }
}
