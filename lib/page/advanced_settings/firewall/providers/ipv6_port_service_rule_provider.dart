import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_util_mixin.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final ipv6PortServiceRuleProvider =
    NotifierProvider<Ipv6PortServiceRuleNotifier, Ipv6PortServiceRuleState>(
        () => Ipv6PortServiceRuleNotifier());

class Ipv6PortServiceRuleNotifier extends Notifier<Ipv6PortServiceRuleState>
    with PortUtilMixin {
  @override
  Ipv6PortServiceRuleState build() => const Ipv6PortServiceRuleState();

  void init(
    List<IPv6FirewallRule> rules,
    IPv6FirewallRule? rule,
    int? index,
  ) {
    state = state.copyWith(
      rules: rules,
      rule: () => rule,
      editIndex: () => index,
    );
  }

  void updateRule(IPv6FirewallRule? rule) {
    state = state.copyWith(rule: () => rule);
  }

  bool isRuleValid() {
    final rule = state.rule;
    if (rule == null) {
      return false;
    }
    return isRuleNameValidate(rule.description) &&
        isDeviceIpValidate(rule.ipv6Address) &&
        isPortRangeValid(
          rule.portRanges.first.firstPort,
          rule.portRanges.first.lastPort,
        ) &&
        !isPortConflict(
          rule.portRanges.first.firstPort,
          rule.portRanges.first.lastPort,
          rule.portRanges.first.protocol,
        );
  }

  bool isRuleNameValidate(String ruleName) {
    return ruleName.isNotEmpty && ruleName.length <= 32;
  }

  bool isDeviceIpValidate(String ipAddress) {
    return IPv6Rule().validate(ipAddress);
  }

  bool isPortRangeValid(int firstPort, int lastPort) {
    return lastPort - firstPort >= 0;
  }

  bool isPortConflict(int firstPort, int lastPort, String protocol) {
    return state.rules
        .whereIndexed((index, rule) => index != state.editIndex)
        .any((rule) =>
            doesRangeOverlap(
              rule.portRanges.first.firstPort,
              rule.portRanges.first.lastPort,
              firstPort,
              lastPort,
            ) &&
            (protocol == rule.portRanges.first.protocol || protocol == 'Both'));
  }
}
