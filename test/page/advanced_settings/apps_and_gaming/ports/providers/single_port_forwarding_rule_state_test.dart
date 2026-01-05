import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_rule_state.dart';

void main() {
  group('SinglePortForwardingRuleState', () {
    const testRule = SinglePortForwardingRuleUIModel(
      isEnabled: true,
      externalPort: 8080,
      protocol: 'TCP',
      internalServerIPAddress: '192.168.1.100',
      internalPort: 8080,
      description: 'Test Rule',
    );

    test('creates instance with default values', () {
      const state = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
    });

    test('creates instance with all fields', () {
      const state = SinglePortForwardingRuleState(
        rules: [testRule],
        rule: testRule,
        editIndex: 0,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );
      expect(state.rules, hasLength(1));
      expect(state.rule, testRule);
      expect(state.editIndex, 0);
      expect(state.routerIp, '10.0.0.1');
    });

    test('copyWith updates specified fields', () {
      const original = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      final copied = original.copyWith(
        rules: [testRule],
        routerIp: '10.0.0.1',
      );
      expect(copied.rules, hasLength(1));
      expect(copied.routerIp, '10.0.0.1');
      expect(copied.subnetMask, '255.255.255.0');
    });

    test('copyWith updates rule with ValueGetter', () {
      const original = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      final copied = original.copyWith(rule: () => testRule);
      expect(copied.rule, testRule);
    });

    test('copyWith sets rule to null with ValueGetter', () {
      const original = SinglePortForwardingRuleState(
        rule: testRule,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      final copied = original.copyWith(rule: () => null);
      expect(copied.rule, isNull);
    });

    test('copyWith updates editIndex with ValueGetter', () {
      const original = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      final copied = original.copyWith(editIndex: () => 5);
      expect(copied.editIndex, 5);
    });

    test('toMap converts to map correctly', () {
      const state = SinglePortForwardingRuleState(
        rules: [testRule],
        rule: testRule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      final map = state.toMap();
      expect(map['rules'], hasLength(1));
      expect(map['rule'], isNotNull);
      expect(map['editIndex'], 0);
      expect(map['routerIp'], '192.168.1.1');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'rules': [testRule.toMap()],
        'rule': testRule.toMap(),
        'editIndex': 0,
        'routerIp': '192.168.1.1',
        'subnetMask': '255.255.255.0',
      };
      final state = SinglePortForwardingRuleState.fromMap(map);
      expect(state.rules, hasLength(1));
      expect(state.rule, isNotNull);
      expect(state.editIndex, 0);
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'rules': <Map<String, dynamic>>[],
        'rule': null,
        'editIndex': null,
        'routerIp': '192.168.1.1',
        'subnetMask': '255.255.255.0',
      };
      final state = SinglePortForwardingRuleState.fromMap(map);
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    test('toJson/fromJson round-trip works', () {
      const original = SinglePortForwardingRuleState(
        rules: [testRule],
        rule: testRule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      final json = original.toJson();
      final restored = SinglePortForwardingRuleState.fromJson(json);
      expect(restored.rules, hasLength(1));
      expect(restored.editIndex, 0);
      expect(restored.routerIp, '192.168.1.1');
    });

    test('equality comparison works', () {
      const state1 = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      const state2 = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      expect(state1, state2);
    });

    test('distinguishes different states', () {
      const state1 = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      const state2 = SinglePortForwardingRuleState(
        routerIp: '10.0.0.1',
        subnetMask: '255.255.255.0',
      );
      expect(state1, isNot(state2));
    });

    test('props returns correct list', () {
      const state = SinglePortForwardingRuleState(
        rules: [testRule],
        rule: testRule,
        editIndex: 0,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      expect(state.props, [
        state.rules,
        state.rule,
        state.editIndex,
        state.routerIp,
        state.subnetMask,
      ]);
    });

    test('stringify returns true', () {
      const state = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      expect(state.stringify, true);
    });

    test('toString contains all fields', () {
      const state = SinglePortForwardingRuleState(
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );
      final str = state.toString();
      expect(str, contains('routerIp'));
      expect(str, contains('subnetMask'));
    });
  });
}
