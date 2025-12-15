import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';

void main() {
  group('StaticRoutingRuleUIModel', () {
    test('creates instance with required fields', () {
      const model = StaticRoutingRuleUIModel(
        name: 'Test Route',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      expect(model.name, 'Test Route');
      expect(model.destinationIP, '192.168.100.0');
      expect(model.networkPrefixLength, 24);
      expect(model.gateway, '192.168.1.1');
      expect(model.interface, 'LAN');
    });

    test('creates instance with nullable gateway', () {
      const model = StaticRoutingRuleUIModel(
        name: 'Test Route',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      expect(model.gateway, isNull);
    });

    test('props includes all fields for equality', () {
      const model1 = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      const model2 = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      expect(model1, model2);
    });

    test('copyWith creates new instance with overrides', () {
      const original = StaticRoutingRuleUIModel(
        name: 'Original',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      final updated = original.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.destinationIP, '192.168.100.0');
      expect(original.name, 'Original'); // Original unchanged
    });

    test('toMap converts to map representation', () {
      const model = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      final map = model.toMap();

      expect(map['name'], 'Test');
      expect(map['destinationIP'], '192.168.100.0');
      expect(map['networkPrefixLength'], 24);
      expect(map['gateway'], '192.168.1.1');
      expect(map['interface'], 'LAN');
    });

    test('fromMap constructs instance from map', () {
      final map = {
        'name': 'Test',
        'destinationIP': '192.168.100.0',
        'networkPrefixLength': 24,
        'gateway': '192.168.1.1',
        'interface': 'LAN',
      };

      final model = StaticRoutingRuleUIModel.fromMap(map);

      expect(model.name, 'Test');
      expect(model.destinationIP, '192.168.100.0');
      expect(model.networkPrefixLength, 24);
      expect(model.gateway, '192.168.1.1');
      expect(model.interface, 'LAN');
    });

    test('toJson and fromJson round-trip preserves data', () {
      const original = StaticRoutingRuleUIModel(
        name: 'Test Route',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      final json = original.toJson();
      final restored = StaticRoutingRuleUIModel.fromJson(json);

      expect(restored, original);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = {
        'name': 'Test',
      };

      final model = StaticRoutingRuleUIModel.fromMap(map);

      expect(model.name, 'Test');
      expect(model.destinationIP, ''); // Default
      expect(model.networkPrefixLength, 24); // Default
      expect(model.gateway, isNull); // Default
      expect(model.interface, 'LAN'); // Default
    });
  });

  group('StaticRoutingRuleState', () {
    test('creates instance with required fields', () {
      const state = StaticRoutingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    test('copyWith creates new instance with overrides', () {
      const original = StaticRoutingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(
        routerIp: '10.0.0.1',
      );

      expect(updated.routerIp, '10.0.0.1');
      expect(updated.subnetMask, '255.255.255.0');
      expect(original.routerIp, '192.168.1.1'); // Original unchanged
    });

    test('copyWith with ValueGetter for nullable fields', () {
      const rule = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      const original = StaticRoutingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(
        rule: () => rule,
        editIndex: () => 0,
      );

      expect(updated.rule, rule);
      expect(updated.editIndex, 0);
    });

    test('toMap returns correct map representation', () {
      const rule = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '192.168.100.0',
        networkPrefixLength: 24,
        interface: 'LAN',
      );

      const state = StaticRoutingRuleState(
        rules: [rule],
        rule: rule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final map = state.toMap();

      expect(map['routerIp'], '192.168.1.1');
      expect(map['subnetMask'], '255.255.255.0');
      expect(map['rules'], isNotEmpty);
      expect(map['editIndex'], 0);
    });

    test('fromMap constructs instance from map', () {
      final map = {
        'routerIp': '192.168.1.1',
        'subnetMask': '255.255.255.0',
        'rules': [],
        'editIndex': null,
      };

      final state = StaticRoutingRuleState.fromMap(map);

      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
      expect(state.rules, isEmpty);
    });

    test('toJson and fromJson round-trip preserves data', () {
      const original = StaticRoutingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final json = original.toJson();
      final restored = StaticRoutingRuleState.fromJson(json);

      expect(restored.routerIp, original.routerIp);
      expect(restored.subnetMask, original.subnetMask);
    });

    test('stringify returns string representation', () {
      const state = StaticRoutingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state.stringify, isTrue);
      expect(state.toString(), contains('StaticRoutingRuleState'));
    });

    test('equality comparison works correctly', () {
      const state1 = StaticRoutingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const state2 = StaticRoutingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state1, state2);
    });
  });
}
