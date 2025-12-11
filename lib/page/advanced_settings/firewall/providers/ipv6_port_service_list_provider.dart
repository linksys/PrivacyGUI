import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/ipv6_port_service_list_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final ipv6PortServiceListProvider =
    NotifierProvider<Ipv6PortServiceListNotifier, Ipv6PortServiceListState>(
        () => Ipv6PortServiceListNotifier());

final preservableIpv6PortServiceListProvider = Provider<PreservableContract>(
  (ref) => ref.watch(ipv6PortServiceListProvider.notifier),
);

class Ipv6PortServiceListNotifier extends Notifier<Ipv6PortServiceListState>
    with
        PreservableNotifierMixin<IPv6PortServiceRuleUIList,
            Ipv6PortServiceListStatus, Ipv6PortServiceListState> {
  @override
  Ipv6PortServiceListState build() {
    return const Ipv6PortServiceListState(
      settings: Preservable(
        original: IPv6PortServiceRuleUIList(rules: []),
        current: IPv6PortServiceRuleUIList(rules: []),
      ),
      status: Ipv6PortServiceListStatus(),
    );
  }

  @override
  Future<(IPv6PortServiceRuleUIList?, Ipv6PortServiceListStatus?)>
      performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final repo = ref.read(routerRepositoryProvider);

      // Execute JNAP action to retrieve IPv6 firewall rules
      final result = await repo.send(
        JNAPAction.getIPv6FirewallRules,
        auth: true,
        fetchRemote: forceRemote,
      );

      // Parse Data layer model (JNAP response)
      final dataModel = IPv6FirewallRuleList.fromMap(result.output);

      // Transform to Application layer UI model using service
      final service = IPv6PortServiceListService();
      final (uiRules, _) = await service.fetchPortServiceRules(dataModel.rules);

      if (uiRules == null) {
        return (null, null);
      }

      // Return UI rules with default status
      return (uiRules, const Ipv6PortServiceListStatus());
    } catch (e) {
      throw Exception(
        'Failed to fetch IPv6 port service rules: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> performSave() async {
    // Save is handled individually by add/update/delete operations
    // This implementation is kept for PreservableNotifierMixin compatibility
    throw UnimplementedError(
      'Save is handled by individual add/update/delete operations',
    );
  }

  /// Initializes the rules list (for testing and UI initialization)
  void setRules(List<IPv6PortServiceRuleUI> rules) {
    final ruleList = IPv6PortServiceRuleUIList(rules: rules);
    state = state.copyWith(
      settings: state.settings.copyWith(
        original: ruleList,
        current: ruleList,
      ),
    );
  }

  bool isExceedMax() {
    return state.status.maxRules <= state.current.rules.length;
  }

  Future<void> addRule(IPv6PortServiceRuleUI rule) async {
    // TODO: Implement with IPv6PortServiceListService (US2)
    await fetch(forceRemote: true);
  }

  Future<void> editRule(int index, IPv6PortServiceRuleUI newRule) async {
    // TODO: Implement with IPv6PortServiceListService (US2)
    await fetch(forceRemote: true);
  }

  Future<void> deleteRule(IPv6PortServiceRuleUI rule) async {
    // TODO: Implement with IPv6PortServiceListService (US2)
    await fetch(forceRemote: true);
  }
}
