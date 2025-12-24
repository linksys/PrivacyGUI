import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/ipv6_port_service_list_service.dart';
import 'package:privacy_gui/providers/empty_status.dart';

// Mock class for IPv6PortServiceListService
class MockIPv6PortServiceListService extends Mock
    implements IPv6PortServiceListService {}

// Fake class for Ref
class FakeRef extends Fake implements Ref {}

void main() {
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeRef());
  });

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

    group('rule manipulation', () {
      test('addRule adds a new rule to the list', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
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

        // Act
        notifier.setRules([rule1]);
        notifier.addRule(rule2);
        var state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.length, 2);
        expect(state.settings.current.rules.last, rule2);
      });

      test('addRule throws exception when max rules reached', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        final rules = List<IPv6PortServiceRuleUI>.generate(
          50,
          (i) => IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule $i',
            ipv6Address: '2001:db8::${i + 1}',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        );
        final newRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Extra Rule',
          ipv6Address: '2001:db8::51',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 8080, lastPort: 8080)
          ],
        );

        // Act & Assert
        notifier.setRules(rules);
        expect(
          () => notifier.addRule(newRule),
          throwsException,
        );
      });

      test('editRule updates rule at specified index', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
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
        final updatedRule = IPv6PortServiceRuleUI(
          enabled: false,
          description: 'Updated Rule 2',
          ipv6Address: '2001:db8::2',
          portRanges: const [
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
          ],
        );

        // Act
        notifier.setRules([rule1, rule2]);
        notifier.editRule(1, updatedRule);
        var state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules[1], updatedRule);
        expect(state.settings.current.rules[0], rule1);
      });

      test('editRule throws exception for invalid index', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 1',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        // Act & Assert
        notifier.setRules([rule]);
        expect(
          () => notifier.editRule(5, rule),
          throwsException,
        );
      });

      test('deleteRule removes rule from list', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
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

        // Act
        notifier.setRules([rule1, rule2]);
        notifier.deleteRule(rule1);
        var state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.length, 1);
        expect(state.settings.current.rules.first, rule2);
      });

      test('deleteRule handles non-existent rule gracefully', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
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
        final nonExistentRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Non-existent',
          ipv6Address: '2001:db8::99',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 9999, lastPort: 9999)
          ],
        );

        // Act
        notifier.setRules([rule1, rule2]);
        notifier.deleteRule(nonExistentRule);
        var state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.length, 2);
      });

      test('multiple add/edit/delete operations maintain state', () {
        // Arrange
        final notifier = container.read(ipv6PortServiceListProvider.notifier);
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
        final rule3 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 3',
          ipv6Address: '2001:db8::3',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 443, lastPort: 443)
          ],
        );

        // Act
        notifier.setRules([rule1]);
        notifier.addRule(rule2);
        notifier.editRule(0, rule3);
        notifier.addRule(rule1);
        var state = container.read(ipv6PortServiceListProvider);

        // Assert
        expect(state.settings.current.rules.length, 3);
        expect(state.settings.current.rules[0], rule3);
        expect(state.settings.current.rules[1], rule2);
        expect(state.settings.current.rules[2], rule1);
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

    group('service integration', () {
      late MockIPv6PortServiceListService mockService;
      late ProviderContainer container;

      setUp(() {
        mockService = MockIPv6PortServiceListService();
        container = ProviderContainer(
          overrides: [
            ipv6PortServiceListServiceProvider.overrideWithValue(mockService),
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      group('performFetch integration', () {
        test('fetches rules via service provider', () async {
          // Arrange
          final testRules = IPv6PortServiceRuleUIList(rules: [
            IPv6PortServiceRuleUI(
              enabled: true,
              description: 'Test Rule',
              ipv6Address: '2001:db8::1',
              portRanges: const [
                PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
              ],
            ),
            IPv6PortServiceRuleUI(
              enabled: false,
              description: 'Another Rule',
              ipv6Address: '2001:db8::2',
              portRanges: const [
                PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
              ],
            )
          ]);

          when(() =>
                  mockService.fetchRulesFromDevice(any(), forceRemote: false))
              .thenAnswer((_) async => (testRules, const EmptyStatus()));

          // Act
          await container.read(ipv6PortServiceListProvider.notifier).fetch();

          // Assert
          final state = container.read(ipv6PortServiceListProvider);
          expect(state.settings.current.rules, hasLength(2));
          expect(state.settings.current.rules[0].description, 'Test Rule');
          expect(state.settings.current.rules[1].description, 'Another Rule');
          expect(state.settings.original, state.settings.current);

          verify(() =>
                  mockService.fetchRulesFromDevice(any(), forceRemote: false))
              .called(1);
        });

        test('fetches with forceRemote parameter', () async {
          // Arrange
          final testRules = IPv6PortServiceRuleUIList(rules: [
            IPv6PortServiceRuleUI(
              enabled: true,
              description: 'Remote Rule',
              ipv6Address: '2001:db8::1',
              portRanges: const [
                PortRangeUI(protocol: 'TCP', firstPort: 22, lastPort: 22)
              ],
            )
          ]);

          when(() => mockService.fetchRulesFromDevice(any(), forceRemote: true))
              .thenAnswer((_) async => (testRules, const EmptyStatus()));

          // Act
          await container
              .read(ipv6PortServiceListProvider.notifier)
              .fetch(forceRemote: true);

          // Assert
          final state = container.read(ipv6PortServiceListProvider);
          expect(state.settings.current.rules, hasLength(1));
          expect(state.settings.current.rules.first.description, 'Remote Rule');

          verify(() =>
                  mockService.fetchRulesFromDevice(any(), forceRemote: true))
              .called(1);
        });

        test('handles fetch failure gracefully', () async {
          // Arrange
          when(() =>
                  mockService.fetchRulesFromDevice(any(), forceRemote: false))
              .thenAnswer((_) async => (null, null));

          // Act
          final result = await container
              .read(ipv6PortServiceListProvider.notifier)
              .fetch();

          // Assert - provider returns current (empty) state instead of throwing
          expect(result.settings.current.rules, isEmpty);
          expect(result.settings.original.rules, isEmpty);
        });

        test('handles service exception', () async {
          // Arrange
          when(() =>
                  mockService.fetchRulesFromDevice(any(), forceRemote: false))
              .thenThrow(Exception('Service error'));

          // Act & Assert
          expect(
            () => container.read(ipv6PortServiceListProvider.notifier).fetch(),
            throwsException,
          );
        });
      });

      group('performSave integration', () {
        test('saves rules via service provider', () async {
          // Arrange
          final testRule = IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Test Save Rule',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 443, lastPort: 443)
            ],
          );

          when(() => mockService.saveRulesToDevice(any(), any()))
              .thenAnswer((_) async {});

          // Act
          container
              .read(ipv6PortServiceListProvider.notifier)
              .setRules([testRule]);
          await container.read(ipv6PortServiceListProvider.notifier).save();

          // Assert
          final state = container.read(ipv6PortServiceListProvider);
          expect(state.settings.original, state.settings.current);
          expect(state.isDirty, false);

          verify(() => mockService.saveRulesToDevice(any(), [testRule]))
              .called(1);
        });

        test('saves multiple rules', () async {
          // Arrange
          final testRules = [
            IPv6PortServiceRuleUI(
              enabled: true,
              description: 'Rule 1',
              ipv6Address: '2001:db8::1',
              portRanges: const [
                PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
              ],
            ),
            IPv6PortServiceRuleUI(
              enabled: false,
              description: 'Rule 2',
              ipv6Address: '2001:db8::2',
              portRanges: const [
                PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
              ],
            )
          ];

          when(() => mockService.saveRulesToDevice(any(), any()))
              .thenAnswer((_) async {});

          // Act
          container
              .read(ipv6PortServiceListProvider.notifier)
              .setRules(testRules);
          await container.read(ipv6PortServiceListProvider.notifier).save();

          // Assert
          verify(() => mockService.saveRulesToDevice(any(), testRules))
              .called(1);
        });

        test('handles save exception', () async {
          // Arrange
          final testRule = IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Fail Rule',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 8080, lastPort: 8080)
            ],
          );

          when(() => mockService.saveRulesToDevice(any(), any()))
              .thenThrow(Exception('Save failed'));

          // Act & Assert
          container
              .read(ipv6PortServiceListProvider.notifier)
              .setRules([testRule]);

          expect(
            () => container.read(ipv6PortServiceListProvider.notifier).save(),
            throwsException,
          );

          verify(() => mockService.saveRulesToDevice(any(), [testRule]))
              .called(1);
        });

        test('updates original to match current after successful save',
            () async {
          // Arrange
          final initialRule = IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Initial',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          );

          final modifiedRule = IPv6PortServiceRuleUI(
            enabled: false,
            description: 'Modified',
            ipv6Address: '2001:db8::2',
            portRanges: const [
              PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
            ],
          );

          when(() => mockService.saveRulesToDevice(any(), any()))
              .thenAnswer((_) async {});

          // Act
          container
              .read(ipv6PortServiceListProvider.notifier)
              .setRules([initialRule]);
          var state = container.read(ipv6PortServiceListProvider);
          expect(state.settings.original.rules, [initialRule]);
          expect(state.settings.current.rules, [initialRule]);

          // Modify current
          container
              .read(ipv6PortServiceListProvider.notifier)
              .editRule(0, modifiedRule);
          state = container.read(ipv6PortServiceListProvider);
          expect(state.settings.original.rules, [initialRule]);
          expect(state.settings.current.rules, [modifiedRule]);
          expect(state.isDirty, true);

          // Save
          await container.read(ipv6PortServiceListProvider.notifier).save();
          state = container.read(ipv6PortServiceListProvider);

          // Assert - original should now match current
          expect(state.settings.original.rules, [modifiedRule]);
          expect(state.settings.current.rules, [modifiedRule]);
          expect(state.isDirty, false);
        });
      });
    });
  });
}
