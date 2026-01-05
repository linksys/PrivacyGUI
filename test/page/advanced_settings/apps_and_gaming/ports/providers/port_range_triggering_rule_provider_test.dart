import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_rule_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('PortRangeTriggeringRuleNotifier', () {
    group('initial state', () {
      test('has default initial state', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        final state = notifier.state;

        expect(state.rules, isEmpty);
        expect(state.rule, isNull);
        expect(state.editIndex, isNull);
      });
    });

    group('init', () {
      test('initializes with rules and rule for add mode', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRules = [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Existing',
          ),
        ];
        const newRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 4000,
          lastTriggerPort: 4000,
          firstForwardedPort: 4100,
          lastForwardedPort: 4100,
          description: 'New',
        );

        notifier.init(existingRules, newRule, null);

        expect(notifier.state.rules, existingRules);
        expect(notifier.state.rule, newRule);
        expect(notifier.state.editIndex, isNull);
      });

      test('initializes with rules and rule for edit mode', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Existing',
        );
        const existingRules = [existingRule];

        notifier.init(existingRules, existingRule, 0);

        expect(notifier.state.rules, existingRules);
        expect(notifier.state.rule, existingRule);
        expect(notifier.state.editIndex, 0);
      });
    });

    group('updateRule', () {
      test('updates rule in state', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const newRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 5000,
          lastTriggerPort: 5000,
          firstForwardedPort: 5100,
          lastForwardedPort: 5100,
          description: 'Updated',
        );

        notifier.updateRule(newRule);

        expect(notifier.state.rule, newRule);
      });

      test('updates rule to null', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const initialRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Initial',
        );

        notifier.init([], initialRule, null);
        notifier.updateRule(null);

        expect(notifier.state.rule, isNull);
      });
    });

    group('isRuleValid', () {
      test('returns false when rule is null', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);

        expect(notifier.isRuleValid(), false);
      });

      test('returns false when description is empty', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const invalidRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: '', // Empty description
        );

        notifier.init([], invalidRule, null);

        expect(notifier.isRuleValid(), false);
      });

      test('returns false when forwarded port range is invalid', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const invalidRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3074,
          firstForwardedPort: 3080, // First > Last
          lastForwardedPort: 3075,
          description: 'Test',
        );

        notifier.init([], invalidRule, null);

        expect(notifier.isRuleValid(), false);
      });

      test('returns false when trigger port range is invalid', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const invalidRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3080, // First > Last
          lastTriggerPort: 3074,
          firstForwardedPort: 3075,
          lastForwardedPort: 3075,
          description: 'Test',
        );

        notifier.init([], invalidRule, null);

        expect(notifier.isRuleValid(), false);
      });

      test('returns true for valid rule', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const validRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3080,
          firstForwardedPort: 3075,
          lastForwardedPort: 3085,
          description: 'Valid Rule',
        );

        notifier.init([], validRule, null);

        expect(notifier.isRuleValid(), true);
      });
    });

    group('isNameValid', () {
      test('returns false for empty name', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);

        expect(notifier.isNameValid(''), false);
      });

      test('returns true for non-empty name', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);

        expect(notifier.isNameValid('Test Rule'), true);
      });
    });

    group('isPortRangeValid', () {
      test('returns true when lastPort >= firstPort', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);

        expect(notifier.isPortRangeValid(100, 200), true);
        expect(notifier.isPortRangeValid(100, 100), true);
      });

      test('returns false when lastPort < firstPort', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);

        expect(notifier.isPortRangeValid(200, 100), false);
      });
    });

    group('isTriggeredPortConflict', () {
      test('returns false when no conflicting rules exist', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3080,
          firstForwardedPort: 3075,
          lastForwardedPort: 3085,
          description: 'Existing',
        );

        notifier.init([existingRule], null, null);

        // No overlap
        expect(notifier.isTriggeredPortConflict(4000, 4100), false);
      });

      test('returns true when port range overlaps with existing rule', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3080,
          firstForwardedPort: 3075,
          lastForwardedPort: 3085,
          description: 'Existing',
        );

        notifier.init([existingRule], null, null);

        // Overlapping
        expect(notifier.isTriggeredPortConflict(3077, 3090), true);
      });

      test('excludes current rule when in edit mode', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3080,
          firstForwardedPort: 3075,
          lastForwardedPort: 3085,
          description: 'Existing',
        );

        notifier.init([existingRule], existingRule, 0);

        // Same port range as existing, but editing index 0
        expect(notifier.isTriggeredPortConflict(3074, 3080), false);
      });
    });

    group('isForwardedPortConflict', () {
      test('returns false when no conflicting rules exist', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3080,
          firstForwardedPort: 3075,
          lastForwardedPort: 3085,
          description: 'Existing',
        );

        notifier.init([existingRule], null, null);

        // No overlap with forwarded ports
        expect(notifier.isForwardedPortConflict(4000, 4100), false);
      });

      test('returns true when trigger port overlaps with existing forwarded',
          () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3080,
          firstForwardedPort: 3075,
          lastForwardedPort: 3085,
          description: 'Existing',
        );

        notifier.init([existingRule], null, null);

        // Overlapping with forwarded ports
        expect(notifier.isForwardedPortConflict(3080, 3090), true);
      });

      test('excludes current rule when in edit mode', () {
        final notifier =
            container.read(portRangeTriggeringRuleProvider.notifier);
        const existingRule = PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3074,
          lastTriggerPort: 3080,
          firstForwardedPort: 3075,
          lastForwardedPort: 3085,
          description: 'Existing',
        );

        notifier.init([existingRule], existingRule, 0);

        // Same as forwarded port, editing index 0
        expect(notifier.isForwardedPortConflict(3075, 3085), false);
      });
    });
  });
}
