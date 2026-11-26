import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';

/// One rule of `GetPortRangeForwardingRules`, the legacy JNAP reference's
/// sample.
const _output = <String, dynamic>{
  'isEnabled': true,
  'firstExternalPort': 6888,
  'lastExternalPort': 6900,
  'protocol': 'Both',
  'internalServerIPAddress': '192.168.1.150',
  'description': 'BitTorrent',
};

void main() {
  test('reads a rule', () {
    final rule = PortRangeForwardingRule.fromMap(_output);

    expect(rule.isEnabled, isTrue);
    expect(rule.firstExternalPort, 6888);
    expect(rule.lastExternalPort, 6900);
    expect(rule.protocol, 'Both');
    expect(rule.internalServerIPAddress, '192.168.1.150');
    expect(rule.description, 'BitTorrent');
  });

  test('writes the fields it read', () {
    expect(PortRangeForwardingRule.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final rule = PortRangeForwardingRule.fromMap(_output);

    expect(PortRangeForwardingRule.fromJson(rule.toJson()), rule);
  });

  test('copyWith changes only what it names', () {
    final rule = PortRangeForwardingRule.fromMap(_output);

    final changed = rule.copyWith(
      isEnabled: false,
      firstExternalPort: 27015,
      lastExternalPort: 27030,
      protocol: 'UDP',
      internalServerIPAddress: '192.168.1.60',
      description: 'Steam',
    );

    expect(changed.toMap(), {
      'isEnabled': false,
      'firstExternalPort': 27015,
      'lastExternalPort': 27030,
      'protocol': 'UDP',
      'internalServerIPAddress': '192.168.1.60',
      'description': 'Steam',
    });
    expect(rule.copyWith(), rule);
  });
}
