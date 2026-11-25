import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';

import '../../../test_data/single_port_forwarding_test_state.dart';

/// The first rule of the router-shaped test data.
final _output = Map<String, dynamic>.from(
    (singlePortForwardingListTestState['rules'] as List).first as Map);

void main() {
  test('reads a rule', () {
    final rule = SinglePortForwardingRule.fromMap(_output);

    expect(rule.isEnabled, isFalse);
    expect(rule.externalPort, 999);
    expect(rule.protocol, 'Both');
    expect(rule.internalServerIPAddress, '10.137.1.123');
    expect(rule.internalPort, 9999);
    expect(rule.description, 'XBOX');
  });

  test('writes the fields it read', () {
    expect(SinglePortForwardingRule.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final rule = SinglePortForwardingRule.fromMap(_output);

    expect(SinglePortForwardingRule.fromJson(rule.toJson()), rule);
  });

  test('copyWith changes only what it names', () {
    final rule = SinglePortForwardingRule.fromMap(_output);

    final changed = rule.copyWith(
      isEnabled: true,
      externalPort: 8080,
      protocol: 'Both',
      internalServerIPAddress: '192.168.1.30',
      internalPort: 80,
      description: 'Web',
    );

    expect(changed.toMap(), {
      'isEnabled': true,
      'externalPort': 8080,
      'protocol': 'Both',
      'internalServerIPAddress': '192.168.1.30',
      'internalPort': 80,
      'description': 'Web',
    });
    expect(rule.copyWith(), rule);
  });
}
