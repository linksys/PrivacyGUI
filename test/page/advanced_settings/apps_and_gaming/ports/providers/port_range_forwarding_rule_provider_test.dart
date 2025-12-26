import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_rule_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('PortRangeForwardingRuleNotifier - Initialization', () {
    test('build returns initial state with default values', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      final state = notifier.build();

      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    test('init sets state correctly for new rule', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      final rules = [
        const PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 3074,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          lastExternalPort: 3074,
          description: 'XBox Live',
        ),
      ];

      notifier.init(rules, null, null, '192.168.1.1', '255.255.255.0');

      final state = container.read(portRangeForwardingRuleProvider);
      expect(state.rules, rules);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
    });

    test('init sets state correctly for editing existing rule', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const existingRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );
      final rules = [existingRule];

      notifier.init(rules, existingRule, 0, '192.168.1.1', '255.255.255.0');

      final state = container.read(portRangeForwardingRuleProvider);
      expect(state.rules, rules);
      expect(state.rule, existingRule);
      expect(state.editIndex, 0);
      expect(state.routerIp, '192.168.1.1');
      expect(state.subnetMask, '255.255.255.0');
    });
  });

  group('PortRangeForwardingRuleNotifier - updateRule', () {
    test('updateRule updates the rule in state', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8080,
        protocol: 'UDP',
        internalServerIPAddress: '192.168.1.200',
        lastExternalPort: 8080,
        description: 'Test Rule',
      );

      notifier.updateRule(newRule);

      final state = container.read(portRangeForwardingRuleProvider);
      expect(state.rule, newRule);
    });

    test('updateRule can set rule to null', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const initialRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'XBox Live',
      );

      notifier.updateRule(initialRule);
      expect(container.read(portRangeForwardingRuleProvider).rule, initialRule);

      notifier.updateRule(null);
      expect(container.read(portRangeForwardingRuleProvider).rule, isNull);
    });
  });

  group('PortRangeForwardingRuleNotifier - Validation', () {
    test('isNameValid returns true for non-empty name', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);

      expect(notifier.isNameValid('XBox Live'), true);
      expect(notifier.isNameValid('A'), true);
      expect(notifier.isNameValid('Test 123'), true);
    });

    test('isNameValid returns false for empty name', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);

      expect(notifier.isNameValid(''), false);
    });

    test('isDeviceIpValidate validates IP within subnet', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');

      // Valid IPs within subnet
      expect(notifier.isDeviceIpValidate('192.168.1.100'), true);
      expect(notifier.isDeviceIpValidate('192.168.1.2'), true);
      expect(notifier.isDeviceIpValidate('192.168.1.254'), true);

      // Invalid IPs (outside subnet)
      expect(notifier.isDeviceIpValidate('192.168.2.100'), false);
      expect(notifier.isDeviceIpValidate('10.0.0.1'), false);
    });

    test('isDeviceIpValidate rejects invalid IP formats', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');

      expect(notifier.isDeviceIpValidate(''), false);
      expect(notifier.isDeviceIpValidate('192.168.1'), false);
      expect(notifier.isDeviceIpValidate('invalid'), false);
      expect(notifier.isDeviceIpValidate('192.168.1.256'), false);
    });

    test('isPortRangeValid returns true for valid port ranges', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);

      // Single port
      expect(notifier.isPortRangeValid(3074, 3074), true);
      // Valid range
      expect(notifier.isPortRangeValid(8000, 8100), true);
      expect(notifier.isPortRangeValid(1, 65535), true);
    });

    test('isPortRangeValid returns false for invalid port ranges', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);

      // Last port before first port
      expect(notifier.isPortRangeValid(8100, 8000), false);
      expect(notifier.isPortRangeValid(5000, 4999), false);
    });

    test('isPortConflict detects conflict with existing range rules', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      final existingRules = [
        const PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 8000,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          lastExternalPort: 8100,
          description: 'Existing Rule',
        ),
      ];
      notifier.init(existingRules, null, null, '192.168.1.1', '255.255.255.0');

      // Overlapping range (TCP)
      expect(notifier.isPortConflict(8050, 8150, 'TCP'), true);
      expect(notifier.isPortConflict(7990, 8010, 'TCP'), true);
      expect(notifier.isPortConflict(8020, 8080, 'TCP'), true);

      // Overlapping with 'Both' protocol
      expect(notifier.isPortConflict(8050, 8150, 'Both'), true);

      // Non-overlapping range (TCP)
      expect(notifier.isPortConflict(7000, 7999, 'TCP'), false);
      expect(notifier.isPortConflict(8101, 8200, 'TCP'), false);

      // Different protocol (UDP) - no conflict
      expect(notifier.isPortConflict(8050, 8150, 'UDP'), false);
    });

    test('isPortConflict with Both protocol conflicts with any protocol', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      final existingRules = [
        const PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 8000,
          protocol: 'Both',
          internalServerIPAddress: '192.168.1.100',
          lastExternalPort: 8100,
          description: 'Both Protocol Rule',
        ),
      ];
      notifier.init(existingRules, null, null, '192.168.1.1', '255.255.255.0');

      // Conflicts with TCP
      expect(notifier.isPortConflict(8050, 8150, 'TCP'), true);
      // Conflicts with UDP
      expect(notifier.isPortConflict(8050, 8150, 'UDP'), true);
      // Conflicts with Both
      expect(notifier.isPortConflict(8050, 8150, 'Both'), true);
    });

    test('isPortConflict excludes current edit index from conflict check', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const editingRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8000,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 8100,
        description: 'Editing Rule',
      );
      final existingRules = [
        editingRule,
        const PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 9000,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.200',
          lastExternalPort: 9100,
          description: 'Other Rule',
        ),
      ];
      notifier.init(
          existingRules, editingRule, 0, '192.168.1.1', '255.255.255.0');

      // Should not conflict with itself (index 0)
      expect(notifier.isPortConflict(8000, 8100, 'TCP'), false);

      // Should conflict with other rule (index 1)
      expect(notifier.isPortConflict(9050, 9150, 'TCP'), true);
    });

    test('isRuleValid returns true for valid rule', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const validRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Valid Rule',
      );
      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');
      notifier.updateRule(validRule);

      expect(notifier.isRuleValid(), true);
    });

    test('isRuleValid returns false when rule is null', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');

      expect(notifier.isRuleValid(), false);
    });

    test('isRuleValid returns false for invalid name', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const invalidRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: '',
      );
      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');
      notifier.updateRule(invalidRule);

      expect(notifier.isRuleValid(), false);
    });

    test('isRuleValid returns false for invalid IP', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const invalidRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '10.0.0.1', // Outside subnet
        lastExternalPort: 3074,
        description: 'Invalid IP Rule',
      );
      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');
      notifier.updateRule(invalidRule);

      expect(notifier.isRuleValid(), false);
    });

    test('isRuleValid returns false for invalid port range', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      const invalidRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8100,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 8000, // Invalid range
        description: 'Invalid Range Rule',
      );
      notifier.init([], null, null, '192.168.1.1', '255.255.255.0');
      notifier.updateRule(invalidRule);

      expect(notifier.isRuleValid(), false);
    });

    test('isRuleValid returns false for port conflict', () {
      final notifier = container.read(portRangeForwardingRuleProvider.notifier);
      final existingRules = [
        const PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 8000,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          lastExternalPort: 8100,
          description: 'Existing Rule',
        ),
      ];
      const conflictingRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8050,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.200',
        lastExternalPort: 8150,
        description: 'Conflicting Rule',
      );
      notifier.init(existingRules, null, null, '192.168.1.1', '255.255.255.0');
      notifier.updateRule(conflictingRule);

      expect(notifier.isRuleValid(), false);
    });
  });
}
