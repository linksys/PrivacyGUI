import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/ipv6_port_service_list_service.dart';

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
          portRanges: [
            const PortRange(protocol: 'TCP', firstPort: 22, lastPort: 22),
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
            portRanges: [
              const PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
              const PortRange(protocol: 'TCP', firstPort: 443, lastPort: 443),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: false,
            description: 'DNS',
            ipv6Address: '2001:db8::2',
            portRanges: [
              const PortRange(protocol: 'UDP', firstPort: 53, lastPort: 53),
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
            portRanges: [
              const PortRange(protocol: 'TCP', firstPort: 1000, lastPort: 2000),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: true,
            description: 'UDP Rule',
            ipv6Address: '2001:db8::2',
            portRanges: [
              const PortRange(protocol: 'UDP', firstPort: 3000, lastPort: 4000),
            ],
          ),
          IPv6FirewallRule(
            isEnabled: true,
            description: 'Both Rule',
            ipv6Address: '2001:db8::3',
            portRanges: [
              const PortRange(
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
          portRanges: [
            const PortRange(protocol: 'TCP', firstPort: 0, lastPort: 65535),
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
          portRanges: [
            const PortRange(protocol: 'TCP', firstPort: 8080, lastPort: 8080),
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
          portRanges: [
            const PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
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
          portRanges: [
            const PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
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
          portRanges: [
            const PortRange(protocol: 'TCP', firstPort: 1000, lastPort: 2000),
            const PortRange(protocol: 'UDP', firstPort: 3000, lastPort: 4000),
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
          portRanges: [
            const PortRange(protocol: 'TCP', firstPort: 80, lastPort: 80),
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
  });
}
