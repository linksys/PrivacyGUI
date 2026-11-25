import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';

/// One rule of `GetSinglePortForwardingRules`, the spec's sample.
const _output = <String, dynamic>{
  'isEnabled': true,
  'externalPort': 3074,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.150',
  'internalPort': 3074,
  'description': 'XBox Live (TM)',
};

void main() {
  test('reads a rule', () {
    final rule = SinglePortForwardingRule.fromMap(_output);

    expect(rule.isEnabled, isTrue);
    expect(rule.externalPort, 3074);
    expect(rule.protocol, 'TCP');
    expect(rule.internalServerIPAddress, '192.168.1.150');
    expect(rule.internalPort, 3074);
    expect(rule.description, 'XBox Live (TM)');
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
      isEnabled: false,
      externalPort: 8080,
      protocol: 'Both',
      internalServerIPAddress: '192.168.1.30',
      internalPort: 80,
      description: 'Web',
    );

    expect(changed.toMap(), {
      'isEnabled': false,
      'externalPort': 8080,
      'protocol': 'Both',
      'internalServerIPAddress': '192.168.1.30',
      'internalPort': 80,
      'description': 'Web',
    });
    expect(rule.copyWith(), rule);
  });
}
