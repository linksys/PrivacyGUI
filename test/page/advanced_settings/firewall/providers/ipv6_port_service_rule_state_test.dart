import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

const _rule = IPv6FirewallRule(
  description: 'NAS',
  ipv6Address: '2001:db8::10',
  isEnabled: true,
  portRanges: [PortRange(protocol: 'TCP', firstPort: 3000, lastPort: 3001)],
);

void main() {
  test('survives a trip through JSON text', () {
    const state =
        Ipv6PortServiceRuleState(rules: [_rule], rule: _rule, editIndex: 0);

    expect(Ipv6PortServiceRuleState.fromJson(state.toJson()), state);
  });

  test('reads an add, with no rule or place yet', () {
    final state = Ipv6PortServiceRuleState.fromMap(const {'rules': []});

    expect(state, const Ipv6PortServiceRuleState());
  });

  test('copyWith can clear the rule and its place', () {
    const state =
        Ipv6PortServiceRuleState(rules: [_rule], rule: _rule, editIndex: 0);

    final cleared = state.copyWith(rule: () => null, editIndex: () => null);

    expect(cleared, const Ipv6PortServiceRuleState(rules: [_rule]));
    expect(state.copyWith(), state);
  });
}
