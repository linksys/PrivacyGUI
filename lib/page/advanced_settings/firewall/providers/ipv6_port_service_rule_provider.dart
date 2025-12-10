import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    List<IPv6PortServiceRuleUI> rules,
    IPv6PortServiceRuleUI? rule,
    int? index,
  ) {
    state = state.copyWith(
      rules: rules,
      rule: () => rule,
      editIndex: () => index,
    );
  }

  void updateRule(IPv6PortServiceRuleUI? rule) {
    state = state.copyWith(rule: () => rule);
  }

  bool isRuleValid() {
    // TODO: Implement validation for IPv6 port service rules with portRanges (US2)
    final rule = state.rule;
    return rule != null && rule.description.isNotEmpty && rule.ipv6Address.isNotEmpty;
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
    // TODO: Implement port conflict checking for portRanges (US2)
    return false;
  }
}
