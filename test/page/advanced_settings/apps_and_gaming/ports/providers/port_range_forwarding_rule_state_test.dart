import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_rule_state.dart';

void main() {
  group('PortRangeForwardingRuleState', () {
    test('creates instance with required parameters', () {
      const state = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    test('creates instance with all parameters', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );
      const rules = [rule];
      const state = PortRangeForwardingRuleState(
        rules: rules,
        rule: rule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state.rules, rules);
      expect(state.rule, rule);
      expect(state.editIndex, 0);
      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
    });

    test('creates instance with default empty rules', () {
      const state = PortRangeForwardingRuleState(
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      expect(state.rules, isEmpty);
    });

    test('Equatable props includes all fields', () {
      const rule1 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Rule 1',
      );
      const rule2 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8080,
        protocol: 'UDP',
        internalServerIPAddress: '192.168.1.200',
        lastExternalPort: 8080,
        description: 'Rule 2',
      );

      const state1 = PortRangeForwardingRuleState(
        rules: [rule1],
        rule: rule1,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const state2 = PortRangeForwardingRuleState(
        rules: [rule1],
        rule: rule1,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const state3 = PortRangeForwardingRuleState(
        rules: [rule2],
        rule: rule1,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state1, state2);
      expect(state1 == state3, false);
    });

    test('Equatable detects difference in routerIp', () {
      const state1 = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const state2 = PortRangeForwardingRuleState(
        routerIp: '10.0.0.1',
        subnetMask: '255.255.255.0',
      );

      expect(state1 == state2, false);
    });

    test('Equatable detects difference in subnetMask', () {
      const state1 = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const state2 = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.0.0',
      );

      expect(state1 == state2, false);
    });

    test('Equatable detects difference in editIndex', () {
      const state1 = PortRangeForwardingRuleState(
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const state2 = PortRangeForwardingRuleState(
        editIndex: 1,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state1 == state2, false);
    });

    test('Equatable detects difference in rule (null vs non-null)', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const state1 = PortRangeForwardingRuleState(
        rule: rule,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const state2 = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(state1 == state2, false);
    });
  });

  group('PortRangeForwardingRuleState - copyWith', () {
    test('copyWith creates new instance with updated rules', () {
      const original = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'New Rule',
      );

      final updated = original.copyWith(rules: [newRule]);

      expect(updated.rules, [newRule]);
      expect(updated.routerIp, '192.168.1.1');
      expect(updated.subnetMask, '255.255.255.0');
      expect(updated.rule, isNull);
      expect(updated.editIndex, isNull);
    });

    test('copyWith updates rule using ValueGetter', () {
      const original = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'New Rule',
      );

      final updated = original.copyWith(rule: () => newRule);

      expect(updated.rule, newRule);
    });

    test('copyWith can set rule to null using ValueGetter', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Existing Rule',
      );

      const original = PortRangeForwardingRuleState(
        rule: rule,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(rule: () => null);

      expect(updated.rule, isNull);
    });

    test('copyWith updates editIndex using ValueGetter', () {
      const original = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(editIndex: () => 5);

      expect(updated.editIndex, 5);
    });

    test('copyWith can set editIndex to null using ValueGetter', () {
      const original = PortRangeForwardingRuleState(
        editIndex: 3,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(editIndex: () => null);

      expect(updated.editIndex, isNull);
    });

    test('copyWith updates routerIp', () {
      const original = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(routerIp: '10.0.0.1');

      expect(updated.routerIp, '10.0.0.1');
      expect(updated.subnetMask, '255.255.255.0');
    });

    test('copyWith updates subnetMask', () {
      const original = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(subnetMask: '255.255.0.0');

      expect(updated.routerIp, '192.168.1.1');
      expect(updated.subnetMask, '255.255.0.0');
    });

    test('copyWith updates multiple fields at once', () {
      const original = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'New Rule',
      );

      final updated = original.copyWith(
        rules: [newRule],
        rule: () => newRule,
        editIndex: () => 0,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      expect(updated.rules, [newRule]);
      expect(updated.rule, newRule);
      expect(updated.editIndex, 0);
      expect(updated.routerIp, '10.0.0.1');
      expect(updated.subnetMask, '255.255.0.0');
    });

    test('copyWith preserves unchanged fields', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Existing Rule',
      );

      const original = PortRangeForwardingRuleState(
        rules: [rule],
        rule: rule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(routerIp: '10.0.0.1');

      expect(updated.rules, original.rules);
      expect(updated.rule, original.rule);
      expect(updated.editIndex, original.editIndex);
      expect(updated.routerIp, '10.0.0.1');
      expect(updated.subnetMask, original.subnetMask);
    });
  });

  group('PortRangeForwardingRuleState - Serialization', () {
    test('toMap converts state to Map correctly', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const state = PortRangeForwardingRuleState(
        rules: [rule],
        rule: rule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final map = state.toMap();

      expect(map['rules'], hasLength(1));
      expect(map['rule'], isA<Map<String, dynamic>>());
      expect(map['editIndex'], 0);
      expect(map['routerIp'], '192.168.1.1');
      expect(map['subnetMask'], '255.255.255.0');
    });

    test('toMap handles null rule', () {
      const state = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final map = state.toMap();

      expect(map['rule'], isNull);
      expect(map['editIndex'], isNull);
    });

    test('toMap handles empty rules list', () {
      const state = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final map = state.toMap();

      expect(map['rules'], isEmpty);
    });

    test('fromMap creates state from Map correctly', () {
      final map = {
        'rules': [
          {
            'isEnabled': true,
            'firstExternalPort': 3074,
            'protocol': 'TCP',
            'internalServerIPAddress': '192.168.1.100',
            'lastExternalPort': 3074,
            'description': 'XBox Live',
          },
        ],
        'rule': {
          'isEnabled': true,
          'firstExternalPort': 3074,
          'protocol': 'TCP',
          'internalServerIPAddress': '192.168.1.100',
          'lastExternalPort': 3074,
          'description': 'XBox Live',
        },
        'editIndex': 0,
        'routerIp': '192.168.1.1',
        'subnetMask': '255.255.255.0',
      };

      final state = PortRangeForwardingRuleState.fromMap(map);

      expect(state.rules, hasLength(1));
      expect(state.rule?.description, 'XBox Live');
      expect(state.editIndex, 0);
      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
    });

    test('fromMap handles null rule', () {
      final map = {
        'rules': [],
        'rule': null,
        'editIndex': null,
        'routerIp': '192.168.1.1',
        'subnetMask': '255.255.255.0',
      };

      final state = PortRangeForwardingRuleState.fromMap(map);

      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    test('fromMap handles missing routerIp with default value', () {
      final map = {
        'rules': [],
      };

      final state = PortRangeForwardingRuleState.fromMap(map);

      expect(state.routerIp, '');
      expect(state.subnetMask, '');
    });

    test('toJson and fromJson work correctly', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const original = PortRangeForwardingRuleState(
        rules: [rule],
        rule: rule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final json = original.toJson();
      final restored = PortRangeForwardingRuleState.fromJson(json);

      expect(restored, original);
    });

    test('toJson and fromJson handle null values', () {
      const original = PortRangeForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final json = original.toJson();
      final restored = PortRangeForwardingRuleState.fromJson(json);

      expect(restored.rule, isNull);
      expect(restored.editIndex, isNull);
      expect(restored.routerIp, original.routerIp);
    });
  });

  group('PortRangeForwardingRuleState - toString', () {
    test('toString includes all fields', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const state = PortRangeForwardingRuleState(
        rules: [rule],
        rule: rule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final string = state.toString();

      expect(string, contains('PortRangeForwardingRuleState'));
      expect(string, contains('rules:'));
      expect(string, contains('rule:'));
      expect(string, contains('editIndex: 0'));
      expect(string, contains('routerIp: 192.168.1.1'));
      expect(string, contains('subnetMask: 255.255.255.0'));
    });
  });
}