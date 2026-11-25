import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_provider.dart';

PortRangeForwardingRule _range({
  String description = 'BitTorrent',
  int first = 6888,
  int last = 6900,
  String protocol = 'TCP',
  String device = '192.168.1.150',
}) =>
    PortRangeForwardingRule(
      isEnabled: true,
      firstExternalPort: first,
      lastExternalPort: last,
      protocol: protocol,
      internalServerIPAddress: device,
      description: description,
    );

SinglePortForwardingRule _single(int port, String protocol) =>
    SinglePortForwardingRule(
      isEnabled: true,
      externalPort: port,
      protocol: protocol,
      internalServerIPAddress: '192.168.1.20',
      internalPort: port,
      description: 'Single',
    );

void main() {
  late ProviderContainer container;
  late PortRangeForwardingRuleNotifier notifier;

  PortRangeForwardingRuleState rule() =>
      container.read(portRangeForwardingRuleProvider);

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(portRangeForwardingRuleProvider.notifier);
    // The router is 192.168.1.1/24 and holds one range, 6888 to 6900.
    notifier.init([_range()], null, null, '192.168.1.1', '255.255.255.0');
  });

  tearDown(() => container.dispose());

  test('init holds the list, the rule being edited, its place and the LAN', () {
    final rules = [_range()];

    notifier.init(rules, rules.first, 0, '10.0.0.1', '255.255.0.0');

    expect(
        rule(),
        PortRangeForwardingRuleState(
          rules: rules,
          rule: rules.first,
          editIndex: 0,
          routerIp: '10.0.0.1',
          subnetMask: '255.255.0.0',
        ));
  });

  group('the name and device rules', () {
    test('need a name', () {
      expect(notifier.isNameValid(''), isFalse);
      expect(notifier.isNameValid('Steam'), isTrue);
    });

    test('need a host of the router network', () {
      expect(notifier.isDeviceIpValidate('192.168.1.150'), isTrue);
      expect(notifier.isDeviceIpValidate('192.168.1.1'), isFalse);
      expect(notifier.isDeviceIpValidate('172.16.0.5'), isFalse);
    });
  });

  group('the port range rule', () {
    test('takes a range of one port and a rising range', () {
      expect(notifier.isPortRangeValid(27015, 27015), isTrue);
      expect(notifier.isPortRangeValid(27015, 27030), isTrue);
    });

    test('turns down a range that ends before it starts', () {
      expect(notifier.isPortRangeValid(27030, 27015), isFalse);
    });
  });

  group('the overlap rule, against the other ranges', () {
    test('flags a range that overlaps one on the same protocol', () {
      expect(notifier.isPortConflict(6895, 6910, 'TCP'), isTrue);
      // Ranges share their ends.
      expect(notifier.isPortConflict(6900, 6910, 'TCP'), isTrue);
      expect(notifier.isPortConflict(6880, 6888, 'TCP'), isTrue);
    });

    test('flags an overlap when either side forwards both protocols', () {
      expect(notifier.isPortConflict(6895, 6910, 'Both'), isTrue);

      notifier.init([_range(protocol: 'Both')], null, null, '192.168.1.1',
          '255.255.255.0');
      expect(notifier.isPortConflict(6895, 6910, 'UDP'), isTrue);
    });

    test('lets an overlap through on the other protocol', () {
      expect(notifier.isPortConflict(6895, 6910, 'UDP'), isFalse);
    });

    test('lets a range beside it through', () {
      expect(notifier.isPortConflict(6901, 6910, 'TCP'), isFalse);
    });

    test('does not hold the rule being edited against itself', () {
      notifier.init([_range()], _range(), 0, '192.168.1.1', '255.255.255.0');

      expect(notifier.isPortConflict(6888, 6900, 'TCP'), isFalse);
    });
  });

  group('the overlap rule, against the single ports', () {
    setUp(() => container
        .read(singlePortForwardingListProvider.notifier)
        .addRule(_single(3074, 'TCP')));

    test('flags a range around a single port on the same protocol', () {
      expect(notifier.isPortConflict(3070, 3080, 'TCP'), isTrue);
      expect(notifier.isPortConflict(3070, 3080, 'Both'), isTrue);
    });

    test('flags a range that starts or ends on a single port', () {
      expect(notifier.isPortConflict(3074, 3080, 'TCP'), isTrue);
      expect(notifier.isPortConflict(3070, 3074, 'TCP'), isTrue);
      expect(notifier.isPortConflict(3074, 3074, 'TCP'), isTrue);
    });

    test('lets a range around a single port through on the other protocol', () {
      expect(notifier.isPortConflict(3070, 3080, 'UDP'), isFalse);
    });

    test('lets a range that misses every single port through', () {
      expect(notifier.isPortConflict(3075, 3080, 'TCP'), isFalse);
    });
  });

  group('isRuleValid', () {
    test('has nothing to check before a rule is open', () {
      expect(notifier.isRuleValid(), isFalse);
    });

    test('accepts a named rule to a LAN device on a free rising range', () {
      notifier
          .updateRule(_range(description: 'Steam', first: 27015, last: 27030));

      expect(notifier.isRuleValid(), isTrue);
    });

    test('turns down a rule that breaks any one rule', () {
      final broken = <String, PortRangeForwardingRule>{
        'no name': _range(description: '', first: 27015, last: 27030),
        'a device off the LAN':
            _range(first: 27015, last: 27030, device: '10.0.0.5'),
        'a falling range': _range(first: 27030, last: 27015),
        'an overlap': _range(description: 'Again', first: 6890, last: 6895),
      };

      for (final MapEntry(key: reason, value: candidate) in broken.entries) {
        notifier.updateRule(candidate);
        expect(notifier.isRuleValid(), isFalse, reason: reason);
      }
    });
  });
}
