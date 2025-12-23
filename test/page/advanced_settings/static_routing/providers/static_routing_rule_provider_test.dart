import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_routing_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';

void main() {
  group('StaticRoutingRuleNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('builds with default initial state', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);
      final state = container.read(staticRoutingRuleProvider);

      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
      expect(state.rule, isNull);
      expect(state.rules, isEmpty);
    });

    test('init sets rules, rule, index, and network context', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      const rule = StaticRoutingRuleUIModel(
        name: 'Test Route',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      const rules = [rule];

      notifier.init(
        rules,
        rule,
        0,
        '10.0.0.1',
        '255.255.0.0',
      );

      final state = container.read(staticRoutingRuleProvider);

      expect(state.rule, rule);
      expect(state.rules, rules);
      expect(state.editIndex, 0);
      expect(state.routerIp, '10.0.0.1');
      expect(state.subnetMask, '255.255.0.0');
    });

    test('updateRule modifies current rule', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      const originalRule = StaticRoutingRuleUIModel(
        name: 'Original',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      notifier.init([originalRule], originalRule, 0, '192.168.1.1', '255.255.255.0');

      const updatedRule = StaticRoutingRuleUIModel(
        name: 'Updated',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      notifier.updateRule(updatedRule);

      final state = container.read(staticRoutingRuleProvider);
      expect(state.rule?.name, 'Updated');
    });

    test('updateRule to null clears current rule', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      const rule = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      notifier.init([rule], rule, 0, '192.168.1.1', '255.255.255.0');
      notifier.updateRule(null);

      final state = container.read(staticRoutingRuleProvider);
      expect(state.rule, isNull);
    });

    test('isNameValid validates route name', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      expect(notifier.isNameValid('Valid Name'), isTrue);
      expect(notifier.isNameValid(''), isFalse);
    });

    test('isValidSubnetMask accepts valid prefix lengths', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      // Valid prefix lengths (8-30 per NetworkUtils constraints)
      expect(notifier.isValidSubnetMask(8), isTrue);
      expect(notifier.isValidSubnetMask(16), isTrue);
      expect(notifier.isValidSubnetMask(24), isTrue);
      expect(notifier.isValidSubnetMask(30), isTrue);
    });

    test('isValidIpAddress validates IP addresses', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      notifier.init(
        [],
        null,
        null,
        '192.168.1.1',
        '255.255.255.0',
      );

      // Valid IPs
      expect(notifier.isValidIpAddress('8.8.8.8'), isTrue);
      expect(notifier.isValidIpAddress('10.0.0.1'), isTrue);

      // Invalid IPs
      expect(notifier.isValidIpAddress('256.256.256.256'), isFalse);
      expect(notifier.isValidIpAddress('invalid'), isFalse);
      expect(notifier.isValidIpAddress(''), isFalse);
    });

    test('isValidIpAddress localIPOnly validates local network', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      notifier.init(
        [],
        null,
        null,
        '192.168.1.1',
        '255.255.255.0',
      );

      // Valid local IPs (same subnet)
      expect(notifier.isValidIpAddress('192.168.1.100', true), isTrue);
      expect(notifier.isValidIpAddress('192.168.1.254', true), isTrue);

      // Invalid local IPs (different subnet)
      expect(notifier.isValidIpAddress('10.0.0.1', true), isFalse);
      expect(notifier.isValidIpAddress('8.8.8.8', true), isFalse);
    });

    test('isRuleValid validates complete rule', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      // Valid rule - use a local destination IP with interface='LAN'
      const validRule = StaticRoutingRuleUIModel(
        name: 'Valid Route',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.254',
        interface: 'LAN',
      );

      notifier.init(
        [validRule],
        validRule,
        0,
        '192.168.1.1',
        '255.255.255.0',
      );

      expect(notifier.isRuleValid(), isTrue);
    });

    test('isRuleValid rejects rule with empty name', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      const invalidRule = StaticRoutingRuleUIModel(
        name: '',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      notifier.init(
        [invalidRule],
        invalidRule,
        0,
        '192.168.1.1',
        '255.255.255.0',
      );

      expect(notifier.isRuleValid(), isFalse);
    });

    test('isRuleValid rejects rule with invalid destination IP', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      const invalidRule = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: 'invalid',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      notifier.init(
        [invalidRule],
        invalidRule,
        0,
        '192.168.1.1',
        '255.255.255.0',
      );

      expect(notifier.isRuleValid(), isFalse);
    });

    test('isRuleValid rejects null rule', () {
      final notifier = container.read(staticRoutingRuleProvider.notifier);

      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');

      expect(notifier.isRuleValid(), isFalse);
    });
  });
}
