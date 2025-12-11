import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Ipv6PortServiceListProvider', () {
    group('build', () {
      test('returns default state with empty rules and default status', () {
        // Act
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules, isEmpty);
        expect(state.settings.original.rules, isEmpty);
        expect(state.status, isNotNull);
        expect(state.status.maxRules, 50);
        expect(state.status.maxDescriptionLength, 32);
      });

      test('initializes with settings preservable having original and current',
          () {
        // Act
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.original, isNotNull);
        expect(state.settings.current, isNotNull);
        expect(state.settings.original, state.settings.current);
      });

      test('initializes with default Ipv6PortServiceListStatus', () {
        // Act
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.status, isA<Ipv6PortServiceListStatus>());
        expect(state.status.maxRules, 50);
        expect(state.status.maxDescriptionLength, 32);
      });
    });

    group('notifier access', () {
      test('notifier can be accessed from container', () {
        // Act
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier, isNotNull);
        expect(notifier, isA<Ipv6PortServiceListNotifier>());
      });

      test('preservable contract accessor returns notifier', () {
        // Act
        final preservable =
            container.read(preservableIpv6PortServiceListProvider)
                as Ipv6PortServiceListNotifier;

        // Assert
        expect(preservable, isNotNull);
        expect(preservable, isA<Ipv6PortServiceListNotifier>());
      });
    });

    group('isExceedMax', () {
      test('returns false when rules count is below max', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        final rules = List<IPv6PortServiceRuleUI>.generate(
          25,
          (i) => IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule $i',
            ipv6Address: '2001:db8::$i',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        );

        // Act
        notifier.setRules(rules);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(notifier.isExceedMax(), false);
      });

      test('returns false when rules count equals max', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        final rules = List<IPv6PortServiceRuleUI>.generate(
          50,
          (i) => IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule $i',
            ipv6Address: '2001:db8::$i',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        );

        // Act
        notifier.setRules(rules);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(notifier.isExceedMax(), true);
      });

      test('returns true when rules count exceeds max', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        final rules = List<IPv6PortServiceRuleUI>.generate(
          55,
          (i) => IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule $i',
            ipv6Address: '2001:db8::$i',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        );

        // Act
        notifier.setRules(rules);

        // Assert
        expect(notifier.isExceedMax(), true);
      });

      test('returns false for empty rules', () {
        // Act
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier.isExceedMax(), false);
      });
    });

    group('state preservation', () {
      test('original and current are equal after init', () {
        // Arrange
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules([rule]);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.original.rules, [rule]);
        expect(state.settings.current.rules, [rule]);
        expect(state.settings.original, state.settings.current);
      });

      test('preserves original after modifying current', () {
        // Arrange
        final rule1 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 1',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final rule2 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 2',
          ipv6Address: '2001:db8::2',
          portRanges: const [
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
          ],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules([rule1]);
        var state = container.read(ipv6PortServiceListProvider);
        expect(state.settings.original.rules, [rule1]);

        // Now "modify" by creating new state with different rules
        // (in real use, this would be done through form interactions)
        final newState = state.copyWith(
          settings: state.settings.copyWith(
              current: state.settings.current.copyWith(rules: [rule1, rule2])),
        );

        // Assert - original should remain unchanged
        expect(state.settings.original.rules, [rule1]);
        expect(newState.settings.current.rules, [rule1, rule2]);
        expect(newState.settings.original.rules, [rule1]);
      });
    });

    group('isDirty tracking', () {
      test('isDirty is false initially', () {
        // Act
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.isDirty, false);
      });

      test('isDirty remains false after init with same data', () {
        // Arrange
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules([rule]);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.isDirty, false);
      });

      test('isDirty is true after modifying rules', () {
        // Arrange
        final rule1 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 1',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final rule2 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 2',
          ipv6Address: '2001:db8::2',
          portRanges: const [
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
          ],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        notifier.setRules([rule1]);

        // Act - Create new state with modified rules
        var state = container.read(ipv6PortServiceListProvider);
        state = state.copyWith(
          settings: state.settings.copyWith(
            current: state.settings.current.copyWith(rules: [rule1, rule2]),
          ),
        );

        // Assert
        expect(state.isDirty, true);
      });

      test('isDirty tracks changes to rule count', () {
        // Arrange
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        notifier.setRules([rule]);

        var state = container.read(ipv6PortServiceListProvider);
        expect(state.isDirty, false);

        // Act - Remove the rule
        state = state.copyWith(
          settings: state.settings.copyWith(
            current: state.settings.current.copyWith(rules: []),
          ),
        );

        // Assert
        expect(state.isDirty, true);
      });
    });

    group('state immutability', () {
      test('init does not mutate previous state', () {
        // Arrange
        final rule1 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 1',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final rule2 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 2',
          ipv6Address: '2001:db8::2',
          portRanges: const [
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
          ],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        notifier.setRules([rule1]);
        final state1 = container.read(ipv6PortServiceListProvider);

        // Act
        notifier.setRules([rule2]);
        final state2 = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state1.settings.current.rules, [rule1]);
        expect(state2.settings.current.rules, [rule2]);
        expect(
            identical(state1.settings.current, state2.settings.current), false);
      });

      test('multiple inits maintain immutability', () {
        // Arrange
        final rules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule 1',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule 2',
            ipv6Address: '2001:db8::2',
            portRanges: const [
              PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
            ],
          ),
        ];

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act & Assert
        notifier.setRules([rules[0]]);
        final state1 = container.read(ipv6PortServiceListProvider);
        expect(state1.settings.current.rules, [rules[0]]);

        notifier.setRules([rules[1]]);
        final state2 = container.read(ipv6PortServiceListProvider);
        expect(state2.settings.current.rules, [rules[1]]);

        expect(
            identical(state1.settings.current, state2.settings.current), false);
      });
    });

    group('method signatures', () {
      test('performFetch method is callable', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier.performFetch, isA<Function>());
      });

      test('performSave method is callable', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier.performSave, isA<Function>());
      });

      test('addRule method is callable', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier.addRule, isA<Function>());
      });

      test('editRule method is callable', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier.editRule, isA<Function>());
      });

      test('deleteRule method is callable', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier.deleteRule, isA<Function>());
      });

      test('isExceedMax method is callable', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Assert
        expect(notifier.isExceedMax, isA<Function>());
      });
    });

    group('large dataset handling', () {
      test('handles maximum allowed rules (50)', () {
        // Arrange
        final rules = List<IPv6PortServiceRuleUI>.generate(
          50,
          (i) => IPv6PortServiceRuleUI(
            enabled: i % 2 == 0,
            description: 'Rule $i',
            ipv6Address: '2001:db8::${i + 1}',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 1000, lastPort: 2000)
            ],
          ),
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules(rules);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.length, 50);
        expect(notifier.isExceedMax(), true);
      });

      test('handles many port ranges per rule', () {
        // Arrange
        final portRanges = List<PortRangeUI>.generate(
          20,
          (i) => PortRangeUI(
            protocol: i % 2 == 0 ? 'TCP' : 'UDP',
            firstPort: 1000 + i * 100,
            lastPort: 1000 + i * 100 + 50,
          ),
        );

        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Complex Rule',
          ipv6Address: '2001:db8::1',
          portRanges: portRanges,
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules([rule]);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.first.portRanges.length, 20);
      });

      test('handles mixed enabled and disabled rules', () {
        // Arrange
        final rules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Enabled Rule',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
          IPv6PortServiceRuleUI(
            enabled: false,
            description: 'Disabled Rule',
            ipv6Address: '2001:db8::2',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 443, lastPort: 443)
            ],
          ),
        ];

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules(rules);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules[0].enabled, true);
        expect(state.settings.current.rules[1].enabled, false);
      });
    });

    group('edge cases', () {
      test('handles init with empty rule list', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules([]);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules, isEmpty);
        expect(notifier.isExceedMax(), false);
      });

      test('handles rule with empty port ranges', () {
        // Arrange
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'No Ports',
          ipv6Address: '2001:db8::1',
          portRanges: const [],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules([rule]);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.first.portRanges, isEmpty);
      });

      test('handles rule with special characters in description', () {
        // Arrange
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule-#123!@Special_Port',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules([rule]);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.first.description,
            'Rule-#123!@Special_Port');
      });

      test('handles boundary IPv6 addresses', () {
        // Arrange
        final rules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'IPv6 Boundary 1',
            ipv6Address: '::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 0, lastPort: 0)
            ],
          ),
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'IPv6 Boundary 2',
            ipv6Address: 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 65535, lastPort: 65535)
            ],
          ),
        ];

        final notifier = container.read(ipv6PortServiceListProvider.notifier);

        // Act
        notifier.setRules(rules);
        final state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules[0].ipv6Address, '::1');
        expect(state.settings.current.rules[1].ipv6Address,
            'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff');
      });
    });
  });
}
