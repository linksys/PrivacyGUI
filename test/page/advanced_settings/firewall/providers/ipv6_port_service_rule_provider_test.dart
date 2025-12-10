import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

import '../services/ipv6_port_service_list_service_test_data.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Ipv6PortServiceRuleNotifier', () {
    test('initial state is empty', () {
      // Arrange
      final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

      // Act
      final state = notifier.state;

      // Assert
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    group('init', () {
      test('initializes state with rules', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rules = IPv6PortServiceTestData.createUIRuleList();

        // Act
        notifier.init(rules, null, null);

        // Assert
        expect(notifier.state.rules, equals(rules));
        expect(notifier.state.rule, isNull);
        expect(notifier.state.editIndex, isNull);
      });

      test('initializes state with rules and rule', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rules = IPv6PortServiceTestData.createUIRuleList();
        final rule = rules.first;

        // Act
        notifier.init(rules, rule, null);

        // Assert
        expect(notifier.state.rules, equals(rules));
        expect(notifier.state.rule, equals(rule));
        expect(notifier.state.editIndex, isNull);
      });

      test('initializes state with all parameters', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rules = IPv6PortServiceTestData.createUIRuleList();
        final rule = rules[1];
        const editIndex = 1;

        // Act
        notifier.init(rules, rule, editIndex);

        // Assert
        expect(notifier.state.rules, equals(rules));
        expect(notifier.state.rule, equals(rule));
        expect(notifier.state.editIndex, editIndex);
      });

      test('can re-initialize state with different values', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rules1 = [IPv6PortServiceTestData.createUIRule()];
        final rules2 = IPv6PortServiceTestData.createUIRuleList();

        // Act
        notifier.init(rules1, rules1.first, 0);
        notifier.init(rules2, null, null);

        // Assert
        expect(notifier.state.rules, equals(rules2));
        expect(notifier.state.rule, isNull);
        expect(notifier.state.editIndex, isNull);
      });
    });

    group('updateRule', () {
      test('updates rule in state', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rules = IPv6PortServiceTestData.createUIRuleList();
        final newRule = rules.first;

        // Act
        notifier.updateRule(newRule);

        // Assert
        expect(notifier.state.rule, equals(newRule));
      });

      test('can update rule to null', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rules = IPv6PortServiceTestData.createUIRuleList();
        notifier.init(rules, rules.first, 0);

        // Act
        notifier.updateRule(null);

        // Assert
        expect(notifier.state.rule, isNull);
      });

      test('can update rule multiple times', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rules = IPv6PortServiceTestData.createUIRuleList();

        // Act
        notifier.updateRule(rules[0]);
        notifier.updateRule(rules[1]);
        notifier.updateRule(rules[2]);

        // Assert
        expect(notifier.state.rule, equals(rules[2]));
      });
    });

    group('isRuleValid', () {
      test('returns false when rule is null', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, false);
      });

      test('returns true for valid rule', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rule = IPv6PortServiceTestData.createUIRule(
          description: 'Valid Rule',
          internalIPAddress: '2001:db8::1',
          externalPort: 80,
          internalPort: 80,
        );
        notifier.init([], rule, null);

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, true);
      });

      test('returns false when description is empty', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rule = IPv6PortServiceTestData.createUIRule(
          description: '',
        );
        notifier.init([], rule, null);

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, false);
      });

      test('returns false when description exceeds max length', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rule = IPv6PortServiceTestData.createUIRule(
          description: 'a' * 33, // Max is 32
        );
        notifier.init([], rule, null);

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, false);
      });

      test('returns false for invalid IPv6 address', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rule = IPv6PortServiceTestData.createUIRule(
          internalIPAddress: 'invalid',
        );
        notifier.init([], rule, null);

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, false);
      });

      test('returns false when port range is invalid', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final rule = IPv6PortServiceTestData.createUIRule(
          externalPort: 100,
          internalPort: 50, // Last port less than first port
        );
        notifier.init([], rule, null);

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, false);
      });

      test('returns false when port conflicts with existing rule', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 80,
            protocol: 'TCP',
          ),
        ];
        final newRule = IPv6PortServiceTestData.createUIRule(
          externalPort: 80,
          internalPort: 80,
          protocol: 'TCP',
        );
        notifier.init(existingRules, newRule, null);

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, false);
      });

      test('returns true when editing existing rule (no conflict with self)', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 80,
            protocol: 'TCP',
          ),
        ];
        final editRule = existingRules.first;
        notifier.init(existingRules, editRule, 0); // Editing index 0

        // Act
        final isValid = notifier.isRuleValid();

        // Assert
        expect(isValid, true);
      });
    });

    group('isRuleNameValidate', () {
      test('returns true for valid rule name', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act & Assert
        expect(notifier.isRuleNameValidate('Valid Name'), true);
      });

      test('returns false for empty rule name', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act & Assert
        expect(notifier.isRuleNameValidate(''), false);
      });

      test('returns false for rule name exceeding 32 characters', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act & Assert
        expect(notifier.isRuleNameValidate('a' * 33), false);
      });

      test('returns true for rule name at max length (32)', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act & Assert
        expect(notifier.isRuleNameValidate('a' * 32), true);
      });
    });

    group('isDeviceIpValidate', () {
      test('returns true for valid IPv6 addresses', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final validAddresses = [
          '2001:db8::1',
          'fe80::1',
          '::1',
          '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
        ];

        // Act & Assert
        for (final address in validAddresses) {
          expect(notifier.isDeviceIpValidate(address), true,
              reason: '$address should be valid');
        }
      });

      test('returns false for invalid IPv6 addresses', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final invalidAddresses = [
          '',
          'invalid',
          '192.168.1.1', // IPv4
          'gggg::1',
          '2001:db8::xyz',
        ];

        // Act & Assert
        for (final address in invalidAddresses) {
          expect(notifier.isDeviceIpValidate(address), false,
              reason: '$address should be invalid');
        }
      });
    });

    group('isPortRangeValid', () {
      test('returns true when last port equals first port', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act & Assert
        expect(notifier.isPortRangeValid(80, 80), true);
      });

      test('returns true when last port is greater than first port', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act & Assert
        expect(notifier.isPortRangeValid(8000, 9000), true);
      });

      test('returns false when last port is less than first port', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        // Act & Assert
        expect(notifier.isPortRangeValid(9000, 8000), false);
      });
    });

    group('isPortConflict', () {
      test('returns false when no rules exist', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        notifier.init([], null, null);

        // Act
        final hasConflict = notifier.isPortConflict(80, 80, 'TCP');

        // Assert
        expect(hasConflict, false);
      });

      test('returns true when port overlaps with existing rule', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 90,
            protocol: 'TCP',
          ),
        ];
        notifier.init(existingRules, null, null);

        // Act
        final hasConflict = notifier.isPortConflict(85, 85, 'TCP');

        // Assert
        expect(hasConflict, true);
      });

      test('returns false when port does not overlap', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 90,
            protocol: 'TCP',
          ),
        ];
        notifier.init(existingRules, null, null);

        // Act
        final hasConflict = notifier.isPortConflict(100, 110, 'TCP');

        // Assert
        expect(hasConflict, false);
      });

      test('returns false when protocol differs', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 80,
            protocol: 'TCP',
          ),
        ];
        notifier.init(existingRules, null, null);

        // Act
        final hasConflict = notifier.isPortConflict(80, 80, 'UDP');

        // Assert
        expect(hasConflict, false);
      });

      test('returns true when new protocol is Both and existing is TCP', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 80,
            protocol: 'TCP',
          ),
        ];
        notifier.init(existingRules, null, null);

        // Act
        final hasConflict = notifier.isPortConflict(80, 80, 'Both');

        // Assert
        expect(hasConflict, true);
      });

      test('returns false when editing same rule', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 80,
            protocol: 'TCP',
          ),
        ];
        notifier.init(existingRules, existingRules.first, 0);

        // Act
        final hasConflict = notifier.isPortConflict(80, 80, 'TCP');

        // Assert
        expect(hasConflict, false);
      });

      test('returns true when editing different rule with conflict', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 80,
            internalPort: 80,
            protocol: 'TCP',
          ),
          IPv6PortServiceTestData.createUIRule(
            externalPort: 443,
            internalPort: 443,
            protocol: 'TCP',
          ),
        ];
        notifier.init(existingRules, existingRules[1], 1); // Editing rule at index 1

        // Act
        final hasConflict = notifier.isPortConflict(80, 80, 'TCP');

        // Assert
        expect(hasConflict, true);
      });

      test('handles port range overlaps correctly', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);
        final existingRules = [
          IPv6PortServiceTestData.createUIRule(
            externalPort: 8000,
            internalPort: 9000,
            protocol: 'TCP',
          ),
        ];
        notifier.init(existingRules, null, null);

        // Act & Assert
        expect(notifier.isPortConflict(7500, 8500, 'TCP'), true); // Overlaps start
        expect(notifier.isPortConflict(8500, 9500, 'TCP'), true); // Overlaps end
        expect(notifier.isPortConflict(8100, 8200, 'TCP'), true); // Within range
        expect(notifier.isPortConflict(7000, 7999, 'TCP'), false); // Before range
        expect(notifier.isPortConflict(9001, 9100, 'TCP'), false); // After range
      });
    });
  });
}
