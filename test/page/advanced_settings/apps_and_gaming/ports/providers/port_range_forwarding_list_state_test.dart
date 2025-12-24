import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_list_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('PortRangeForwardingListStatus', () {
    test('creates instance with default values', () {
      const status = PortRangeForwardingListStatus();

      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
      expect(status.routerIp, '192.168.1.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('creates instance with custom values', () {
      const status = PortRangeForwardingListStatus(
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

    test('Equatable props includes all fields', () {
      const status1 = PortRangeForwardingListStatus(
        maxRules: 50,
        maxDescriptionLength: 32,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const status2 = PortRangeForwardingListStatus(
        maxRules: 50,
        maxDescriptionLength: 32,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      const status3 = PortRangeForwardingListStatus(
        maxRules: 100,
        maxDescriptionLength: 32,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      expect(status1, status2);
      expect(status1 == status3, false);
    });

    test('Equatable detects difference in maxDescriptionLength', () {
      const status1 = PortRangeForwardingListStatus(maxDescriptionLength: 32);
      const status2 = PortRangeForwardingListStatus(maxDescriptionLength: 64);

      expect(status1 == status2, false);
    });

    test('Equatable detects difference in routerIp', () {
      const status1 = PortRangeForwardingListStatus(routerIp: '192.168.1.1');
      const status2 = PortRangeForwardingListStatus(routerIp: '10.0.0.1');

      expect(status1 == status2, false);
    });

    test('Equatable detects difference in subnetMask', () {
      const status1 =
          PortRangeForwardingListStatus(subnetMask: '255.255.255.0');
      const status2 = PortRangeForwardingListStatus(subnetMask: '255.255.0.0');

      expect(status1 == status2, false);
    });

    test('copyWith creates new instance with updated values', () {
      const original = PortRangeForwardingListStatus();

      final updated = original.copyWith(
        maxRules: 100,
        maxDescriptionLength: 64,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      expect(updated.maxRules, 100);
      expect(updated.maxDescriptionLength, 64);
      expect(updated.routerIp, '10.0.0.1');
      expect(updated.subnetMask, '255.255.0.0');
    });

    test('copyWith preserves unchanged fields', () {
      const original = PortRangeForwardingListStatus(
        maxRules: 50,
        maxDescriptionLength: 32,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      final updated = original.copyWith(maxRules: 100);

      expect(updated.maxRules, 100);
      expect(updated.maxDescriptionLength, original.maxDescriptionLength);
      expect(updated.routerIp, original.routerIp);
      expect(updated.subnetMask, original.subnetMask);
    });

    test('toMap converts status to Map correctly', () {
      const status = PortRangeForwardingListStatus(
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

    test('fromMap creates status from Map correctly', () {
      final map = {
        'maxRules': 100,
        'maxDescriptionLength': 64,
        'routerIp': '10.0.0.1',
        'subnetMask': '255.255.0.0',
      };

      final status = PortRangeForwardingListStatus.fromMap(map);

      expect(status.maxRules, 100);
      expect(status.maxDescriptionLength, 64);
      expect(status.routerIp, '10.0.0.1');
      expect(status.subnetMask, '255.255.0.0');
    });

    test('fromMap uses default values for missing fields', () {
      final map = <String, dynamic>{};

      final status = PortRangeForwardingListStatus.fromMap(map);

      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
      expect(status.routerIp, '192.168.1.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('toJson and fromJson work correctly', () {
      const original = PortRangeForwardingListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      final json = original.toJson();
      final restored = PortRangeForwardingListStatus.fromJson(json);

      expect(restored, original);
    });
  });

  group('PortRangeForwardingListState', () {
    test('creates instance with required parameters', () {
      const state = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: PortRangeForwardingRuleListUIModel(rules: []),
        ),
        status: PortRangeForwardingListStatus(),
      );

      expect(state.settings.original.rules, isEmpty);
      expect(state.settings.current.rules, isEmpty);
      expect(state.status.maxRules, 50);
    });

    test('creates instance with rules', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const state = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      expect(state.settings.original.rules, [rule]);
      expect(state.settings.current.rules, [rule]);
    });

    test('Equatable props includes settings and status', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const state1 = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule]),
        ),
        status: PortRangeForwardingListStatus(maxRules: 50),
      );

      const state2 = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule]),
        ),
        status: PortRangeForwardingListStatus(maxRules: 50),
      );

      const state3 = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule]),
        ),
        status: PortRangeForwardingListStatus(maxRules: 100),
      );

      expect(state1, state2);
      expect(state1 == state3, false);
    });

    test('Equatable detects difference in settings', () {
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

      const state1 = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule1]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule1]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      const state2 = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule2]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule2]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      expect(state1 == state2, false);
    });

    test('Equatable detects difference between original and current', () {
      const originalRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Original',
      );

      const modifiedRule = PortRangeForwardingRuleUIModel(
        isEnabled: false,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Modified',
      );

      const state1 = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [originalRule]),
          current: PortRangeForwardingRuleListUIModel(rules: [originalRule]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      const state2 = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [originalRule]),
          current: PortRangeForwardingRuleListUIModel(rules: [modifiedRule]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      expect(state1 == state2, false);
    });
  });

  group('PortRangeForwardingListState - copyWith', () {
    test('copyWith creates new instance with updated settings', () {
      const original = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: PortRangeForwardingRuleListUIModel(rules: []),
        ),
        status: PortRangeForwardingListStatus(),
      );

      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'New Rule',
      );

      const newSettings = Preservable(
        original: PortRangeForwardingRuleListUIModel(rules: [newRule]),
        current: PortRangeForwardingRuleListUIModel(rules: [newRule]),
      );

      final updated = original.copyWith(settings: newSettings);

      expect(updated.settings.current.rules, [newRule]);
      expect(updated.status, original.status);
    });

    test('copyWith creates new instance with updated status', () {
      const original = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: PortRangeForwardingRuleListUIModel(rules: []),
        ),
        status: PortRangeForwardingListStatus(),
      );

      const newStatus = PortRangeForwardingListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      final updated = original.copyWith(status: newStatus);

      expect(updated.status, newStatus);
      expect(updated.settings, original.settings);
    });

    test('copyWith updates both settings and status', () {
      const original = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: PortRangeForwardingRuleListUIModel(rules: []),
        ),
        status: PortRangeForwardingListStatus(),
      );

      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'New Rule',
      );

      const newSettings = Preservable(
        original: PortRangeForwardingRuleListUIModel(rules: [newRule]),
        current: PortRangeForwardingRuleListUIModel(rules: [newRule]),
      );

      const newStatus = PortRangeForwardingListStatus(maxRules: 100);

      final updated = original.copyWith(
        settings: newSettings,
        status: newStatus,
      );

      expect(updated.settings.current.rules, [newRule]);
      expect(updated.status.maxRules, 100);
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

      const original = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule]),
        ),
        status: PortRangeForwardingListStatus(maxRules: 50),
      );

      const newStatus = PortRangeForwardingListStatus(maxRules: 100);

      final updated = original.copyWith(status: newStatus);

      expect(updated.settings, original.settings);
      expect(updated.status.maxRules, 100);
    });
  });

  group('PortRangeForwardingListState - Serialization', () {
    test('toMap converts state to Map correctly', () {
      const rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      const state = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule]),
        ),
        status: PortRangeForwardingListStatus(
          maxRules: 100,
          maxDescriptionLength: 64,
          routerIp: '10.0.0.1',
          subnetMask: '255.255.0.0',
        ),
      );

      final map = state.toMap();

      expect(map['settings'], isA<Map<String, dynamic>>());
      expect(map['status'], isA<Map<String, dynamic>>());
      expect(map['status']['maxRules'], 100);
    });

    test('toMap handles empty rules', () {
      const state = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: PortRangeForwardingRuleListUIModel(rules: []),
        ),
        status: PortRangeForwardingListStatus(),
      );

      final map = state.toMap();

      expect(map['settings'], isA<Map<String, dynamic>>());
      expect(map['status'], isA<Map<String, dynamic>>());
    });

    test('fromMap creates state from Map correctly', () {
      final map = {
        'settings': {
          'original': {
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
          },
          'current': {
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
          },
        },
        'status': {
          'maxRules': 100,
          'maxDescriptionLength': 64,
          'routerIp': '10.0.0.1',
          'subnetMask': '255.255.0.0',
        },
      };

      final state = PortRangeForwardingListState.fromMap(map);

      expect(state.settings.original.rules, hasLength(1));
      expect(state.settings.current.rules, hasLength(1));
      expect(state.status.maxRules, 100);
      expect(state.status.routerIp, '10.0.0.1');
    });

    test('fromMap handles empty rules', () {
      final map = {
        'settings': {
          'original': {'rules': []},
          'current': {'rules': []},
        },
        'status': {
          'maxRules': 50,
          'maxDescriptionLength': 32,
          'routerIp': '192.168.1.1',
          'subnetMask': '255.255.255.0',
        },
      };

      final state = PortRangeForwardingListState.fromMap(map);

      expect(state.settings.original.rules, isEmpty);
      expect(state.settings.current.rules, isEmpty);
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

      const original = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule]),
        ),
        status: PortRangeForwardingListStatus(
          maxRules: 100,
          maxDescriptionLength: 64,
          routerIp: '10.0.0.1',
          subnetMask: '255.255.0.0',
        ),
      );

      final json = original.toJson();
      final restored = PortRangeForwardingListState.fromJson(json);

      expect(restored, original);
    });

    test('toJson and fromJson handle empty rules', () {
      const original = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: PortRangeForwardingRuleListUIModel(rules: []),
        ),
        status: PortRangeForwardingListStatus(),
      );

      final json = original.toJson();
      final restored = PortRangeForwardingListState.fromJson(json);

      expect(restored.settings.original.rules, isEmpty);
      expect(restored.settings.current.rules, isEmpty);
    });
  });

  group('PortRangeForwardingListState - stringify', () {
    test('stringify is enabled', () {
      const state = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: PortRangeForwardingRuleListUIModel(rules: []),
        ),
        status: PortRangeForwardingListStatus(),
      );

      expect(state.stringify, true);
    });
  });
}