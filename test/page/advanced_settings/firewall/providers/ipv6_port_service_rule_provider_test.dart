import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

IPv6FirewallRule _rule({
  String description = 'NAS',
  String address = '2001:db8::10',
  String protocol = 'TCP',
  int first = 3000,
  int last = 3010,
}) =>
    IPv6FirewallRule(
      description: description,
      ipv6Address: address,
      isEnabled: true,
      portRanges: [
        PortRange(protocol: protocol, firstPort: first, lastPort: last),
      ],
    );

void main() {
  late ProviderContainer container;
  late Ipv6PortServiceRuleNotifier notifier;

  Ipv6PortServiceRuleState rule() =>
      container.read(ipv6PortServiceRuleProvider);

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(ipv6PortServiceRuleProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('init holds the list, the rule being edited and its place', () {
    final existing = [_rule()];

    notifier.init(existing, existing.first, 0);

    expect(rule().rules, existing);
    expect(rule().rule, existing.first);
    expect(rule().editIndex, 0);
  });

  group('the name rule', () {
    test('needs a name', () {
      expect(notifier.isRuleNameValidate(''), isFalse);
    });

    test('takes up to 32 characters', () {
      expect(notifier.isRuleNameValidate('a' * 32), isTrue);
      expect(notifier.isRuleNameValidate('a' * 33), isFalse);
    });
  });

  group('the device address rule', () {
    test('takes a full or a shortened IPv6 address', () {
      expect(notifier.isDeviceIpValidate('2001:db8:0:0:0:0:0:10'), isTrue);
      expect(notifier.isDeviceIpValidate('2001:db8::10'), isTrue);
    });

    test('turns down an IPv4 address, junk and the unspecified address', () {
      expect(notifier.isDeviceIpValidate('192.168.1.10'), isFalse);
      expect(notifier.isDeviceIpValidate('2001:db8::zz'), isFalse);
      expect(notifier.isDeviceIpValidate('::'), isFalse);
    });
  });

  group('the port range rule', () {
    test('takes a range of one port and a rising range', () {
      expect(notifier.isPortRangeValid(80, 80), isTrue);
      expect(notifier.isPortRangeValid(80, 90), isTrue);
    });

    test('turns down a range that ends before it starts', () {
      expect(notifier.isPortRangeValid(90, 80), isFalse);
    });
  });

  group('the overlap rule', () {
    setUp(() => notifier.init([_rule(first: 3000, last: 3010)], null, null));

    test('flags a range that overlaps a rule on the same protocol', () {
      expect(notifier.isPortConflict(3005, 3020, 'TCP'), isTrue);
      // Ranges share their ends.
      expect(notifier.isPortConflict(3010, 3020, 'TCP'), isTrue);
      expect(notifier.isPortConflict(2990, 3000, 'TCP'), isTrue);
    });

    test('flags a range on both protocols that overlaps any rule', () {
      expect(notifier.isPortConflict(3005, 3005, 'Both'), isTrue);
    });

    test('lets a range sit beside a rule', () {
      expect(notifier.isPortConflict(3011, 3020, 'TCP'), isFalse);
    });

    test('lets a range overlap a rule on the other protocol', () {
      expect(notifier.isPortConflict(3005, 3005, 'UDP'), isFalse);
    });

    test('does not hold the rule being edited against itself', () {
      notifier.init([_rule(first: 3000, last: 3010)], _rule(), 0);

      expect(notifier.isPortConflict(3000, 3010, 'TCP'), isFalse);
    });
  });

  group('isRuleValid', () {
    test('has nothing to check before a rule is open', () {
      expect(notifier.isRuleValid(), isFalse);
    });

    test('accepts a named rule to an IPv6 device on a free range', () {
      notifier.init([_rule(first: 3000, last: 3010)], null, null);
      notifier.updateRule(_rule(description: 'Game', first: 4000, last: 4010));

      expect(notifier.isRuleValid(), isTrue);
    });

    test('turns down a rule that breaks any one rule', () {
      notifier.init([_rule(first: 3000, last: 3010)], null, null);
      final broken = <String, IPv6FirewallRule>{
        'no name': _rule(description: '', first: 4000, last: 4010),
        'an IPv4 device':
            _rule(address: '192.168.1.10', first: 4000, last: 4010),
        'a falling range': _rule(first: 4010, last: 4000),
        'an overlap': _rule(first: 3005, last: 3006),
      };

      for (final MapEntry(key: reason, value: candidate) in broken.entries) {
        notifier.updateRule(candidate);
        expect(notifier.isRuleValid(), isFalse, reason: reason);
      }
    });
  });
}
