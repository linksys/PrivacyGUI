import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';

import '../../../test_data/ipv6_port_service_list_test_state.dart';

/// The first rule of the router-shaped test data, as JSON on the wire.
final _output = jsonDecode(
        jsonEncode((ipv6PortServiceListTestState['rules'] as List).first))
    as Map<String, dynamic>;

void main() {
  test('reads a rule and its port range', () {
    final rule = IPv6FirewallRule.fromMap(_output);

    expect(rule.isEnabled, isTrue);
    expect(rule.ipv6Address, '1111:1111:1111:1111:1111:1111:1111:ffff');
    expect(rule.description, '222');
    expect(rule.portRanges, const [
      PortRange(protocol: 'Both', firstPort: 1223, lastPort: 1235),
    ]);
  });

  test('writes the fields it read', () {
    expect(IPv6FirewallRule.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final rule = IPv6FirewallRule.fromMap(_output);

    expect(IPv6FirewallRule.fromJson(rule.toJson()), rule);
    expect(PortRange.fromJson(rule.portRanges.first.toJson()),
        rule.portRanges.first);
  });

  test('copyWith changes only what it names', () {
    final rule = IPv6FirewallRule.fromMap(_output);
    const range = PortRange(protocol: 'TCP', firstPort: 3000, lastPort: 3001);

    expect(rule.copyWith(isEnabled: false).isEnabled, isFalse);
    expect(rule.copyWith(), rule);
    expect(range.copyWith(lastPort: 3005),
        const PortRange(protocol: 'TCP', firstPort: 3000, lastPort: 3005));
    expect(range.copyWith(), range);
  });
}
