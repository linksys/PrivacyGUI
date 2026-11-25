import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';

const _rule = IPv6FirewallRule(
  description: 'NAS',
  ipv6Address: '2001:db8::10',
  isEnabled: true,
  portRanges: [PortRange(protocol: 'TCP', firstPort: 3000, lastPort: 3001)],
);

void main() {
  test('survives a trip through JSON text', () {
    const state = Ipv6PortServiceListState(
        rules: [_rule], maxRules: 15, maxDescriptionLength: 64);

    expect(Ipv6PortServiceListState.fromJson(state.toJson()), state);
  });

  test('falls back to 50 rules of 32 characters when the map omits them', () {
    final state = Ipv6PortServiceListState.fromMap(const {'rules': []});

    expect(state, const Ipv6PortServiceListState());
    expect(state.maxRules, 50);
    expect(state.maxDescriptionLength, 32);
  });

  test('copyWith changes only what it names', () {
    final state = Ipv6PortServiceListState.fromMap({
      'rules': [_rule.toMap()],
      'maxRules': 15,
    });

    final changed = state.copyWith(maxRules: 5, maxDescriptionLength: 8);

    expect(changed.maxRules, 5);
    expect(changed.maxDescriptionLength, 8);
    expect(changed.rules, [_rule]);
    expect(changed.copyWith(maxRules: 15, maxDescriptionLength: 32), state);
  });
}
