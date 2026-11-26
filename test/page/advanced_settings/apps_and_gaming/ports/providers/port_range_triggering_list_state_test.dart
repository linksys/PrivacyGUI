import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_state.dart';

const _rule = PortRangeTriggeringRule(
  isEnabled: true,
  firstTriggerPort: 12000,
  lastTriggerPort: 12050,
  firstForwardedPort: 12000,
  lastForwardedPort: 12050,
  description: 'custom',
);

void main() {
  test('survives a trip through JSON text', () {
    const state = PortRangeTriggeringListState(
        rules: [_rule], maxRules: 15, maxDescriptionLength: 12);

    expect(PortRangeTriggeringListState.fromJson(state.toJson()), state);
  });

  test('falls back to 50 rules of 32 characters when the map omits them', () {
    final state = PortRangeTriggeringListState.fromMap(const {'rules': []});

    expect(state, const PortRangeTriggeringListState());
  });

  test('copyWith changes only what it names', () {
    const state = PortRangeTriggeringListState(rules: [_rule]);

    expect(state.copyWith(maxDescriptionLength: 8).maxDescriptionLength, 8);
    expect(state.copyWith(), state);
  });
}
