import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';

final ipv6PortServiceListProvider =
    NotifierProvider<Ipv6PortServiceListNotifier, Ipv6PortServiceListState>(
        () => Ipv6PortServiceListNotifier());

class Ipv6PortServiceListNotifier extends Notifier<Ipv6PortServiceListState> {
  @override
  Ipv6PortServiceListState build() => const Ipv6PortServiceListState();

  Future fetch([bool force = false]) {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getIPv6FirewallRules, auth: true, fetchRemote: force)
        .then((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => IPv6FirewallRule.fromMap(e))
          .toList();
      final int maxRules = value.output['maxRules'] ?? 50;
      final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
      state = state.copyWith(
          rules: rules, maxRules: maxRules, maxDescriptionLength: maxDesc);
    });
  }

  bool isExceedMax() {
    return state.maxRules == state.rules.length;
  }
}
