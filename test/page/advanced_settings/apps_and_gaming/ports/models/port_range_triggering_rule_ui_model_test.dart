import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';

void main() {
  group('PortRangeTriggeringRuleUIModel', () {
    test('creates instance with all required fields', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      expect(rule.isEnabled, true);
      expect(rule.firstTriggerPort, 3074);
      expect(rule.lastTriggerPort, 3074);
      expect(rule.firstForwardedPort, 3075);
      expect(rule.lastForwardedPort, 3075);
      expect(rule.description, 'XBox Live');
    });

    test('two instances with same data are equal', () {
      const rule1 = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      const rule2 = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      expect(rule1, equals(rule2));
      expect(rule1.hashCode, equals(rule2.hashCode));
    });

    test('two instances with different data are not equal', () {
      const rule1 = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      const rule2 = PortRangeTriggeringRuleUIModel(
        isEnabled: false,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      expect(rule1, isNot(equals(rule2)));
    });

    test('copyWith creates new instance with updated fields', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      final updated = rule.copyWith(
        isEnabled: false,
        description: 'Updated Rule',
      );

      expect(updated.isEnabled, false);
      expect(updated.firstTriggerPort, 3074);
      expect(updated.lastTriggerPort, 3074);
      expect(updated.firstForwardedPort, 3075);
      expect(updated.lastForwardedPort, 3075);
      expect(updated.description, 'Updated Rule');
    });

    test('copyWith without arguments returns equal instance', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      final copied = rule.copyWith();

      expect(copied, equals(rule));
    });

    test('toMap converts to map correctly', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      final map = rule.toMap();

      expect(map['isEnabled'], true);
      expect(map['firstTriggerPort'], 3074);
      expect(map['lastTriggerPort'], 3074);
      expect(map['firstForwardedPort'], 3075);
      expect(map['lastForwardedPort'], 3075);
      expect(map['description'], 'XBox Live');
    });

    test('fromMap creates instance from map correctly', () {
      final map = {
        'isEnabled': true,
        'firstTriggerPort': 3074,
        'lastTriggerPort': 3074,
        'firstForwardedPort': 3075,
        'lastForwardedPort': 3075,
        'description': 'XBox Live',
      };

      final rule = PortRangeTriggeringRuleUIModel.fromMap(map);

      expect(rule.isEnabled, true);
      expect(rule.firstTriggerPort, 3074);
      expect(rule.lastTriggerPort, 3074);
      expect(rule.firstForwardedPort, 3075);
      expect(rule.lastForwardedPort, 3075);
      expect(rule.description, 'XBox Live');
    });

    test('toJson converts to JSON string correctly', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'XBox Live',
      );

      final json = rule.toJson();
      final decoded = jsonDecode(json);

      expect(decoded['isEnabled'], true);
      expect(decoded['firstTriggerPort'], 3074);
      expect(decoded['description'], 'XBox Live');
    });

    test('fromJson creates instance from JSON string correctly', () {
      const jsonString = '''
      {
        "isEnabled": true,
        "firstTriggerPort": 3074,
        "lastTriggerPort": 3074,
        "firstForwardedPort": 3075,
        "lastForwardedPort": 3075,
        "description": "XBox Live"
      }
      ''';

      final rule = PortRangeTriggeringRuleUIModel.fromJson(jsonString);

      expect(rule.isEnabled, true);
      expect(rule.firstTriggerPort, 3074);
      expect(rule.description, 'XBox Live');
    });

    test('isSingleTriggerPort returns true for single port', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Single Port',
      );

      expect(rule.isSingleTriggerPort, true);
    });

    test('isSingleTriggerPort returns false for port range', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 6000,
        lastTriggerPort: 6100,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Port Range',
      );

      expect(rule.isSingleTriggerPort, false);
    });

    test('isSingleForwardedPort returns true for single port', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Single Port',
      );

      expect(rule.isSingleForwardedPort, true);
    });

    test('isSingleForwardedPort returns false for port range', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 7000,
        lastForwardedPort: 7100,
        description: 'Port Range',
      );

      expect(rule.isSingleForwardedPort, false);
    });

    test('triggerPortDisplay formats single port correctly', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Single Port',
      );

      expect(rule.triggerPortDisplay, '3074');
    });

    test('triggerPortDisplay formats port range correctly', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 6000,
        lastTriggerPort: 6100,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Port Range',
      );

      expect(rule.triggerPortDisplay, '6000-6100');
    });

    test('forwardedPortDisplay formats single port correctly', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Single Port',
      );

      expect(rule.forwardedPortDisplay, '3075');
    });

    test('forwardedPortDisplay formats port range correctly', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 7000,
        lastForwardedPort: 7100,
        description: 'Port Range',
      );

      expect(rule.forwardedPortDisplay, '7000-7100');
    });
  });

  group('PortRangeTriggeringRuleListUIModel', () {
    test('creates instance with empty list', () {
      const listModel = PortRangeTriggeringRuleListUIModel(rules: []);

      expect(listModel.rules, isEmpty);
    });

    test('creates instance with rules', () {
      const listModel = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Rule 1',
          ),
          PortRangeTriggeringRuleUIModel(
            isEnabled: false,
            firstTriggerPort: 6000,
            lastTriggerPort: 6100,
            firstForwardedPort: 7000,
            lastForwardedPort: 7100,
            description: 'Rule 2',
          ),
        ],
      );

      expect(listModel.rules, hasLength(2));
      expect(listModel.rules[0].description, 'Rule 1');
      expect(listModel.rules[1].description, 'Rule 2');
    });

    test('two instances with same rules are equal', () {
      const listModel1 = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Rule 1',
          ),
        ],
      );

      const listModel2 = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Rule 1',
          ),
        ],
      );

      expect(listModel1, equals(listModel2));
    });

    test('copyWith creates new instance with updated rules', () {
      const listModel = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Rule 1',
          ),
        ],
      );

      final updated = listModel.copyWith(
        rules: const [
          PortRangeTriggeringRuleUIModel(
            isEnabled: false,
            firstTriggerPort: 6000,
            lastTriggerPort: 6100,
            firstForwardedPort: 7000,
            lastForwardedPort: 7100,
            description: 'Rule 2',
          ),
        ],
      );

      expect(updated.rules, hasLength(1));
      expect(updated.rules[0].description, 'Rule 2');
    });

    test('toMap converts to map correctly', () {
      const listModel = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Rule 1',
          ),
        ],
      );

      final map = listModel.toMap();

      expect(map['rules'], isA<List>());
      expect((map['rules'] as List), hasLength(1));
      expect((map['rules'] as List)[0]['description'], 'Rule 1');
    });

    test('fromMap creates instance from map correctly', () {
      final map = {
        'rules': [
          {
            'isEnabled': true,
            'firstTriggerPort': 3074,
            'lastTriggerPort': 3074,
            'firstForwardedPort': 3075,
            'lastForwardedPort': 3075,
            'description': 'Rule 1',
          },
        ],
      };

      final listModel = PortRangeTriggeringRuleListUIModel.fromMap(map);

      expect(listModel.rules, hasLength(1));
      expect(listModel.rules[0].description, 'Rule 1');
    });

    test('fromMap handles empty rules list', () {
      final map = {
        'rules': [],
      };

      final listModel = PortRangeTriggeringRuleListUIModel.fromMap(map);

      expect(listModel.rules, isEmpty);
    });

    test('toJson converts to JSON string correctly', () {
      const listModel = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Rule 1',
          ),
        ],
      );

      final json = listModel.toJson();
      final decoded = jsonDecode(json);

      expect(decoded['rules'], isA<List>());
      expect((decoded['rules'] as List), hasLength(1));
    });

    test('fromJson creates instance from JSON string correctly', () {
      const jsonString = '''
      {
        "rules": [
          {
            "isEnabled": true,
            "firstTriggerPort": 3074,
            "lastTriggerPort": 3074,
            "firstForwardedPort": 3075,
            "lastForwardedPort": 3075,
            "description": "Rule 1"
          }
        ]
      }
      ''';

      final listModel = PortRangeTriggeringRuleListUIModel.fromJson(jsonString);

      expect(listModel.rules, hasLength(1));
      expect(listModel.rules[0].description, 'Rule 1');
    });
  });
}