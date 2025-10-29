import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';
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
        PreservableNotifierMixin<IPv6FirewallRuleList,
            Ipv6PortServiceListStatus, Ipv6PortServiceListState> {
  @override
  Ipv6PortServiceListState build() => const Ipv6PortServiceListState(
        settings: Preservable(
            original: IPv6FirewallRuleList(rules: []),
            current: IPv6FirewallRuleList(rules: [])),
        status: Ipv6PortServiceListStatus(),
      );

  @override
  Future<(IPv6FirewallRuleList?, Ipv6PortServiceListStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final value = await ref.read(routerRepositoryProvider).send(
        JNAPAction.getIPv6FirewallRules,
        auth: true,
        fetchRemote: forceRemote);
    final rules = List.from(value.output['rules'])
        .map((e) => IPv6FirewallRule.fromMap(e))
        .toList();
    final int maxRules = value.output['maxRules'] ?? 50;
    final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
    final status = Ipv6PortServiceListStatus(
        maxRules: maxRules, maxDescriptionLength: maxDesc);
    return (IPv6FirewallRuleList(rules: rules), status);
  }

  @override
  Future<void> performSave() async {
    final rules = state.settings.current;

    await ref.read(routerRepositoryProvider).send(
      JNAPAction.setIPv6FirewallRules,
      auth: true,
      data: {
        'rules': rules.rules.map((e) => e.toMap()).toList(),
      },
    );
  }

  bool isExceedMax() {
    return state.status.maxRules == state.current.rules.length;
  }

  void addRule(IPv6FirewallRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: IPv6FirewallRuleList(
                rules: List.from(state.settings.current.rules)..add(rule))));
  }

  void editRule(int index, IPv6FirewallRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: IPv6FirewallRuleList(
                rules: List.from(state.settings.current.rules)
                  ..replaceRange(index, index + 1, [rule]))));
  }

  void deleteRule(IPv6FirewallRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: IPv6FirewallRuleList(
                rules: List.from(state.settings.current.rules)..remove(rule))));
  }
}
