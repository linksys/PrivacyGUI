import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('PortRangeTriggeringListStatus', () {
    test('creates instance with default values', () {
      const status = PortRangeTriggeringListStatus();

      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
    });

    test('creates instance with custom values', () {
      const status = PortRangeTriggeringListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
      );

      expect(status.maxRules, 100);
      expect(status.maxDescriptionLength, 64);
    });

    test('copyWith updates specified fields', () {
      const status = PortRangeTriggeringListStatus();
      final updated = status.copyWith(maxRules: 75);

      expect(updated.maxRules, 75);
      expect(updated.maxDescriptionLength, 32); // unchanged
    });

    test('copyWith preserves all fields when none specified', () {
      const status = PortRangeTriggeringListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
      );
      final copied = status.copyWith();

      expect(copied, status);
    });

    test('toMap converts to map correctly', () {
      const status = PortRangeTriggeringListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
      );

      final map = status.toMap();

      expect(map['maxRules'], 100);
      expect(map['maxDescriptionLength'], 64);
    });

    test('fromMap creates instance from map', () {
      final map = {
        'maxRules': 100,
        'maxDescriptionLength': 64,
      };

      final status = PortRangeTriggeringListStatus.fromMap(map);

      expect(status.maxRules, 100);
      expect(status.maxDescriptionLength, 64);
    });

    test('fromMap uses defaults for missing or null values', () {
      final map = <String, dynamic>{};

      final status = PortRangeTriggeringListStatus.fromMap(map);

      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
    });

    test('toJson/fromJson serialization works correctly', () {
      const original = PortRangeTriggeringListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
      );

      final json = original.toJson();
      final restored = PortRangeTriggeringListStatus.fromJson(json);

      expect(restored, original);
    });

    test('equality comparison works correctly', () {
      const status1 = PortRangeTriggeringListStatus(maxRules: 100);
      const status2 = PortRangeTriggeringListStatus(maxRules: 100);
      const status3 = PortRangeTriggeringListStatus(maxRules: 75);

      expect(status1, status2);
      expect(status1, isNot(status3));
    });
  });

  group('PortRangeTriggeringListState', () {
    test('creates instance with preservable settings', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Test',
      );
      const settings = PortRangeTriggeringRuleListUIModel(rules: [rule]);
      const status = PortRangeTriggeringListStatus();

      const state = PortRangeTriggeringListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      expect(state.settings.original, settings);
      expect(state.settings.current, settings);
      expect(state.status, status);
    });

    test('copyWith updates specified fields', () {
      const settings1 = PortRangeTriggeringRuleListUIModel(rules: []);
      const status1 = PortRangeTriggeringListStatus(maxRules: 50);
      const status2 = PortRangeTriggeringListStatus(maxRules: 100);

      const state = PortRangeTriggeringListState(
        settings: Preservable(original: settings1, current: settings1),
        status: status1,
      );

      final updatedStatus = state.copyWith(status: status2);
      expect(updatedStatus.status, status2);
      expect(updatedStatus.settings.original, settings1); // unchanged
    });

    test('toMap/fromMap serialization works correctly', () {
      const rule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Test',
      );
      const settings = PortRangeTriggeringRuleListUIModel(rules: [rule]);
      const status = PortRangeTriggeringListStatus(maxRules: 75);

      const original = PortRangeTriggeringListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      final map = original.toMap();
      final restored = PortRangeTriggeringListState.fromMap(map);

      expect(restored.settings.original.rules.length, 1);
      expect(restored.settings.original.rules.first.description, 'Test');
      expect(restored.status.maxRules, 75);
    });

    test('toJson/fromJson serialization works correctly', () {
      const settings = PortRangeTriggeringRuleListUIModel(rules: []);
      const status = PortRangeTriggeringListStatus();

      const original = PortRangeTriggeringListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      final json = original.toJson();
      final restored = PortRangeTriggeringListState.fromJson(json);

      expect(restored.settings.original.rules, isEmpty);
      expect(restored.status.maxRules, 50);
    });

    test('equality comparison works correctly', () {
      const settings = PortRangeTriggeringRuleListUIModel(rules: []);
      const status = PortRangeTriggeringListStatus();

      const state1 = PortRangeTriggeringListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      const state2 = PortRangeTriggeringListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      expect(state1, state2);
    });

    test('props returns correct list', () {
      const settings = PortRangeTriggeringRuleListUIModel(rules: []);
      const status = PortRangeTriggeringListStatus();

      const state = PortRangeTriggeringListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      expect(state.props, [state.settings, state.status]);
    });

    test('stringify returns true', () {
      const settings = PortRangeTriggeringRuleListUIModel(rules: []);
      const status = PortRangeTriggeringListStatus();

      const state = PortRangeTriggeringListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      expect(state.stringify, true);
    });
  });
}
