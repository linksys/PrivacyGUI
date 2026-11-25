import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';

/// One rule of `GetIPv6FirewallRules`, the spec's sample with two ranges.
const _output = <String, dynamic>{
  'isEnabled': true,
  'ipv6Address': '2001:0DB8:85A3:0000:0000:8A2E:0370:7334',
  'portRanges': [
    {'protocol': 'TCP', 'firstPort': 3000, 'lastPort': 3001},
    {'protocol': 'UDP', 'firstPort': 5000, 'lastPort': 5000},
  ],
  'description': 'ports 3000-3001',
};

void main() {
  test('reads a rule and each of its port ranges', () {
    final rule = IPv6FirewallRule.fromMap(_output);

    expect(rule.isEnabled, isTrue);
    expect(rule.ipv6Address, '2001:0DB8:85A3:0000:0000:8A2E:0370:7334');
    expect(rule.description, 'ports 3000-3001');
    expect(rule.portRanges, const [
      PortRange(protocol: 'TCP', firstPort: 3000, lastPort: 3001),
      PortRange(protocol: 'UDP', firstPort: 5000, lastPort: 5000),
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
