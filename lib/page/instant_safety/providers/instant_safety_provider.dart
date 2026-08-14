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
    } on ServiceError catch (e) {
      logger.e('[USP][Safety]: Fetch failed', error: e);
      // isLoading must be set explicitly — InstantSafetyStatus defaults it to
      // true, so omitting it would leave the view stuck on its loader and the
      // ServiceErrorView (and its Retry) unreachable.
      return (
        null,
        InstantSafetyStatus(isLoading: false, error: e),
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
      ref.invalidate(lanDataProvider);
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
