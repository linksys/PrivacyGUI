import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/usp_page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/usp_page/firewall/services/usp_firewall_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspFirewallProvider =
    AutoDisposeNotifierProvider<UspFirewallNotifier, FirewallFeatureState>(
  UspFirewallNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspFirewallProvider = AutoDisposeProvider<
    PreservableContract<FirewallSettings, FirewallStatus>>(
  (ref) => ref.watch(uspFirewallProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspFirewallNotifier extends AutoDisposeNotifier<FirewallFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<FirewallSettings, FirewallStatus,
            FirewallFeatureState> {
  UspFirewallService get _svc => ref.read(uspFirewallServiceProvider);

  @override
  FirewallFeatureState build() {
    // Listen to data provider for SSE-driven changes.
    // Uses the framework's onSseInvalidation() — skips if dirty.
    ref.listen(firewallDataProvider, (_, next) {
      if (next.hasValue) onSseInvalidation();
    });

    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return FirewallFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      // Clone data from the shared data provider (read, not watch).
      final data = await ref.read(firewallDataProvider.future);

      final (uiModel, ruleContext) =
          _svc.buildFromChainRules(data.chainRules);

      logger.d('[USP][Firewall] Fetched — '
          'spiV4: ${uiModel.isIPv4FirewallEnabled}, '
          'spiV6: ${uiModel.isIPv6FirewallEnabled}');

      return (
        FirewallSettings(model: uiModel, ruleContext: ruleContext),
        const FirewallStatus(isLoading: false),
      );
    } catch (e) {
      logger.e('[USP][Firewall] Fetch failed', error: e);
      return (
        null,
        FirewallStatus(isLoading: false, errorMessage: '$e'),
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
      final settings = state.settings.current;

      await ref.read(uspMutationLockProvider).withLock(() async {
        final count = await _svc.save(
          original: state.settings.original.model,
          pending: settings.model,
          context: settings.ruleContext,
        );

        logger.d('[USP][Firewall] Saved — $count rules updated');
      });

      // Force data provider to re-fetch so dashboard card updates too.
      ref.invalidate(firewallDataProvider);
    } catch (e) {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — no network call)
  // ---------------------------------------------------------------------------

  /// Update a single firewall toggle.
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: updater(current.model)),
      ),
    );
  }
}
