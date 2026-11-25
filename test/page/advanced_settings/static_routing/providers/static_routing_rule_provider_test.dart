import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';

NamedStaticRouteEntry _route({
  String name = 'Lab',
  String destination = '192.168.50.0',
  int prefixLength = 24,
  String? gateway = '192.168.1.254',
  String interface = 'LAN',
}) =>
    NamedStaticRouteEntry(
      name: name,
      settings: StaticRouteEntry(
        destinationLAN: destination,
        gateway: gateway,
        interface: interface,
        networkPrefixLength: prefixLength,
      ),
    );

void main() {
  late ProviderContainer container;
  late StaticRoutingRuleNotifier notifier;

  StaticRoutingRuleState rule() => container.read(staticRoutingRuleProvider);

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(staticRoutingRuleProvider.notifier);
    // The router is 192.168.1.1/24.
    notifier.init(const [], null, null, '192.168.1.1', '255.255.255.0');
  });

  tearDown(() => container.dispose());

  test('init holds the list, the route being edited and the LAN', () {
    final routes = [_route()];

    notifier.init(routes, routes.first, 0, '10.0.0.1', '255.255.0.0');

    expect(
        rule(),
        StaticRoutingRuleState(
          rules: routes,
          rule: routes.first,
          editIndex: 0,
          routerIp: '10.0.0.1',
          subnetMask: '255.255.0.0',
        ));
  });

  group('the name rule', () {
    test('needs a name', () {
      expect(notifier.isNameValid(''), isFalse);
      expect(notifier.isNameValid('Lab'), isTrue);
    });
  });

  group('the subnet mask rule', () {
    test('takes prefix lengths from 8 to 30', () {
      expect(notifier.isValidSubnetMask(8), isTrue);
      expect(notifier.isValidSubnetMask(24), isTrue);
      expect(notifier.isValidSubnetMask(30), isTrue);
    });
  });

  group('the gateway rule', () {
    test('on the LAN: takes a host of the router network', () {
      expect(notifier.isValidIpAddress('192.168.1.254', true), isTrue);
    });

    test('on the LAN: turns down the router, other networks and junk', () {
      expect(notifier.isValidIpAddress('192.168.1.1', true), isFalse);
      expect(notifier.isValidIpAddress('192.168.2.254', true), isFalse);
      expect(notifier.isValidIpAddress('192.168.1', true), isFalse);
    });

    test('on the internet: takes an address outside the router network', () {
      expect(notifier.isValidIpAddress('203.0.113.1'), isTrue);
    });

    test('on the internet: turns down a LAN host and reserved addresses', () {
      expect(notifier.isValidIpAddress('192.168.1.254'), isFalse);
      expect(notifier.isValidIpAddress('127.0.0.1'), isFalse);
      expect(notifier.isValidIpAddress('224.0.0.1'), isFalse);
    });
  });

  group('isRuleValid', () {
    test('has nothing to check before a route is open', () {
      expect(notifier.isRuleValid(), isFalse);
    });

    test('accepts a LAN route and an internet route', () {
      notifier.updateRule(_route());
      expect(notifier.isRuleValid(), isTrue);

      notifier.updateRule(_route(
          interface: 'Internet',
          destination: '10.20.0.0',
          prefixLength: 16,
          gateway: '203.0.113.1'));
      expect(notifier.isRuleValid(), isTrue);
    });

    test('turns down a route that breaks any one rule', () {
      final broken = <String, NamedStaticRouteEntry>{
        'no name': _route(name: ''),
        'a malformed destination': _route(destination: '192.168.50'),
        'a reserved destination': _route(destination: '127.0.0.0'),
        'a LAN gateway off the LAN': _route(gateway: '10.0.0.1'),
        'no gateway': _route(gateway: null),
        'an internet gateway on the LAN':
            _route(interface: 'Internet', gateway: '192.168.1.254'),
      };

      for (final MapEntry(key: reason, value: candidate) in broken.entries) {
        notifier.updateRule(candidate);
        expect(notifier.isRuleValid(), isFalse, reason: reason);
      }
    });
  });
}
