import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_rule_state.dart';

SinglePortForwardingRule _single({
  String description = 'XBox',
  int port = 3074,
  String protocol = 'TCP',
  String device = '192.168.1.150',
}) =>
    SinglePortForwardingRule(
      isEnabled: true,
      externalPort: port,
      protocol: protocol,
      internalServerIPAddress: device,
      internalPort: port,
      description: description,
    );

PortRangeForwardingRule _range(int first, int last, String protocol) =>
    PortRangeForwardingRule(
      isEnabled: true,
      firstExternalPort: first,
      lastExternalPort: last,
      protocol: protocol,
      internalServerIPAddress: '192.168.1.40',
      description: 'Range',
    );

void main() {
  late ProviderContainer container;
  late SinglePortForwardingRuleNotifier notifier;

  SinglePortForwardingRuleState rule() =>
      container.read(singlePortForwardingRuleProvider);

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(singlePortForwardingRuleProvider.notifier);
    // The router is 192.168.1.1/24 and holds one single-port rule.
    notifier.init([_single()], null, null, '192.168.1.1', '255.255.255.0');
  });

  tearDown(() => container.dispose());

  test('init holds the list, the rule being edited, its place and the LAN', () {
    final rules = [_single()];

    notifier.init(rules, rules.first, 0, '10.0.0.1', '255.255.0.0');

    expect(
        rule(),
        SinglePortForwardingRuleState(
          rules: rules,
          rule: rules.first,
          editIndex: 0,
          routerIp: '10.0.0.1',
          subnetMask: '255.255.0.0',
        ));
  });

  group('the name rule', () {
    test('needs a name', () {
      expect(notifier.isNameValid(''), isFalse);
      expect(notifier.isNameValid('XBox'), isTrue);
    });
  });

  group('the device address rule', () {
    test('takes a host of the router network', () {
      expect(notifier.isDeviceIpValidate('192.168.1.150'), isTrue);
    });

    test('turns down the router, the network address and other networks', () {
      // The broadcast address, 192.168.1.255, is left out. The validator
      // computes it as (~mask | network) >>> 0: dart2js, which 1.x ships,
      // gives `~` 32 bits and turns .255 down, but the Dart VM these tests
      // run on gives it 64 bits, gets a negative number and lets .255
      // through. A test here could only pin the VM's wrong answer.
      expect(notifier.isDeviceIpValidate('192.168.1.1'), isFalse);
      expect(notifier.isDeviceIpValidate('192.168.1.0'), isFalse);
      expect(notifier.isDeviceIpValidate('192.168.2.150'), isFalse);
      expect(notifier.isDeviceIpValidate(''), isFalse);
    });
  });

  group('the overlap rule, against the other single ports', () {
    test('flags the same port on the same protocol', () {
      expect(notifier.isPortConflict(3074, 'TCP'), isTrue);
    });

    test('flags the same port when either side forwards both protocols', () {
      expect(notifier.isPortConflict(3074, 'Both'), isTrue);

      notifier.init([_single(protocol: 'Both')], null, null, '192.168.1.1',
          '255.255.255.0');
      expect(notifier.isPortConflict(3074, 'UDP'), isTrue);
    });

    test('lets the same port through on the other protocol', () {
      expect(notifier.isPortConflict(3074, 'UDP'), isFalse);
    });

    test('lets another port through', () {
      expect(notifier.isPortConflict(3075, 'TCP'), isFalse);
    });

    test('does not hold the rule being edited against itself', () {
      notifier.init([_single()], _single(), 0, '192.168.1.1', '255.255.255.0');

      expect(notifier.isPortConflict(3074, 'TCP'), isFalse);
    });
  });

  group('the overlap rule, against the port ranges', () {
    setUp(() => container
        .read(portRangeForwardingListProvider.notifier)
        .addRule(_range(6888, 6900, 'TCP')));

    test('flags a port inside a range on the same protocol', () {
      expect(notifier.isPortConflict(6890, 'TCP'), isTrue);
      expect(notifier.isPortConflict(6890, 'Both'), isTrue);
    });

    test('flags a port on either end of a range', () {
      // A range holds its first and last ports. That the router refuses a
      // single port on a range's end is inferred from the comment in
      // AppsAndGamingViewNotifier.save, which meets the router's overlap
      // error across the two lists; it was not checked on a router.
      expect(notifier.isPortConflict(6888, 'TCP'), isTrue);
      expect(notifier.isPortConflict(6900, 'TCP'), isTrue);
    });

    test('flags the port of a one-port range', () {
      container
          .read(portRangeForwardingListProvider.notifier)
          .addRule(_range(8080, 8080, 'TCP'));

      expect(notifier.isPortConflict(8080, 'TCP'), isTrue);
    });

    test('lets a port inside a range through on the other protocol', () {
      expect(notifier.isPortConflict(6890, 'UDP'), isFalse);
    });

    test('lets a port outside every range through', () {
      expect(notifier.isPortConflict(6887, 'TCP'), isFalse);
      expect(notifier.isPortConflict(6901, 'TCP'), isFalse);
    });
  });

  group('isRuleValid', () {
    test('has nothing to check before a rule is open', () {
      expect(notifier.isRuleValid(), isFalse);
    });

    test('accepts a named rule to a LAN device on a free port', () {
      notifier.updateRule(_single(description: 'Web', port: 8080));

      expect(notifier.isRuleValid(), isTrue);
    });

    test('turns down a rule that breaks any one rule', () {
      final broken = <String, SinglePortForwardingRule>{
        'no name': _single(description: '', port: 8080),
        'a device off the LAN': _single(port: 8080, device: '10.0.0.5'),
        'a port already forwarded': _single(description: 'Again'),
      };

      for (final MapEntry(key: reason, value: candidate) in broken.entries) {
        notifier.updateRule(candidate);
        expect(notifier.isRuleValid(), isFalse, reason: reason);
      }
    });
  });
}
