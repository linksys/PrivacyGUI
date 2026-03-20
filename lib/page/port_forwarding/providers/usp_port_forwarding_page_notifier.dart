import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_feature_state.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_settings.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_status.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspPortForwardingPageProvider = AutoDisposeNotifierProvider<
    UspPortForwardingPageNotifier, PortForwardingPageFeatureState>(
  UspPortForwardingPageNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspPortForwardingPageProvider = AutoDisposeProvider<
    PreservableContract<PortForwardingPageSettings, PortForwardingPageStatus>>(
  (ref) => ref.watch(uspPortForwardingPageProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspPortForwardingPageNotifier
    extends AutoDisposeNotifier<PortForwardingPageFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<PortForwardingPageSettings,
            PortForwardingPageStatus, PortForwardingPageFeatureState> {
  UspPortForwardingService get _svc =>
      ref.read(uspPortForwardingServiceProvider);

  @override
  PortForwardingPageFeatureState build() {
    // SSE invalidation: re-fetch when port forwarding changes externally.
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.valueOrNull == InvalidationDomain.portForwarding) {
        onSseInvalidation();
      }
    });

    Future.microtask(() => fetch());
    return PortForwardingPageFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch
  // ---------------------------------------------------------------------------

  @override
  Future<(PortForwardingPageSettings?, PortForwardingPageStatus?)>
      performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final results = await Future.wait([
        _svc.fetchForwardingRules(),
        _svc.fetchTriggeringRules(),
      ]);

      final forwardingRules = results[0] as List<PortForwardingRuleUIModel>;
      final triggeringRules = results[1] as List<PortTriggeringRuleUIModel>;

      logger.d('[USP][Firewall][PortForwarding] Fetched — '
          'forwarding: ${forwardingRules.length}, '
          'triggering: ${triggeringRules.length}');

      return (
        PortForwardingPageSettings(
          forwardingRules: forwardingRules,
          triggeringRules: triggeringRules,
        ),
        const PortForwardingPageStatus(),
      );
    } catch (e) {
      logger.e('[USP][Firewall][PortForwarding] Fetch failed', error: e);
      return (
        null,
        PortForwardingPageStatus(errorMessage: '$e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — diff original vs current, batch API calls
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final originalPf = state.settings.original.forwardingRules;
      final currentPf = state.settings.current.forwardingRules;
      final originalPt = state.settings.original.triggeringRules;
      final currentPt = state.settings.current.triggeringRules;

      await ref.read(uspMutationLockProvider).withLock(() async {
        final pfResult = await _svc.saveForwardingBatch(
          original: originalPf,
          current: currentPf,
        );

        final ptResult = await _svc.saveTriggeringBatch(
          original: originalPt,
          current: currentPt,
        );

        logger.d('[USP][Firewall][PortForwarding] Batch save — '
            'PF added: ${pfResult.added}, updated: ${pfResult.updated}, '
            'deleted: ${pfResult.deleted} | '
            'PT added: ${ptResult.added}, updated: ${ptResult.updated}, '
            'deleted: ${ptResult.deleted}');
      });

      // Invalidate Layer 1 providers to refresh dashboard card
      ref.invalidate(portForwardingDataProvider);
      ref.invalidate(portTriggeringDataProvider);
    } catch (e) {
      logger.e('[USP][Firewall][PortForwarding] Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Local Mutations — Port Forwarding
  // ---------------------------------------------------------------------------

  void addForwardingRule(PortForwardingRuleUIModel rule) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: [...current.forwardingRules, rule],
          triggeringRules: current.triggeringRules,
        ),
      ),
    );
  }

  void editForwardingRule(
      PortForwardingRuleUIModel oldRule, PortForwardingRuleUIModel newRule) {
    final rules = List<PortForwardingRuleUIModel>.from(
        state.settings.current.forwardingRules);
    final index = rules.indexOf(oldRule);
    if (index == -1) return;
    rules[index] = newRule;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: rules,
          triggeringRules: state.settings.current.triggeringRules,
        ),
      ),
    );
  }

  void toggleForwardingRule(PortForwardingRuleUIModel rule, bool enabled) {
    editForwardingRule(rule, rule.copyWith(enabled: enabled));
  }

  void deleteForwardingRule(PortForwardingRuleUIModel rule) {
    final rules = List<PortForwardingRuleUIModel>.from(
        state.settings.current.forwardingRules);
    rules.remove(rule);
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: rules,
          triggeringRules: state.settings.current.triggeringRules,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Local Mutations — Port Triggering
  // ---------------------------------------------------------------------------

  void addTriggeringRule(PortTriggeringRuleUIModel rule) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: current.forwardingRules,
          triggeringRules: [...current.triggeringRules, rule],
        ),
      ),
    );
  }

  void editTriggeringRule(
      PortTriggeringRuleUIModel oldRule, PortTriggeringRuleUIModel newRule) {
    final rules = List<PortTriggeringRuleUIModel>.from(
        state.settings.current.triggeringRules);
    final index = rules.indexOf(oldRule);
    if (index == -1) return;
    rules[index] = newRule;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: state.settings.current.forwardingRules,
          triggeringRules: rules,
        ),
      ),
    );
  }

  void toggleTriggeringRule(PortTriggeringRuleUIModel rule, bool enabled) {
    editTriggeringRule(rule, rule.copyWith(enabled: enabled));
  }

  void deleteTriggeringRule(PortTriggeringRuleUIModel rule) {
    final rules = List<PortTriggeringRuleUIModel>.from(
        state.settings.current.triggeringRules);
    rules.remove(rule);
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: state.settings.current.forwardingRules,
          triggeringRules: rules,
        ),
      ),
    );
  }
}
