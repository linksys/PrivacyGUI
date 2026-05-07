import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_feature_state.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_rule_list.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspIpv6PortServiceProvider = AutoDisposeNotifierProvider<
    UspIpv6PortServiceNotifier, Ipv6PortServiceFeatureState>(
  UspIpv6PortServiceNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspIpv6PortServiceProvider = AutoDisposeProvider<
    PreservableContract<Ipv6PortServiceRuleList, Ipv6PortServiceStatus>>(
  (ref) => ref.watch(uspIpv6PortServiceProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspIpv6PortServiceNotifier
    extends AutoDisposeNotifier<Ipv6PortServiceFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<Ipv6PortServiceRuleList,
            Ipv6PortServiceStatus, Ipv6PortServiceFeatureState> {
  UspIpv6PortServiceService get _svc =>
      ref.read(uspIpv6PortServiceServiceProvider);

  @override
  Ipv6PortServiceFeatureState build() {
    // No SSE invalidation domain for IPv6 port service currently.
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return Ipv6PortServiceFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch
  // ---------------------------------------------------------------------------

  @override
  Future<(Ipv6PortServiceRuleList?, Ipv6PortServiceStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final rules = await _svc.fetch();

      logger.d('[USP][Firewall][IPv6Port]: Fetched — ipv6: ${rules.length}');

      return (
        Ipv6PortServiceRuleList(rules: rules),
        const Ipv6PortServiceStatus(),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Firewall][IPv6Port]: Fetch failed', error: e);
      return (
        null,
        Ipv6PortServiceStatus(errorMessage: '$e'),
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
      final original = state.settings.original.rules;
      final current = state.settings.current.rules;

      await ref.read(uspMutationLockProvider).withLock(() async {
        final result = await _svc.saveBatch(
          original: original,
          current: current,
        );

        logger.d('[USP][Firewall][IPv6Port]: Batch save — '
            'added: ${result.added}, updated: ${result.updated}, '
            'deleted: ${result.deleted}');
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Firewall][IPv6Port]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Local Mutations (synchronous — no network calls)
  // ---------------------------------------------------------------------------

  void addRule(Ipv6PortServiceRuleUIModel rule) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        Ipv6PortServiceRuleList(rules: [...current.rules, rule]),
      ),
    );
  }

  void editRule(int index, Ipv6PortServiceRuleUIModel rule) {
    final rules =
        List<Ipv6PortServiceRuleUIModel>.from(state.settings.current.rules);
    rules[index] = rule;
    state = state.copyWith(
      settings: state.settings.update(Ipv6PortServiceRuleList(rules: rules)),
    );
  }

  void toggleRule(int index, bool enabled) {
    final rules =
        List<Ipv6PortServiceRuleUIModel>.from(state.settings.current.rules);
    rules[index] = rules[index].copyWith(enabled: enabled);
    state = state.copyWith(
      settings: state.settings.update(Ipv6PortServiceRuleList(rules: rules)),
    );
  }

  void deleteRule(int index) {
    final rules =
        List<Ipv6PortServiceRuleUIModel>.from(state.settings.current.rules);
    rules.removeAt(index);
    state = state.copyWith(
      settings: state.settings.update(Ipv6PortServiceRuleList(rules: rules)),
    );
  }
}
