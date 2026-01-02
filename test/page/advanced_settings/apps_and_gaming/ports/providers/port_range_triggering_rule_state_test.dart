import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_rule_state.dart';

void main() {
  group('PortRangeTriggeringRuleState', () {
    group('creation and defaults', () {
      test('creates state with default values', () {
        const state = PortRangeTriggeringRuleState();

        expect(state.rules, isEmpty);
        expect(state.rule, isNull);
        expect(state.editIndex, isNull);
      });

      test('creates state with all fields', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const state = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        expect(state.rules, hasLength(1));
        expect(state.rule, rule);
        expect(state.editIndex, 0);
      });
    });

    group('copyWith', () {
      test('copies with rules override', () {
        const rule1 = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Rule 1',
        );
        const rule2 = PortRangeTriggeringRuleUIModel(
          isEnabled: false,
          firstTriggerPort: 4000,
          lastTriggerPort: 4000,
          firstForwardedPort: 4100,
          lastForwardedPort: 4100,
          description: 'Rule 2',
        );
        const originalState = PortRangeTriggeringRuleState(
          rules: [rule1],
          rule: rule1,
          editIndex: 0,
        );

        final newState = originalState.copyWith(rules: [rule1, rule2]);

        expect(newState.rules, hasLength(2));
        expect(newState.rule, rule1); // unchanged
        expect(newState.editIndex, 0); // unchanged
      });

      test('copies with rule override using ValueGetter', () {
        const rule1 = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Rule 1',
        );
        const rule2 = PortRangeTriggeringRuleUIModel(
          isEnabled: false,
          firstTriggerPort: 4000,
          lastTriggerPort: 4000,
          firstForwardedPort: 4100,
          lastForwardedPort: 4100,
          description: 'Rule 2',
        );
        const originalState = PortRangeTriggeringRuleState(
          rules: [rule1, rule2],
          rule: rule1,
          editIndex: 0,
        );

        final newState = originalState.copyWith(rule: () => rule2);

        expect(newState.rule, rule2);
        expect(newState.rules, originalState.rules); // unchanged
      });

      test('copies with null rule using ValueGetter', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const originalState = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final newState = originalState.copyWith(rule: () => null);

        expect(newState.rule, isNull);
      });

      test('copies with editIndex override using ValueGetter', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const originalState = PortRangeTriggeringRuleState(
          rules: [rule, rule],
          rule: rule,
          editIndex: 0,
        );

        final newState = originalState.copyWith(editIndex: () => 1);

        expect(newState.editIndex, 1);
        expect(newState.rule, rule); // unchanged
      });

      test('copies with null editIndex using ValueGetter', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const originalState = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final newState = originalState.copyWith(editIndex: () => null);

        expect(newState.editIndex, isNull);
      });
    });

    group('serialization', () {
      test('toMap converts to map correctly', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const state = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final map = state.toMap();

        expect(map['rules'], isA<List>());
        expect(map['rules'], hasLength(1));
        expect(map['rule'], isA<Map>());
        expect(map['editIndex'], 0);
      });

      test('toMap handles null rule and editIndex', () {
        const state = PortRangeTriggeringRuleState(
          rules: [],
          rule: null,
          editIndex: null,
        );

        final map = state.toMap();

        expect(map['rules'], isEmpty);
        expect(map['rule'], isNull);
        expect(map['editIndex'], isNull);
      });

      test('fromMap creates instance from map', () {
        final map = {
          'rules': [
            {
              'isEnabled': true,
              'firstTriggerPort': 3074,
              'lastTriggerPort': 3074,
              'firstForwardedPort': 3075,
              'lastForwardedPort': 3075,
              'description': 'Test',
            }
          ],
          'rule': {
            'isEnabled': true,
            'firstTriggerPort': 3074,
            'lastTriggerPort': 3074,
            'firstForwardedPort': 3075,
            'lastForwardedPort': 3075,
            'description': 'Test',
          },
          'editIndex': 0,
        };

        final state = PortRangeTriggeringRuleState.fromMap(map);

        expect(state.rules, hasLength(1));
        expect(state.rules.first.description, 'Test');
        expect(state.rule?.description, 'Test');
        expect(state.editIndex, 0);
      });

      test('fromMap handles null rule and editIndex', () {
        final map = {
          'rules': <Map<String, dynamic>>[],
          'rule': null,
          'editIndex': null,
        };

        final state = PortRangeTriggeringRuleState.fromMap(map);

        expect(state.rules, isEmpty);
        expect(state.rule, isNull);
        expect(state.editIndex, isNull);
      });

      test('round-trip serialization preserves data', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const original = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final map = original.toMap();
        final restored = PortRangeTriggeringRuleState.fromMap(map);

        expect(restored.rules, original.rules);
        expect(restored.rule, original.rule);
        expect(restored.editIndex, original.editIndex);
      });

      test('toJson/fromJson serialization works correctly', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const original = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final json = original.toJson();
        final restored = PortRangeTriggeringRuleState.fromJson(json);

        expect(restored.rules.first.description, 'Test');
        expect(restored.rule?.description, 'Test');
        expect(restored.editIndex, 0);
      });
    });

    group('equality', () {
      test('supports value equality', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const state1 = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );
        const state2 = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        expect(state1, state2);
      });

      test('distinguishes different states', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const state1 = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );
        const state2 = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 1,
        );

        expect(state1, isNot(state2));
      });
    });

    group('props and stringify', () {
      test('props returns correct list', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const state = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        expect(state.props, [state.rules, state.rule, state.editIndex]);
      });

      test('stringify returns true', () {
        const state = PortRangeTriggeringRuleState();

        expect(state.stringify, true);
      });

      test('toString returns expected format', () {
        const rule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );
        const state = PortRangeTriggeringRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final string = state.toString();

        expect(string, contains('PortRangeTriggeringRuleState'));
        expect(string, contains('rules:'));
        expect(string, contains('rule:'));
        expect(string, contains('editIndex:'));
      });
    });
  });
}
