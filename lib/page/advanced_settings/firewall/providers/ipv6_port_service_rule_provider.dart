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
    final rule = state.rule;
    if (rule == null || rule.description.isEmpty || rule.ipv6Address.isEmpty) {
      return false;
    }
    // Validate port ranges
    if (rule.portRanges.isEmpty) {
      return false;
    }
    // All port ranges must be valid
    return rule.portRanges.every((portRange) =>
        isPortRangeValid(portRange.firstPort, portRange.lastPort));
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
    final currentRule = state.rule;
    if (currentRule == null) {
      return false;
    }

    // Check against other rules in the list
    for (int i = 0; i < state.rules.length; i++) {
      final otherRule = state.rules[i];

      // Skip comparing with self (when editing)
      if (state.editIndex != null && i == state.editIndex) {
        continue;
      }

      // Check for port range overlap with same or compatible protocol
      for (final otherRange in otherRule.portRanges) {
        if (_protocolsCompatible(protocol, otherRange.protocol)) {
          if (_portRangesOverlap(firstPort, lastPort, otherRange.firstPort, otherRange.lastPort)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Check if two protocols have overlapping port ranges
  /// TCP and Both overlap, UDP and Both overlap, But TCP and UDP don't
  bool _protocolsCompatible(String protocol1, String protocol2) {
    if (protocol1 == protocol2) return true;
    if (protocol1 == 'Both' || protocol2 == 'Both') return true;
    return false;
  }

  /// Check if two port ranges overlap
  bool _portRangesOverlap(int start1, int end1, int start2, int end2) {
    return !(end1 < start2 || end2 < start1);
  }
}

