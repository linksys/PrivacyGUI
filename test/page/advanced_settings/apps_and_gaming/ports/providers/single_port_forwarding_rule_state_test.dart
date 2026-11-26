import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_rule_state.dart';

const _rule = SinglePortForwardingRule(
  isEnabled: true,
  externalPort: 3074,
  protocol: 'TCP',
  internalServerIPAddress: '192.168.1.150',
  internalPort: 3074,
  description: 'XBox Live (TM)',
);

const _state = SinglePortForwardingRuleState(
  rules: [_rule],
  rule: _rule,
  editIndex: 0,
  routerIp: '192.168.1.1',
  subnetMask: '255.255.255.0',
);

void main() {
  test('survives a trip through JSON text', () {
    expect(SinglePortForwardingRuleState.fromJson(_state.toJson()), _state);
  });

  test('reads an add, with no rule or place yet', () {
    final state = SinglePortForwardingRuleState.fromMap(const {'rules': []});

    expect(state.rule, isNull);
    expect(state.editIndex, isNull);
    expect(state.routerIp, '');
  });

  test('copyWith can clear the rule and its place', () {
    final cleared = _state.copyWith(rule: () => null, editIndex: () => null);

    expect(cleared.rule, isNull);
    expect(cleared.editIndex, isNull);
    expect(_state.copyWith(), _state);
    expect(_state.toString(), contains('editIndex: 0'));
  });
}
