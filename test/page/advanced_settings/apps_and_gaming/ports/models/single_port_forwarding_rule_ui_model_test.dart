import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';

void main() {
  group('SinglePortForwardingRuleUIModel', () {
    test('creates instance with all fields', () {
      const rule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8081,
        description: 'Web Server',
      );

      expect(rule.isEnabled, true);
      expect(rule.externalPort, 8080);
      expect(rule.protocol, 'TCP');
      expect(rule.internalServerIPAddress, '192.168.1.100');
      expect(rule.internalPort, 8081);
      expect(rule.description, 'Web Server');
    });

    test('copyWith updates specified fields', () {
      const original = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );

      final updated = original.copyWith(
        isEnabled: false,
        externalPort: 9090,
      );

      expect(updated.isEnabled, false);
      expect(updated.externalPort, 9090);
      expect(updated.protocol, 'TCP'); // unchanged
      expect(updated.internalServerIPAddress, '192.168.1.100'); // unchanged
      expect(updated.internalPort, 8080); // unchanged
      expect(updated.description, 'Test'); // unchanged
    });

    test('toMap converts to map correctly', () {
      const rule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8081,
        description: 'Web Server',
      );

      final map = rule.toMap();

      expect(map['isEnabled'], true);
      expect(map['externalPort'], 8080);
      expect(map['protocol'], 'TCP');
      expect(map['internalServerIPAddress'], '192.168.1.100');
      expect(map['internalPort'], 8081);
      expect(map['description'], 'Web Server');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'isEnabled': false,
        'externalPort': 3000,
        'protocol': 'UDP',
        'internalServerIPAddress': '192.168.1.50',
        'internalPort': 3001,
        'description': 'Game Server',
      };

      final rule = SinglePortForwardingRuleUIModel.fromMap(map);

      expect(rule.isEnabled, false);
      expect(rule.externalPort, 3000);
      expect(rule.protocol, 'UDP');
      expect(rule.internalServerIPAddress, '192.168.1.50');
      expect(rule.internalPort, 3001);
      expect(rule.description, 'Game Server');
    });

    test('toJson/fromJson serialization works correctly', () {
      const original = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );

      final json = original.toJson();
      final restored = SinglePortForwardingRuleUIModel.fromJson(json);

      expect(restored, original);
    });

    test('equality comparison works correctly', () {
      const rule1 = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );
      const rule2 = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );
      const rule3 = SinglePortForwardingRuleUIModel(
        isEnabled: false,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );

      expect(rule1, rule2);
      expect(rule1, isNot(rule3));
    });
  });

  group('SinglePortForwardingRuleListUIModel', () {
    test('creates instance with rules', () {
      const rule1 = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Rule 1',
      );
      const rule2 = SinglePortForwardingRuleUIModel(
        isEnabled: false,
        externalPort: 9090,
        protocol: 'UDP',
        internalServerIPAddress: '192.168.1.101',
        internalPort: 9090,
        description: 'Rule 2',
      );

      const ruleList = SinglePortForwardingRuleListUIModel(rules: [rule1, rule2]);

      expect(ruleList.rules, hasLength(2));
      expect(ruleList.rules.first, rule1);
      expect(ruleList.rules.last, rule2);
    });

    test('creates instance with empty rules', () {
      const ruleList = SinglePortForwardingRuleListUIModel(rules: []);

      expect(ruleList.rules, isEmpty);
    });

    test('copyWith updates rules', () {
      const original = SinglePortForwardingRuleListUIModel(rules: []);
      const newRule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'New Rule',
      );

      final updated = original.copyWith(rules: [newRule]);

      expect(updated.rules, hasLength(1));
      expect(updated.rules.first, newRule);
    });

    test('toMap converts to map correctly', () {
      const rule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );
      const ruleList = SinglePortForwardingRuleListUIModel(rules: [rule]);

      final map = ruleList.toMap();

      expect(map['rules'], isA<List>());
      expect(map['rules'], hasLength(1));
      expect(map['rules'][0]['externalPort'], 8080);
    });

    test('fromMap creates instance from map', () {
      final map = {
        'rules': [
          {
            'isEnabled': true,
            'externalPort': 8080,
            'protocol': 'TCP',
            'internalServerIPAddress': '192.168.1.100',
            'internalPort': 8080,
            'description': 'Test',
          }
        ]
      };

      final ruleList = SinglePortForwardingRuleListUIModel.fromMap(map);

      expect(ruleList.rules, hasLength(1));
      expect(ruleList.rules.first.externalPort, 8080);
    });

    test('toJson/fromJson serialization works correctly', () {
      const rule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );
      const original = SinglePortForwardingRuleListUIModel(rules: [rule]);

      final json = original.toJson();
      final restored = SinglePortForwardingRuleListUIModel.fromJson(json);

      expect(restored, original);
      expect(restored.rules.first.externalPort, 8080);
    });

    test('equality comparison works correctly', () {
      const rule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );

      const list1 = SinglePortForwardingRuleListUIModel(rules: [rule]);
      const list2 = SinglePortForwardingRuleListUIModel(rules: [rule]);
      const list3 = SinglePortForwardingRuleListUIModel(rules: []);

      expect(list1, list2);
      expect(list1, isNot(list3));
    });
  });
}