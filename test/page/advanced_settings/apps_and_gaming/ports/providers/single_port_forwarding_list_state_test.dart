import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('SinglePortForwardingListStatus', () {
    test('creates instance with default values', () {
      const status = SinglePortForwardingListStatus();

      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
      expect(status.routerIp, '192.168.1.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('creates instance with custom values', () {
      const status = SinglePortForwardingListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      expect(status.maxRules, 100);
      expect(status.maxDescriptionLength, 64);
      expect(status.routerIp, '10.0.0.1');
      expect(status.subnetMask, '255.255.0.0');
    });

    test('copyWith updates specified fields', () {
      const status = SinglePortForwardingListStatus();
      final updated = status.copyWith(
        maxRules: 75,
        routerIp: '192.168.2.1',
      );

      expect(updated.maxRules, 75);
      expect(updated.maxDescriptionLength, 32); // unchanged
      expect(updated.routerIp, '192.168.2.1');
      expect(updated.subnetMask, '255.255.255.0'); // unchanged
    });

    test('toMap converts to map correctly', () {
      const status = SinglePortForwardingListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      final map = status.toMap();

      expect(map['maxRules'], 100);
      expect(map['maxDescriptionLength'], 64);
      expect(map['routerIp'], '10.0.0.1');
      expect(map['subnetMask'], '255.255.0.0');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'maxRules': 100,
        'maxDescriptionLength': 64,
        'routerIp': '10.0.0.1',
        'subnetMask': '255.255.0.0',
      };

      final status = SinglePortForwardingListStatus.fromMap(map);

      expect(status.maxRules, 100);
      expect(status.maxDescriptionLength, 64);
      expect(status.routerIp, '10.0.0.1');
      expect(status.subnetMask, '255.255.0.0');
    });

    test('toJson/fromJson serialization works correctly', () {
      const original = SinglePortForwardingListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      final json = original.toJson();
      final restored = SinglePortForwardingListStatus.fromJson(json);

      expect(restored, original);
    });

    test('equality comparison works correctly', () {
      const status1 = SinglePortForwardingListStatus(maxRules: 100);
      const status2 = SinglePortForwardingListStatus(maxRules: 100);
      const status3 = SinglePortForwardingListStatus(maxRules: 75);

      expect(status1, status2);
      expect(status1, isNot(status3));
    });
  });

  group('SinglePortForwardingListState', () {
    test('creates instance with preservable settings', () {
      const rule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );
      const settings = SinglePortForwardingRuleListUIModel(rules: [rule]);
      const status = SinglePortForwardingListStatus();

      const state = SinglePortForwardingListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      expect(state.settings.original, settings);
      expect(state.settings.current, settings);
      expect(state.status, status);
    });

    test('copyWith updates specified fields', () {
      const settings1 = SinglePortForwardingRuleListUIModel(rules: []);
      const settings2 = SinglePortForwardingRuleListUIModel(rules: []);
      const status1 = SinglePortForwardingListStatus(maxRules: 50);
      const status2 = SinglePortForwardingListStatus(maxRules: 100);

      const state = SinglePortForwardingListState(
        settings: Preservable(original: settings1, current: settings1),
        status: status1,
      );

      final updated = state.copyWith(
        settings: const Preservable(original: settings2, current: settings2),
      );

      expect(updated.settings.original, settings2);
      expect(updated.status, status1); // unchanged

      final updatedStatus = state.copyWith(status: status2);
      expect(updatedStatus.status, status2);
      expect(updatedStatus.settings.original, settings1); // unchanged
    });

    test('toMap/fromMap serialization works correctly', () {
      const rule = SinglePortForwardingRuleUIModel(
        isEnabled: true,
        externalPort: 8080,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        internalPort: 8080,
        description: 'Test',
      );
      const settings = SinglePortForwardingRuleListUIModel(rules: [rule]);
      const status = SinglePortForwardingListStatus(maxRules: 75);

      const original = SinglePortForwardingListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      final map = original.toMap();
      final restored = SinglePortForwardingListState.fromMap(map);

      expect(restored.settings.original.rules.length, 1);
      expect(restored.settings.original.rules.first.externalPort, 8080);
      expect(restored.status.maxRules, 75);
    });

    test('toJson/fromJson serialization works correctly', () {
      const settings = SinglePortForwardingRuleListUIModel(rules: []);
      const status = SinglePortForwardingListStatus();

      const original = SinglePortForwardingListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      final json = original.toJson();
      final restored = SinglePortForwardingListState.fromJson(json);

      expect(restored.settings.original.rules, isEmpty);
      expect(restored.status.maxRules, 50);
    });

    test('equality comparison works correctly', () {
      const settings = SinglePortForwardingRuleListUIModel(rules: []);
      const status = SinglePortForwardingListStatus();

      const state1 = SinglePortForwardingListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      const state2 = SinglePortForwardingListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      expect(state1, state2);
    });
  });
}