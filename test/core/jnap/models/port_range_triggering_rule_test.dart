import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';

/// One rule of `GetPortRangeTriggeringRules`, after the spec's sample.
const _output = <String, dynamic>{
  'isEnabled': true,
  'firstTriggerPort': 6667,
  'lastTriggerPort': 6669,
  'firstForwardedPort': 113,
  'lastForwardedPort': 114,
  'description': 'IRC',
};

void main() {
  test('reads a rule', () {
    final rule = PortRangeTriggeringRule.fromMap(_output);

    expect(rule.isEnabled, isTrue);
    expect(rule.firstTriggerPort, 6667);
    expect(rule.lastTriggerPort, 6669);
    expect(rule.firstForwardedPort, 113);
    expect(rule.lastForwardedPort, 114);
    expect(rule.description, 'IRC');
  });

  test('writes the fields it read', () {
    expect(PortRangeTriggeringRule.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final rule = PortRangeTriggeringRule.fromMap(_output);

    expect(PortRangeTriggeringRule.fromJson(rule.toJson()), rule);
  });

  test('copyWith changes only what it names', () {
    final rule = PortRangeTriggeringRule.fromMap(_output);

    final changed = rule.copyWith(
      isEnabled: false,
      firstTriggerPort: 12000,
      lastTriggerPort: 12050,
      firstForwardedPort: 12100,
      lastForwardedPort: 12150,
      description: 'custom',
    );

    expect(changed.toMap(), {
      'isEnabled': false,
      'firstTriggerPort': 12000,
      'lastTriggerPort': 12050,
      'firstForwardedPort': 12100,
      'lastForwardedPort': 12150,
      'description': 'custom',
    });
    expect(rule.copyWith(), rule);
  });
}
