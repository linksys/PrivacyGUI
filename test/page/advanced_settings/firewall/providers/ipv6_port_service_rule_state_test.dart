import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

void main() {
  group('PortRangeUI', () {
    group('creation and equality', () {
      test('creates PortRangeUI with all fields', () {
        const portRange = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );

        expect(portRange.protocol, 'TCP');
        expect(portRange.firstPort, 80);
        expect(portRange.lastPort, 8080);
      });

      test('supports value equality', () {
        const portRange1 = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );
        const portRange2 = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );

        expect(portRange1, portRange2);
      });

      test('distinguishes different protocols', () {
        const portRange1 = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );
        const portRange2 = PortRangeUI(
          protocol: 'UDP',
          firstPort: 80,
          lastPort: 8080,
        );

        expect(portRange1, isNot(portRange2));
      });
    });

    group('copyWith', () {
      test('copies with protocol override', () {
        const original = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );

        final copied = original.copyWith(protocol: 'UDP');

        expect(copied.protocol, 'UDP');
        expect(copied.firstPort, 80);
        expect(copied.lastPort, 8080);
      });

      test('copies with port override', () {
        const original = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );

        final copied = original.copyWith(firstPort: 443, lastPort: 443);

        expect(copied.protocol, 'TCP');
        expect(copied.firstPort, 443);
        expect(copied.lastPort, 443);
      });
    });

    group('serialization', () {
      test('converts to Map', () {
        const portRange = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );

        final map = portRange.toMap();

        expect(map['protocol'], 'TCP');
        expect(map['firstPort'], 80);
        expect(map['lastPort'], 8080);
      });

      test('creates from Map', () {
        const expected = PortRangeUI(
          protocol: 'TCP',
          firstPort: 80,
          lastPort: 8080,
        );

        final portRange = PortRangeUI.fromMap({
          'protocol': 'TCP',
          'firstPort': 80,
          'lastPort': 8080,
        });

        expect(portRange, expected);
      });

      test('round-trip serialization preserves data', () {
        const original = PortRangeUI(
          protocol: 'Both',
          firstPort: 1000,
          lastPort: 2000,
        );

        final map = original.toMap();
        final restored = PortRangeUI.fromMap(map);

        expect(restored, original);
      });
    });
  });

  group('IPv6PortServiceRuleUI', () {
    group('creation and equality', () {
      test('creates rule with all fields', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'SSH Access',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 22, lastPort: 22)
          ],
        );

        expect(rule.enabled, true);
        expect(rule.description, 'SSH Access');
        expect(rule.ipv6Address, '2001:db8::1');
        expect(rule.portRanges, hasLength(1));
      });

      test('supports value equality', () {
        const rule1 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const rule2 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        expect(rule1, rule2);
      });

      test('distinguishes different descriptions', () {
        const rule1 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test1',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const rule2 = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test2',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        expect(rule1, isNot(rule2));
      });
    });

    group('copyWith', () {
      test('copies with description override', () {
        const original = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Original',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final copied = original.copyWith(description: 'Updated');

        expect(copied.description, 'Updated');
        expect(copied.enabled, true);
        expect(copied.ipv6Address, '2001:db8::1');
      });

      test('copies with multiple field overrides', () {
        const original = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Original',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final newPortRanges = [
          const PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53),
        ];

        final copied = original.copyWith(
          enabled: false,
          ipv6Address: '2001:db8::2',
          portRanges: newPortRanges,
        );

        expect(copied.enabled, false);
        expect(copied.ipv6Address, '2001:db8::2');
        expect(copied.portRanges, newPortRanges);
      });
    });

    group('serialization', () {
      test('converts to Map with port ranges', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80),
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53),
          ],
        );

        final map = rule.toMap();

        expect(map['enabled'], true);
        expect(map['description'], 'Test');
        expect(map['ipv6Address'], '2001:db8::1');
        expect(map['portRanges'], hasLength(2));
      });

      test('creates from Map', () {
        const expected = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final rule = IPv6PortServiceRuleUI.fromMap({
          'enabled': true,
          'description': 'Test',
          'ipv6Address': '2001:db8::1',
          'portRanges': [
            {'protocol': 'TCP', 'firstPort': 80, 'lastPort': 80}
          ],
        });

        expect(rule, expected);
      });

      test('round-trip serialization preserves all data', () {
        const original = IPv6PortServiceRuleUI(
          enabled: false,
          description: 'Complete Test',
          ipv6Address: '2001:db8::10',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 1000, lastPort: 2000),
            PortRangeUI(protocol: 'UDP', firstPort: 3000, lastPort: 4000),
          ],
        );

        final map = original.toMap();
        final restored = IPv6PortServiceRuleUI.fromMap(map);

        expect(restored, original);
      });

      test('handles JSON serialization', () {
        const original = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'JSON Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final json = original.toJson();
        final restored = IPv6PortServiceRuleUI.fromJson(json);

        expect(restored, original);
      });

      test('handles empty port ranges during serialization', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'No Ports',
          ipv6Address: '2001:db8::1',
          portRanges: [],
        );

        final map = rule.toMap();
        final restored = IPv6PortServiceRuleUI.fromMap(map);

        expect(restored.portRanges, isEmpty);
        expect(restored, rule);
      });
    });

    group('edge cases', () {
      test('handles rule with many port ranges', () {
        final portRanges = List<PortRangeUI>.generate(
          10,
          (i) => PortRangeUI(
            protocol: i % 2 == 0 ? 'TCP' : 'UDP',
            firstPort: i * 1000,
            lastPort: i * 1000 + 999,
          ),
        );

        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Many Ports',
          ipv6Address: '2001:db8::1',
          portRanges: [],
        );

        final ruleWithPorts = rule.copyWith(portRanges: portRanges);

        expect(ruleWithPorts.portRanges, hasLength(10));

        final map = ruleWithPorts.toMap();
        final restored = IPv6PortServiceRuleUI.fromMap(map);

        expect(restored.portRanges, hasLength(10));
      });

      test('handles boundary port values', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Boundary Ports',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 0, lastPort: 65535),
          ],
        );

        final map = rule.toMap();
        final restored = IPv6PortServiceRuleUI.fromMap(map);

        expect(restored.portRanges.first.firstPort, 0);
        expect(restored.portRanges.first.lastPort, 65535);
      });

      test('handles special characters in description', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test-Rule_#123!@Special',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final map = rule.toMap();
        final restored = IPv6PortServiceRuleUI.fromMap(map);

        expect(restored.description, 'Test-Rule_#123!@Special');
      });
    });
  });

  group('IPv6PortServiceRuleUIList', () {
    group('creation and equality', () {
      test('creates list with rules', () {
        const list = IPv6PortServiceRuleUIList(rules: [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule 1',
            ipv6Address: '2001:db8::1',
            portRanges: [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        ]);

        expect(list.rules, hasLength(1));
      });

      test('supports value equality', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const list1 = IPv6PortServiceRuleUIList(rules: [rule]);
        const list2 = IPv6PortServiceRuleUIList(rules: [rule]);

        expect(list1, list2);
      });
    });

    group('copyWith', () {
      test('copies with new rules', () {
        const originalRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Original',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const originalList = IPv6PortServiceRuleUIList(rules: [originalRule]);

        const newRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'New Rule',
          ipv6Address: '2001:db8::2',
          portRanges: [
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
          ],
        );
        final newList = originalList.copyWith(rules: [originalRule, newRule]);

        expect(newList.rules, hasLength(2));
      });
    });

    group('serialization', () {
      test('converts to Map', () {
        const list = IPv6PortServiceRuleUIList(rules: [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Test',
            ipv6Address: '2001:db8::1',
            portRanges: [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        ]);

        final map = list.toMap();

        expect(map['rules'], isA<List>());
        expect(map['rules'], hasLength(1));
      });

      test('creates from Map', () {
        const expected = IPv6PortServiceRuleUIList(rules: [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Test',
            ipv6Address: '2001:db8::1',
            portRanges: [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        ]);

        final list = IPv6PortServiceRuleUIList.fromMap({
          'rules': [
            {
              'enabled': true,
              'description': 'Test',
              'ipv6Address': '2001:db8::1',
              'portRanges': [
                {'protocol': 'TCP', 'firstPort': 80, 'lastPort': 80}
              ],
            }
          ],
        });

        expect(list, expected);
      });

      test('round-trip serialization preserves data', () {
        const original = IPv6PortServiceRuleUIList(rules: [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule 1',
            ipv6Address: '2001:db8::1',
            portRanges: [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
          IPv6PortServiceRuleUI(
            enabled: false,
            description: 'Rule 2',
            ipv6Address: '2001:db8::2',
            portRanges: [
              PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
            ],
          ),
        ]);

        final map = original.toMap();
        final restored = IPv6PortServiceRuleUIList.fromMap(map);

        expect(restored, original);
      });

      test('handles JSON serialization', () {
        const original = IPv6PortServiceRuleUIList(rules: [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Test',
            ipv6Address: '2001:db8::1',
            portRanges: [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        ]);

        final json = original.toJson();
        final restored = IPv6PortServiceRuleUIList.fromJson(json);

        expect(restored, original);
      });
    });

    group('edge cases', () {
      test('handles empty rule list', () {
        const list = IPv6PortServiceRuleUIList(rules: []);

        expect(list.rules, isEmpty);

        final map = list.toMap();
        final restored = IPv6PortServiceRuleUIList.fromMap(map);

        expect(restored.rules, isEmpty);
      });

      test('handles large number of rules', () {
        final rules = List<IPv6PortServiceRuleUI>.generate(
          100,
          (i) => IPv6PortServiceRuleUI(
            enabled: i % 2 == 0,
            description: 'Rule $i',
            ipv6Address: '2001:db8::$i',
            portRanges: [
              PortRangeUI(
                protocol: ['TCP', 'UDP', 'Both'][i % 3],
                firstPort: 1000 + i,
                lastPort: 2000 + i,
              ),
            ],
          ),
        );

        final list = IPv6PortServiceRuleUIList(rules: rules);

        expect(list.rules, hasLength(100));

        final map = list.toMap();
        final restored = IPv6PortServiceRuleUIList.fromMap(map);

        expect(restored.rules, hasLength(100));
      });
    });
  });

  group('Ipv6PortServiceRuleState', () {
    group('creation and equality', () {
      test('creates state with default values', () {
        const state = Ipv6PortServiceRuleState();

        expect(state.rules, isEmpty);
        expect(state.rule, isNull);
        expect(state.editIndex, isNull);
      });

      test('creates state with all fields', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const state = Ipv6PortServiceRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        expect(state.rules, hasLength(1));
        expect(state.rule, rule);
        expect(state.editIndex, 0);
      });

      test('supports value equality', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const state1 = Ipv6PortServiceRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );
        const state2 = Ipv6PortServiceRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        expect(state1, state2);
      });
    });

    group('copyWith', () {
      test('copies with rule override', () {
        const originalRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Original',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const originalState = Ipv6PortServiceRuleState(
          rules: [originalRule],
          rule: originalRule,
          editIndex: 0,
        );

        const newRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Updated',
          ipv6Address: '2001:db8::2',
          portRanges: [
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
          ],
        );

        final newState = originalState.copyWith(
          rule: () => newRule,
        );

        expect(newState.rule, newRule);
        expect(newState.rules, originalState.rules);
        expect(newState.editIndex, originalState.editIndex);
      });

      test('copies with null rule', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const originalState = Ipv6PortServiceRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final newState = originalState.copyWith(rule: () => null);

        expect(newState.rule, isNull);
      });

      test('copies with editIndex override', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const originalState = Ipv6PortServiceRuleState(
          rules: [rule, rule],
          rule: rule,
          editIndex: 0,
        );

        final newState = originalState.copyWith(editIndex: () => 1);

        expect(newState.editIndex, 1);
        expect(newState.rule, rule);
      });
    });

    group('serialization', () {
      test('converts to Map', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const state = Ipv6PortServiceRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final map = state.toMap();

        expect(map['rules'], isA<List>());
        expect(map['rule'], isA<Map>());
        expect(map['editIndex'], 0);
      });

      test('round-trip serialization preserves data', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const original = Ipv6PortServiceRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final map = original.toMap();
        final restored = Ipv6PortServiceRuleState.fromMap(map);

        expect(restored.rules, original.rules);
        expect(restored.rule, original.rule);
        expect(restored.editIndex, original.editIndex);
      });

      test('handles JSON serialization', () {
        const rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );
        const original = Ipv6PortServiceRuleState(
          rules: [rule],
          rule: rule,
          editIndex: 0,
        );

        final json = original.toJson();
        final restored = Ipv6PortServiceRuleState.fromJson(json);

        expect(restored.rules, original.rules);
        expect(restored.rule, original.rule);
        expect(restored.editIndex, original.editIndex);
      });
    });

    group('edge cases', () {
      test('handles state with null rule and editIndex', () {
        const state = Ipv6PortServiceRuleState(
          rules: [],
          rule: null,
          editIndex: null,
        );

        expect(state.rule, isNull);
        expect(state.editIndex, isNull);

        final map = state.toMap();
        final restored = Ipv6PortServiceRuleState.fromMap(map);

        expect(restored.rule, isNull);
        expect(restored.editIndex, isNull);
      });

      test('handles state with many rules', () {
        final rules = List<IPv6PortServiceRuleUI>.generate(
          50,
          (i) => IPv6PortServiceRuleUI(
            enabled: i % 2 == 0,
            description: 'Rule $i',
            ipv6Address: '2001:db8::$i',
            portRanges: [
              PortRangeUI(
                protocol: ['TCP', 'UDP', 'Both'][i % 3],
                firstPort: 1000 + i,
                lastPort: 2000 + i,
              ),
            ],
          ),
        );

        const state = Ipv6PortServiceRuleState(
          rules: [],
          rule: null,
          editIndex: null,
        );

        final stateWithRules = state.copyWith(
          rules: rules,
        );

        expect(stateWithRules.rules, hasLength(50));
      });
    });
  });
}
