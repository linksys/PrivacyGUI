import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/administration/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/page/administration/port_forwarding/providers/consts.dart';

final ipv6PortServiceRuleProvider =
    NotifierProvider<Ipv6PortServiceRuleNotifier, Ipv6PortServiceRuleState>(
        () => Ipv6PortServiceRuleNotifier());

class Ipv6PortServiceRuleNotifier extends Notifier<Ipv6PortServiceRuleState> {
  @override
  Ipv6PortServiceRuleState build() => const Ipv6PortServiceRuleState();

  Future goAdd(List<IPv6FirewallRule> rules) {
    return fetch().then(
        (value) => state = state.copyWith(mode: RuleMode.adding, rules: rules));
  }

  Future goEdit(List<IPv6FirewallRule> rules, IPv6FirewallRule rule) {
    return fetch().then((value) => state =
        state.copyWith(mode: RuleMode.editing, rules: rules, rule: rule));
  }

  Future fetch() async {}

  Future<bool> save(IPv6FirewallRule rule) async {
    final mode = state.mode;
    final rules = List<IPv6FirewallRule>.from(state.rules);
    if (mode == RuleMode.adding) {
      rules.add(rule);
    } else if (mode == RuleMode.editing) {
      int index = state.rules.indexOf(state.rule!);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      JNAPAction.setIPv6FirewallRules,
      auth: true,
      data: {
        'rules': rules.map((e) => e.toMap()).toList(),
      },
    ).then((value) => true);
    return result;
  }

  Future<bool> delete() async {
    final mode = state.mode;
    if (mode == RuleMode.editing) {
      final rules = List<IPv6FirewallRule>.from(state.rules)
        ..removeWhere((element) => element == state.rule);
      final repo = ref.read(routerRepositoryProvider);
      final result = await repo.send(
        JNAPAction.setIPv6FirewallRules,
        auth: true,
        data: {
          'rules': rules.map((e) => e.toMap()).toList(),
        },
      ).then((value) => true);
      return result;
    } else {
      return false;
    }
  }

  bool isEdit() {
    return state.mode == RuleMode.editing;
  }
}
