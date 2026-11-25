import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_rule_state.dart';

const _rule = PortRangeTriggeringRule(
  isEnabled: true,
  firstTriggerPort: 12000,
  lastTriggerPort: 12050,
  firstForwardedPort: 12000,
  lastForwardedPort: 12050,
  description: 'custom',
);

const _state =
    PortRangeTriggeringRuleState(rules: [_rule], rule: _rule, editIndex: 0);

void main() {
  test('survives a trip through JSON text', () {
    expect(PortRangeTriggeringRuleState.fromJson(_state.toJson()), _state);
  });

  test('reads an add, with no rule or place yet', () {
    final state = PortRangeTriggeringRuleState.fromMap(const {'rules': []});

    expect(state, const PortRangeTriggeringRuleState());
  });

  test('copyWith can clear the rule and its place', () {
    final cleared = _state.copyWith(rule: () => null, editIndex: () => null);

    expect(cleared, const PortRangeTriggeringRuleState(rules: [_rule]));
    expect(_state.copyWith(), _state);
    expect(_state.toString(), contains('editIndex: 0'));
  });
}
