import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_local_network_service.dart';

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
  UspLocalNetworkService get _svc => ref.read(uspLocalNetworkServiceProvider);

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
      final lan = data.model;
      final dnsParts = lan.dnsServers.split(',').map((s) => s.trim()).toList();
      final uiModel = LocalNetworkUIModel(
        hostName: lan.hostName,
        ipAddress: lan.ipAddress,
        subnetMask: lan.subnetMask,
        dhcpEnabled: lan.dhcpEnabled,
        minAddress: lan.minAddress,
        maxAddress: lan.maxAddress,
        leaseTimeMinutes: lan.leaseTimeMinutes,
        dnsServer1: dnsParts.isNotEmpty ? dnsParts[0] : '',
        dnsServer2: dnsParts.length > 1 ? dnsParts[1] : '',
        dnsServer3: dnsParts.length > 2 ? dnsParts[2] : '',
      );

      logger.d('[USP][Network][LAN]: Fetched — '
          'ip: ${uiModel.ipAddress}, '
          'dhcp: ${uiModel.dhcpEnabled}, '
          'pool: ${uiModel.minAddress}-${uiModel.maxAddress}');

      return (
        LocalNetworkSettings(model: uiModel),
        LocalNetworkStatus(
          isLoading: false,
          lockedOctetCount: _svc.lockedOctetCount(uiModel.subnetMask),
        ),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Network][LAN]: Fetch failed', error: e);
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
        logger.d('[USP][Network][LAN]: Saved');
      });

      // Force data provider to re-fetch so dashboard card updates too.
      ref.invalidate(lanDataProvider);
    } on ServiceError catch (e) {
      logger.e('[USP][Network][LAN]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // revert — override to also clear validation errors
  // ---------------------------------------------------------------------------

  @override
  void revert() {
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
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

    // Apply sensible defaults when DHCP is toggled from disabled → enabled
    if (!current.model.dhcpEnabled && newModel.dhcpEnabled) {
      newModel = _svc.applyDhcpDefaults(newModel);
    }

    // Auto-sync pool prefix when router IP changes
    if (newModel.ipAddress != current.model.ipAddress &&
        newModel.subnetMask.isNotEmpty) {
      final locked = _svc.lockedOctetCount(newModel.subnetMask);
      if (locked > 0) {
        newModel = newModel.copyWith(
          minAddress:
              _svc.syncPrefix(newModel.minAddress, newModel.ipAddress, locked),
          maxAddress:
              _svc.syncPrefix(newModel.maxAddress, newModel.ipAddress, locked),
        );
      }
    }

    final errors = _svc.validateAll(newModel);

    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: newModel),
      ),
      status: state.status.copyWith(
        validationErrors: errors,
        lockedOctetCount: _svc.lockedOctetCount(newModel.subnetMask),
      ),
    );
  }
}
