import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';

void main() {
  group('PortRangeForwardingRuleUIModel', () {
    test('creates instance with required parameters', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      expect(rule.isEnabled, true);
      expect(rule.firstExternalPort, 3074);
      expect(rule.protocol, 'TCP');
      expect(rule.internalServerIPAddress, '192.168.1.100');
      expect(rule.lastExternalPort, 3074);
      expect(rule.description, 'XBox Live');
    });

    test('isSinglePort returns true for single port', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Single Port',
      );

      expect(rule.isSinglePort, true);
    });

    test('isSinglePort returns false for port range', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8000,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 8100,
        description: 'Port Range',
      );

      expect(rule.isSinglePort, false);
    });

    test('portRangeDisplay shows single port correctly', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Single Port',
      );

      expect(rule.portRangeDisplay, '3074');
    });

    test('portRangeDisplay shows port range correctly', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8000,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 8100,
        description: 'Port Range',
      );

      expect(rule.portRangeDisplay, '8000-8100');
    });

    test('copyWith creates new instance with updated values', () {
      const original = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Original',
      );

      final updated = original.copyWith(
        isEnabled: false,
        description: 'Updated',
      );

      expect(updated.isEnabled, false);
      expect(updated.description, 'Updated');
      expect(updated.firstExternalPort, 3074); // unchanged
      expect(updated.protocol, 'TCP'); // unchanged
    });

    test('toMap converts to Map correctly', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      final map = rule.toMap();

      expect(map['isEnabled'], true);
      expect(map['firstExternalPort'], 3074);
      expect(map['protocol'], 'TCP');
      expect(map['internalServerIPAddress'], '192.168.1.100');
      expect(map['lastExternalPort'], 3074);
      expect(map['description'], 'XBox Live');
    });

    test('fromMap creates instance from Map', () {
      final map = {
        'isEnabled': false,
        'firstExternalPort': 8080,
        'protocol': 'UDP',
        'internalServerIPAddress': '192.168.1.200',
        'lastExternalPort': 8090,
        'description': 'Test Rule',
      };

      final rule = PortRangeForwardingRuleUIModel.fromMap(map);

      expect(rule.isEnabled, false);
      expect(rule.firstExternalPort, 8080);
      expect(rule.protocol, 'UDP');
      expect(rule.internalServerIPAddress, '192.168.1.200');
      expect(rule.lastExternalPort, 8090);
      expect(rule.description, 'Test Rule');
    });

    test('toJson and fromJson work correctly', () {
      const original = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      final json = original.toJson();
      final restored = PortRangeForwardingRuleUIModel.fromJson(json);

      expect(restored, original);
    });

    test('Equatable props work correctly', () {
      const rule1 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const rule2 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const rule3 = PortRangeForwardingRuleUIModel(
        isEnabled: false,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      expect(rule1, rule2);
      expect(rule1 == rule3, false);
    });
  });

  group('PortRangeForwardingRuleListUIModel', () {
    test('creates instance with rules', () {
      const ruleList = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'Rule 1',
          ),
        ],
      );

      expect(ruleList.rules, hasLength(1));
      expect(ruleList.rules[0].description, 'Rule 1');
    });

    test('creates empty list', () {
      const ruleList = PortRangeForwardingRuleListUIModel(
          rules: <PortRangeForwardingRuleUIModel>[]);

      expect(ruleList.rules, isEmpty);
    });

    test('copyWith creates new instance with updated rules', () {
      const original = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'Rule 1',
          ),
        ],
      );

      const updated = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 8080,
            protocol: 'UDP',
            internalServerIPAddress: '192.168.1.200',
            lastExternalPort: 8080,
            description: 'Rule 2',
          ),
        ],
      );

      final result = original.copyWith(rules: updated.rules);

      expect(result.rules, hasLength(1));
      expect(result.rules[0].description, 'Rule 2');
    });

    test('toMap converts to Map correctly', () {
      const ruleList = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'Rule 1',
          ),
        ],
      );

      final map = ruleList.toMap();

      expect(map['rules'], hasLength(1));
      expect(map['rules'][0]['description'], 'Rule 1');
    });

    test('fromMap creates instance from Map', () {
      final map = {
        'rules': [
          {
            'isEnabled': true,
            'firstExternalPort': 3074,
            'protocol': 'TCP',
            'internalServerIPAddress': '192.168.1.100',
            'lastExternalPort': 3074,
            'description': 'Rule 1',
          },
        ],
      };

      final ruleList = PortRangeForwardingRuleListUIModel.fromMap(map);

      expect(ruleList.rules, hasLength(1));
      expect(ruleList.rules[0].description, 'Rule 1');
    });

    test('toJson and fromJson work correctly', () {
      const original = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'Rule 1',
          ),
        ],
      );

      final json = original.toJson();
      final restored = PortRangeForwardingRuleListUIModel.fromJson(json);

      expect(restored, original);
    });

    test('Equatable props work correctly', () {
      const list1 = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'Rule 1',
          ),
        ],
      );

      const list2 = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'Rule 1',
          ),
        ],
      );

      const list3 = PortRangeForwardingRuleListUIModel(
          rules: <PortRangeForwardingRuleUIModel>[]);

      expect(list1, list2);
      expect(list1 == list3, false);
    });
  });
}
