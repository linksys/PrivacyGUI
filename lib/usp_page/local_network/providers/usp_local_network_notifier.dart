import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp_page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/usp_page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/usp_page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/usp_page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/usp_page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/usp_page/local_network/services/usp_local_network_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspLocalNetworkProvider = AutoDisposeNotifierProvider<
    UspLocalNetworkNotifier, LocalNetworkFeatureState>(
  UspLocalNetworkNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspLocalNetworkProvider = AutoDisposeProvider<
    PreservableContract<LocalNetworkSettings, LocalNetworkStatus>>(
  (ref) => ref.watch(uspLocalNetworkProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspLocalNetworkNotifier
    extends AutoDisposeNotifier<LocalNetworkFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<LocalNetworkSettings,
            LocalNetworkStatus, LocalNetworkFeatureState> {
  UspLocalNetworkService get _svc =>
      ref.read(uspLocalNetworkServiceProvider);

  @override
  LocalNetworkFeatureState build() {
    // LAN data provider has no SSE invalidation domain,
    // so no SSE listener needed here.

    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return LocalNetworkFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(LocalNetworkSettings?, LocalNetworkStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      // Clone data from the shared data provider (read, not watch).
      final data = await ref.read(lanDataProvider.future);
      final uiModel = _svc.buildUIModel(data.raw);

      logger.d('[USP][Network][LAN] Fetched — '
          'ip: ${uiModel.ipAddress}, '
          'dhcp: ${uiModel.dhcpEnabled}, '
          'pool: ${uiModel.minAddress}-${uiModel.maxAddress}');

      return (
        LocalNetworkSettings(model: uiModel),
        const LocalNetworkStatus(isLoading: false),
      );
    } catch (e) {
      logger.e('[USP][Network][LAN] Fetch failed', error: e);
      return (
        null,
        LocalNetworkStatus(isLoading: false, errorMessage: '$e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final o = state.settings.original.model;
      final p = state.settings.current.model;

      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.save(original: o, pending: p);
        logger.d('[USP][Network][LAN] Saved');
      });

      // Force data provider to re-fetch so dashboard card updates too.
      ref.invalidate(lanDataProvider);
    } catch (e) {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // revert — override to also clear validation errors
  // ---------------------------------------------------------------------------

  @override
  void revert() {
    state = state.copyWith(
      settings:
          state.settings.copyWith(current: state.settings.original),
      status: state.status.copyWith(validationErrors: const {}),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — no network call)
  // ---------------------------------------------------------------------------

  /// Update a single setting + trigger cascade validation.
  ///
  /// When router IP changes, locked-prefix octets of pool IPs are
  /// automatically synced so the user doesn't have to retype them.
  void updateSetting(
      LocalNetworkUIModel Function(LocalNetworkUIModel) updater) {
    final current = state.settings.current;
    var newModel = updater(current.model);

    // Auto-sync pool prefix when router IP changes
    if (newModel.ipAddress != current.model.ipAddress &&
        newModel.subnetMask.isNotEmpty) {
      final locked = _svc.lockedOctetCount(newModel.subnetMask);
      if (locked > 0) {
        newModel = newModel.copyWith(
          minAddress: _svc.syncPrefix(
              newModel.minAddress, newModel.ipAddress, locked),
          maxAddress: _svc.syncPrefix(
              newModel.maxAddress, newModel.ipAddress, locked),
        );
      }
    }

    final errors = _svc.validateAll(newModel);

    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: newModel),
      ),
      status: state.status.copyWith(validationErrors: errors),
    );
  }

}
