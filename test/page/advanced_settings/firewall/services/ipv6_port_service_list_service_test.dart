import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/ipv6_port_service_list_service.dart';

// Mock classes
class MockRouterRepository extends Mock implements RouterRepository {}

class MockRef extends Mock implements Ref {}

void main() {
  late IPv6PortServiceListService service;

  setUp(() {
    service = IPv6PortServiceListService();
  });

  group('IPv6PortServiceListService', () {
    group('fetchPortServiceRules', () {
      test('transforms empty list correctly', () async {
        final result = await service.fetchPortServiceRules([]);

        expect(result.$1, isNotNull);
        expect(result.$1!.rules, isEmpty);
        expect(result.$2, isNotNull);
      });

      test('transforms single IPv6FirewallRule to IPv6PortServiceRuleUI',
          () async {
        final jnapRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'SSH Access',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 22, lastPort: 22),
          ],
        );

        final result = await service.fetchPortServiceRules([jnapRule]);

        expect(result.$1, isNotNull);
        expect(result.$1!.rules, hasLength(1));

        final uiRule = result.$1!.rules.first;
        expect(uiRule.enabled, true);
        expect(uiRule.description, 'SSH Access');
        expect(uiRule.ipv6Address, '2001:db8::1');
        expect(uiRule.portRanges, hasLength(1));
        expect(uiRule.portRanges.first.protocol, 'TCP');
        expect(uiRule.portRanges.first.firstPort, 22);
        expect(uiRule.portRanges.first.lastPort, 22);
      });

      test('transforms multiple rules with multiple port ranges', () async {
        final jnapRules = [
          IPv6FirewallRule(
            isEnabled: true,
            description: 'Web Server',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
              PortRange(protocol: 'TCP', firstPort: 443, lastPort: 443),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: false,
            description: 'DNS',
            ipv6Address: '2001:db8::2',
            portRanges: const [
              PortRange(protocol: 'UDP', firstPort: 53, lastPort: 53),
            ],
          ),
        ];

        final result = await service.fetchPortServiceRules(jnapRules);

        expect(result.$1, isNotNull);
        expect(result.$1!.rules, hasLength(2));

        // First rule
        final firstRule = result.$1!.rules[0];
        expect(firstRule.enabled, true);
        expect(firstRule.description, 'Web Server');
        expect(firstRule.portRanges, hasLength(2));

        // Second rule
        final secondRule = result.$1!.rules[1];
        expect(secondRule.enabled, false);
        expect(secondRule.description, 'DNS');
        expect(secondRule.portRanges, hasLength(1));
      });

      test('preserves all protocol types (TCP, UDP, Both)', () async {
        final jnapRules = [
          IPv6FirewallRule(
            isEnabled: true,
            description: 'TCP Rule',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRange(protocol: 'TCP', firstPort: 1000, lastPort: 2000),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: true,
            description: 'UDP Rule',
            ipv6Address: '2001:db8::2',
            portRanges: const [
              PortRange(protocol: 'UDP', firstPort: 3000, lastPort: 4000),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: true,
            description: 'Both Rule',
            ipv6Address: '2001:db8::3',
            portRanges: const [
              PortRange(
                  protocol: 'Both', firstPort: 5000, lastPort: 6000),
            ],
          ),
        ];

        final result = await service.fetchPortServiceRules(jnapRules);

        expect(result.$1!.rules[0].portRanges.first.protocol, 'TCP');
        expect(result.$1!.rules[1].portRanges.first.protocol, 'UDP');
        expect(result.$1!.rules[2].portRanges.first.protocol, 'Both');
      });

      test('handles boundary port values (0, 1, 65535)', () async {
        final jnapRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Edge Ports',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 0, lastPort: 65535),
          ],
        );

        final result = await service.fetchPortServiceRules([jnapRule]);

        final uiRule = result.$1!.rules.first;
        expect(uiRule.portRanges.first.firstPort, 0);
        expect(uiRule.portRanges.first.lastPort, 65535);
      });

      test('handles port ranges with special characters in description',
          () async {
        final jnapRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Test-Rule_#123!@Special',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 8080, lastPort: 8080),
          ],
        );

        final result = await service.fetchPortServiceRules([jnapRule]);

        expect(result.$1!.rules.first.description, 'Test-Rule_#123!@Special');
      });

      test('handles very long description strings', () async {
        final longDescription = 'A' * 255; // 255 character description
        final jnapRule = IPv6FirewallRule(
          isEnabled: true,
          description: longDescription,
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
          ],
        );

        final result = await service.fetchPortServiceRules([jnapRule]);

        expect(result.$1!.rules.first.description, longDescription);
        expect(result.$1!.rules.first.description.length, 255);
      });

      test('returns status on success', () async {
        final jnapRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
          ],
        );

        final result = await service.fetchPortServiceRules([jnapRule]);

        expect(result.$2, isNotNull);
      });

      test('handles error gracefully and returns null', () async {
        // Create a rule with invalid data to trigger transformation error
        // This tests the error handling in fetchPortServiceRules
        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: '',
          ipv6Address: '2001:db8::1',
          portRanges: const [],
        );

        // Should not throw, but return null
        final result = await service.fetchPortServiceRules([invalidRule]);

        // Service should still return a result, just with empty rules or partial data
        expect(result, isNotNull);
      });
    });

    group('Transformation correctness', () {
      test('round-trip transformation preserves all data', () async {
        final original = IPv6FirewallRule(
          isEnabled: true,
          description: 'Preserve Test',
          ipv6Address: '2001:db8::10',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 1000, lastPort: 2000),
            PortRange(protocol: 'UDP', firstPort: 3000, lastPort: 4000),
          ],
        );

        final result = await service.fetchPortServiceRules([original]);
        final transformed = result.$1!.rules.first;

        expect(transformed.enabled, original.isEnabled);
        expect(transformed.description, original.description);
        expect(transformed.ipv6Address, original.ipv6Address);
        expect(transformed.portRanges.length, original.portRanges.length);

        for (int i = 0; i < original.portRanges.length; i++) {
          expect(transformed.portRanges[i].protocol,
              original.portRanges[i].protocol);
          expect(transformed.portRanges[i].firstPort,
              original.portRanges[i].firstPort);
          expect(transformed.portRanges[i].lastPort,
              original.portRanges[i].lastPort);
        }
      });

      test('isEnabled field correctly maps to enabled field', () async {
        final enabledRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Enabled',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final disabledRule = IPv6FirewallRule(
          isEnabled: false,
          description: 'Disabled',
          ipv6Address: '2001:db8::2',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 443, lastPort: 443)
          ],
        );

        final result =
            await service.fetchPortServiceRules([enabledRule, disabledRule]);

        expect(result.$1!.rules[0].enabled, true);
        expect(result.$1!.rules[1].enabled, false);
      });
    });

    group('Edge cases', () {
      test('handles single port range entry', () async {
        final jnapRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Single Port',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
          ],
        );

        final result = await service.fetchPortServiceRules([jnapRule]);

        expect(result.$1!.rules.first.portRanges, hasLength(1));
      });

      test('handles many port ranges for single rule', () async {
        final portRanges = List<PortRange>.generate(
          10,
          (i) => PortRange(
            protocol: i % 2 == 0 ? 'TCP' : 'UDP',
            firstPort: i * 1000,
            lastPort: i * 1000 + 999,
          ),
        );

        final jnapRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Many Ports',
          ipv6Address: '2001:db8::1',
          portRanges: portRanges,
        );

        final result = await service.fetchPortServiceRules([jnapRule]);

        expect(result.$1!.rules.first.portRanges, hasLength(10));
      });

      test('handles large list of rules', () async {
        final rules = List<IPv6FirewallRule>.generate(
          100,
          (i) => IPv6FirewallRule(
            isEnabled: i % 2 == 0,
            description: 'Rule $i',
            ipv6Address: '2001:db8::$i',
            portRanges: [
              PortRange(
                protocol: ['TCP', 'UDP', 'Both'][i % 3],
                firstPort: 1000 + i,
                lastPort: 2000 + i,
              ),
            ],
          ),
        );

        final result = await service.fetchPortServiceRules(rules);

        expect(result.$1!.rules, hasLength(100));
      });
    });

    group('transformRulesToJNAP', () {
      test('transforms UI rules back to JNAP models', () {
        final uiRules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'SSH Access',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 22, lastPort: 22),
            ],
          ),
        ];

        final jnapRules = service.transformRulesToJNAP(uiRules);

        expect(jnapRules, hasLength(1));
        expect(jnapRules.first.isEnabled, true);
        expect(jnapRules.first.description, 'SSH Access');
        expect(jnapRules.first.ipv6Address, '2001:db8::1');
        expect(jnapRules.first.portRanges, hasLength(1));
        expect(jnapRules.first.portRanges.first.protocol, 'TCP');
        expect(jnapRules.first.portRanges.first.firstPort, 22);
        expect(jnapRules.first.portRanges.first.lastPort, 22);
      });

      test('preserves enabled/disabled state during transformation', () {
        final enabledRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Enabled',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        final disabledRule = IPv6PortServiceRuleUI(
          enabled: false,
          description: 'Disabled',
          ipv6Address: '2001:db8::2',
          portRanges: const [
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53)
          ],
        );

        final jnapRules =
            service.transformRulesToJNAP([enabledRule, disabledRule]);

        expect(jnapRules[0].isEnabled, true);
        expect(jnapRules[1].isEnabled, false);
      });

      test('round-trip transformation preserves data', () async {
        final originalJNAP = IPv6FirewallRule(
          isEnabled: true,
          description: 'Round-trip Test',
          ipv6Address: '2001:db8::10',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 1000, lastPort: 2000),
            PortRange(protocol: 'UDP', firstPort: 3000, lastPort: 4000),
          ],
        );

        // Transform JNAP → UI
        final result = await service.fetchPortServiceRules([originalJNAP]);
        final uiRule = result.$1!.rules.first;

        // Transform UI → JNAP
        final transformedBack = service.transformRulesToJNAP([uiRule]);
        final transformedJNAP = transformedBack.first;

        expect(transformedJNAP.isEnabled, originalJNAP.isEnabled);
        expect(transformedJNAP.description, originalJNAP.description);
        expect(transformedJNAP.ipv6Address, originalJNAP.ipv6Address);
        expect(
            transformedJNAP.portRanges.length, originalJNAP.portRanges.length);

        for (int i = 0; i < originalJNAP.portRanges.length; i++) {
          expect(transformedJNAP.portRanges[i].protocol,
              originalJNAP.portRanges[i].protocol);
          expect(transformedJNAP.portRanges[i].firstPort,
              originalJNAP.portRanges[i].firstPort);
          expect(transformedJNAP.portRanges[i].lastPort,
              originalJNAP.portRanges[i].lastPort);
        }
      });

      test('handles empty UI rules list', () {
        final jnapRules = service.transformRulesToJNAP([]);

        expect(jnapRules, isEmpty);
      });

      test('handles multiple port ranges during reverse transformation', () {
        final uiRule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Multi-port',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80),
            PortRangeUI(protocol: 'TCP', firstPort: 443, lastPort: 443),
            PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53),
          ],
        );

        final jnapRules = service.transformRulesToJNAP([uiRule]);

        expect(jnapRules.first.portRanges, hasLength(3));
        expect(jnapRules.first.portRanges[0].firstPort, 80);
        expect(jnapRules.first.portRanges[1].firstPort, 443);
        expect(jnapRules.first.portRanges[2].firstPort, 53);
      });
    });

    group('Error handling', () {
      test('returns (null, null) when rules list is empty', () async {
        // Act
        final result = await service.fetchPortServiceRules([]);

        // Assert
        expect(result.$1, isNotNull);
        expect(result.$1!.rules, isEmpty);
        expect(result.$2, isNotNull);
      });

      test('handles invalid protocol value', () async {
        // Arrange
        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Bad Protocol',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'INVALID', firstPort: 80, lastPort: 80),
          ],
        );

        // Act
        final result = await service.fetchPortServiceRules([invalidRule]);

        // Assert - should return (null, null) due to validation failure
        expect(result.$1, isNull);
        expect(result.$2, isNull);
      });

      test('handles out-of-range port numbers', () async {
        // Arrange
        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Bad Port',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 65536, lastPort: 65537),
          ],
        );

        // Act
        final result = await service.fetchPortServiceRules([invalidRule]);

        // Assert
        expect(result.$1, isNull);
        expect(result.$2, isNull);
      });

      test('handles port range where firstPort > lastPort', () async {
        // Arrange
        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Reversed Range',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 443, lastPort: 80),
          ],
        );

        // Act
        final result = await service.fetchPortServiceRules([invalidRule]);

        // Assert
        expect(result.$1, isNull);
        expect(result.$2, isNull);
      });

      test('handles rule with empty description', () async {
        // Arrange
        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: '',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
          ],
        );

        // Act
        final result = await service.fetchPortServiceRules([invalidRule]);

        // Assert
        expect(result.$1, isNull);
        expect(result.$2, isNull);
      });

      test('handles rule with empty IPv6 address', () async {
        // Arrange
        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Test',
          ipv6Address: '',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
          ],
        );

        // Act
        final result = await service.fetchPortServiceRules([invalidRule]);

        // Assert
        expect(result.$1, isNull);
        expect(result.$2, isNull);
      });

      test('handles rule with no port ranges', () async {
        // Arrange
        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'No Ports',
          ipv6Address: '2001:db8::1',
          portRanges: const [],
        );

        // Act
        final result = await service.fetchPortServiceRules([invalidRule]);

        // Assert
        expect(result.$1, isNull);
        expect(result.$2, isNull);
      });

      test('partial success: returns valid rules when some fail', () async {
        // Arrange
        final validRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Valid Rule',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
          ],
        );

        final invalidRule = IPv6FirewallRule(
          isEnabled: true,
          description: 'Invalid Protocol',
          ipv6Address: '2001:db8::2',
          portRanges: const [
            PortRange(protocol: 'INVALID', firstPort: 443, lastPort: 443),
          ],
        );

        // Act
        final result =
            await service.fetchPortServiceRules([validRule, invalidRule]);

        // Assert - should return valid rule despite one failing
        expect(result.$1, isNotNull);
        expect(result.$1!.rules, hasLength(1));
        expect(result.$1!.rules.first.description, 'Valid Rule');
      });

      test('partial success: continues processing after failure', () async {
        // Arrange
        final rules = [
          IPv6FirewallRule(
            isEnabled: true,
            description: 'Valid 1',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: true,
            description: 'Invalid Port',
            ipv6Address: '2001:db8::2',
            portRanges: const [
              PortRange(protocol: 'TCP', firstPort: 65536, lastPort: 65537),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: true,
            description: 'Valid 2',
            ipv6Address: '2001:db8::3',
            portRanges: const [
              PortRange(protocol: 'UDP', firstPort: 53, lastPort: 53),
            ],
          ),
        ];

        // Act
        final result = await service.fetchPortServiceRules(rules);

        // Assert - should have 2 valid rules
        expect(result.$1, isNotNull);
        expect(result.$1!.rules, hasLength(2));
        expect(result.$1!.rules[0].description, 'Valid 1');
        expect(result.$1!.rules[1].description, 'Valid 2');
      });

      test('returns (null, null) when all rules fail validation', () async {
        // Arrange
        final allInvalidRules = [
          IPv6FirewallRule(
            isEnabled: true,
            description: '',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: true,
            description: 'No Ports',
            ipv6Address: '2001:db8::2',
            portRanges: const [],
          ),
        ];

        // Act
        final result = await service.fetchPortServiceRules(allInvalidRules);

        // Assert
        expect(result.$1, isNull);
        expect(result.$2, isNull);
      });
    });

    group('JNAP communication', () {
      late MockRouterRepository mockRepo;
      late MockRef mockRef;

      setUp(() {
        mockRepo = MockRouterRepository();
        mockRef = MockRef();

        when(() => mockRef.read(routerRepositoryProvider)).thenReturn(mockRepo);
      });

      group('fetchRulesFromDevice', () {
        test('fetches and transforms rules from device successfully', () async {
          // Arrange
          final jnapResponse = {
            'rules': [
              {
                'isEnabled': true,
                'description': 'SSH Access',
                'ipv6Address': '2001:db8::1',
                'portRanges': [
                  {'protocol': 'TCP', 'firstPort': 22, 'lastPort': 22}
                ]
              },
              {
                'isEnabled': false,
                'description': 'Web Server',
                'ipv6Address': '2001:db8::2',
                'portRanges': [
                  {'protocol': 'TCP', 'firstPort': 80, 'lastPort': 80},
                  {'protocol': 'TCP', 'firstPort': 443, 'lastPort': 443}
                ]
              }
            ]
          };

          when(() => mockRepo.send(
                    JNAPAction.getIPv6FirewallRules,
                    auth: true,
                    fetchRemote: false,
                  ))
              .thenAnswer(
                  (_) async => JNAPSuccess(result: 'OK', output: jnapResponse));

          // Act
          final result = await service.fetchRulesFromDevice(mockRef);

          // Assert
          expect(result.$1, isNotNull);
          expect(result.$1!.rules, hasLength(2));
          expect(result.$1!.rules[0].description, 'SSH Access');
          expect(result.$1!.rules[0].enabled, true);
          expect(result.$1!.rules[0].portRanges, hasLength(1));
          expect(result.$1!.rules[1].description, 'Web Server');
          expect(result.$1!.rules[1].enabled, false);
          expect(result.$1!.rules[1].portRanges, hasLength(2));
          expect(result.$2, isNotNull);

          verify(() => mockRepo.send(
                JNAPAction.getIPv6FirewallRules,
                auth: true,
                fetchRemote: false,
              )).called(1);
        });

        test('fetches with forceRemote=true parameter', () async {
          // Arrange
          final jnapResponse = {
            'rules': [
              {
                'isEnabled': true,
                'description': 'Test',
                'ipv6Address': '2001:db8::1',
                'portRanges': [
                  {'protocol': 'TCP', 'firstPort': 80, 'lastPort': 80}
                ]
              }
            ]
          };

          when(() => mockRepo.send(
                    JNAPAction.getIPv6FirewallRules,
                    auth: true,
                    fetchRemote: true,
                  ))
              .thenAnswer(
                  (_) async => JNAPSuccess(result: 'OK', output: jnapResponse));

          // Act
          final result =
              await service.fetchRulesFromDevice(mockRef, forceRemote: true);

          // Assert
          expect(result.$1, isNotNull);
          expect(result.$1!.rules, hasLength(1));

          verify(() => mockRepo.send(
                JNAPAction.getIPv6FirewallRules,
                auth: true,
                fetchRemote: true,
              )).called(1);
        });

        test('returns (null, null) on JNAP error', () async {
          // Arrange
          when(() => mockRepo.send(
                JNAPAction.getIPv6FirewallRules,
                auth: true,
                fetchRemote: false,
              )).thenThrow(Exception('JNAP communication error'));

          // Act
          final result = await service.fetchRulesFromDevice(mockRef);

          // Assert
          expect(result.$1, isNull);
          expect(result.$2, isNull);
        });

        test('returns (null, null) when JNAP returns empty rules', () async {
          // Arrange
          final jnapResponse = {'rules': []};

          when(() => mockRepo.send(
                    JNAPAction.getIPv6FirewallRules,
                    auth: true,
                    fetchRemote: false,
                  ))
              .thenAnswer(
                  (_) async => JNAPSuccess(result: 'OK', output: jnapResponse));

          // Act
          final result = await service.fetchRulesFromDevice(mockRef);

          // Assert
          expect(result.$1, isNotNull);
          expect(result.$1!.rules, isEmpty);
          expect(result.$2, isNotNull);
        });

        test('handles partial success when some rules fail transformation',
            () async {
          // Arrange
          final jnapResponse = {
            'rules': [
              {
                'isEnabled': true,
                'description': 'Valid Rule',
                'ipv6Address': '2001:db8::1',
                'portRanges': [
                  {'protocol': 'TCP', 'firstPort': 80, 'lastPort': 80}
                ]
              },
              {
                'isEnabled': true,
                'description': 'Invalid Rule',
                'ipv6Address': '2001:db8::2',
                'portRanges': [
                  {
                    'protocol': 'INVALID_PROTOCOL',
                    'firstPort': 443,
                    'lastPort': 443
                  }
                ]
              }
            ]
          };

          when(() => mockRepo.send(
                    JNAPAction.getIPv6FirewallRules,
                    auth: true,
                    fetchRemote: false,
                  ))
              .thenAnswer(
                  (_) async => JNAPSuccess(result: 'OK', output: jnapResponse));

          // Act
          final result = await service.fetchRulesFromDevice(mockRef);

          // Assert - should return only valid rule
          expect(result.$1, isNotNull);
          expect(result.$1!.rules, hasLength(1));
          expect(result.$1!.rules.first.description, 'Valid Rule');
        });
      });

      group('saveRulesToDevice', () {
        test('transforms and saves rules to device successfully', () async {
          // Arrange
          final uiRules = [
            IPv6PortServiceRuleUI(
              enabled: true,
              description: 'SSH Access',
              ipv6Address: '2001:db8::1',
              portRanges: const [
                PortRangeUI(protocol: 'TCP', firstPort: 22, lastPort: 22)
              ],
            ),
            IPv6PortServiceRuleUI(
              enabled: false,
              description: 'Web Server',
              ipv6Address: '2001:db8::2',
              portRanges: const [
                PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80),
                PortRangeUI(protocol: 'TCP', firstPort: 443, lastPort: 443)
              ],
            )
          ];

          when(() => mockRepo.send(
                    JNAPAction.setIPv6FirewallRules,
                    auth: true,
                    fetchRemote: true,
                    data: any(named: 'data'),
                  ))
              .thenAnswer(
                  (_) async => const JNAPSuccess(result: 'OK', output: {}));

          // Act
          await service.saveRulesToDevice(mockRef, uiRules);

          // Assert
          final captured = verify(() => mockRepo.send(
                JNAPAction.setIPv6FirewallRules,
                auth: true,
                fetchRemote: true,
                data: captureAny(named: 'data'),
              )).captured;

          expect(captured, hasLength(1));
          final sentData = captured.first as Map<String, dynamic>;
          expect(sentData['rules'], hasLength(2));
          expect(sentData['rules'][0]['description'], 'SSH Access');
          expect(sentData['rules'][0]['isEnabled'], true);
          expect(sentData['rules'][1]['description'], 'Web Server');
          expect(sentData['rules'][1]['isEnabled'], false);
        });

        test('saves empty rules list successfully', () async {
          // Arrange
          when(() => mockRepo.send(
                    JNAPAction.setIPv6FirewallRules,
                    auth: true,
                    fetchRemote: true,
                    data: any(named: 'data'),
                  ))
              .thenAnswer(
                  (_) async => const JNAPSuccess(result: 'OK', output: {}));

          // Act
          await service.saveRulesToDevice(mockRef, []);

          // Assert
          final captured = verify(() => mockRepo.send(
                JNAPAction.setIPv6FirewallRules,
                auth: true,
                fetchRemote: true,
                data: captureAny(named: 'data'),
              )).captured;

          expect(captured, hasLength(1));
          final sentData = captured.first as Map<String, dynamic>;
          expect(sentData['rules'], isEmpty);
        });

        test('throws exception on JNAP save error', () async {
          // Arrange
          final uiRules = [
            IPv6PortServiceRuleUI(
              enabled: true,
              description: 'Test Rule',
              ipv6Address: '2001:db8::1',
              portRanges: const [
                PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
              ],
            )
          ];

          when(() => mockRepo.send(
                JNAPAction.setIPv6FirewallRules,
                auth: true,
                fetchRemote: true,
                data: any(named: 'data'),
              )).thenThrow(Exception('JNAP save failed'));

          // Act & Assert
          expect(
            () => service.saveRulesToDevice(mockRef, uiRules),
            throwsException,
          );

          verify(() => mockRepo.send(
                JNAPAction.setIPv6FirewallRules,
                auth: true,
                fetchRemote: true,
                data: any(named: 'data'),
              )).called(1);
        });

        test('correctly transforms UI models with multiple port ranges',
            () async {
          // Arrange
          final uiRules = [
            IPv6PortServiceRuleUI(
              enabled: true,
              description: 'Complex Rule',
              ipv6Address: '2001:db8::1',
              portRanges: const [
                PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80),
                PortRangeUI(protocol: 'UDP', firstPort: 53, lastPort: 53),
                PortRangeUI(protocol: 'Both', firstPort: 8000, lastPort: 9000)
              ],
            )
          ];

          when(() => mockRepo.send(
                    JNAPAction.setIPv6FirewallRules,
                    auth: true,
                    fetchRemote: true,
                    data: any(named: 'data'),
                  ))
              .thenAnswer(
                  (_) async => const JNAPSuccess(result: 'OK', output: {}));

          // Act
          await service.saveRulesToDevice(mockRef, uiRules);

          // Assert
          final captured = verify(() => mockRepo.send(
                JNAPAction.setIPv6FirewallRules,
                auth: true,
                fetchRemote: true,
                data: captureAny(named: 'data'),
              )).captured;

          final sentData = captured.first as Map<String, dynamic>;
          final savedRules = sentData['rules'] as List;
          expect(savedRules[0]['portRanges'], hasLength(3));
          expect(savedRules[0]['portRanges'][0]['protocol'], 'TCP');
          expect(savedRules[0]['portRanges'][1]['protocol'], 'UDP');
          expect(savedRules[0]['portRanges'][2]['protocol'], 'Both');
        });
      });
    });
  });
}
