import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  group('Ipv6PortServiceRuleNotifier', () {
    group('initialization', () {
      test('builds with default empty state', () {
        final state = container.read(ipv6PortServiceRuleProvider);

        expect(state.rules, isEmpty);
        expect(state.rule, isNull);
        expect(state.editIndex, isNull);
      });
    });

    group('init method', () {
      test('sets rules, rule, and editIndex', () {
        final rules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule 1',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
            ],
          ),
        ];
        final rule = rules.first;

        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .init(rules, rule, 0);

        final state = container.read(ipv6PortServiceRuleProvider);
        expect(state.rules, rules);
        expect(state.rule, rule);
        expect(state.editIndex, 0);
      });

      test('can be called with null rule for add operation', () {
        final rules = <IPv6PortServiceRuleUI>[];

        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .init(rules, null, null);

        final state = container.read(ipv6PortServiceRuleProvider);
        expect(state.rule, isNull);
        expect(state.editIndex, isNull);
      });
    });

    group('updateRule', () {
      test('updates current rule', () {
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Updated',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 8080, lastPort: 8080)
          ],
        );

        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(rule);

        final state = container.read(ipv6PortServiceRuleProvider);
        expect(state.rule, rule);
      });

      test('can set rule to null', () {
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Test',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
          ],
        );

        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(rule);
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(null);

        final state = container.read(ipv6PortServiceRuleProvider);
        expect(state.rule, isNull);
      });
    });

    group('isRuleValid', () {
      test('returns false if rule is null', () {
        final notifier = container.read(ipv6PortServiceRuleProvider.notifier);

        expect(notifier.isRuleValid(), false);
      });

      test('returns false if description is empty', () {
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(
              IPv6PortServiceRuleUI(
                enabled: true,
                description: '',
                ipv6Address: '2001:db8::1',
                portRanges: const [
                  PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
                ],
              ),
            );

        expect(
            container.read(ipv6PortServiceRuleProvider.notifier).isRuleValid(),
            false);
      });

      test('returns false if ipv6Address is empty', () {
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(
              IPv6PortServiceRuleUI(
                enabled: true,
                description: 'Test',
                ipv6Address: '',
                portRanges: const [
                  PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
                ],
              ),
            );

        expect(
            container.read(ipv6PortServiceRuleProvider.notifier).isRuleValid(),
            false);
      });

      test('returns false if portRanges is empty', () {
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(
              IPv6PortServiceRuleUI(
                enabled: true,
                description: 'Test',
                ipv6Address: '2001:db8::1',
                portRanges: const [],
              ),
            );

        expect(
            container.read(ipv6PortServiceRuleProvider.notifier).isRuleValid(),
            false);
      });

      test('returns false if port range is invalid', () {
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(
              IPv6PortServiceRuleUI(
                enabled: true,
                description: 'Test',
                ipv6Address: '2001:db8::1',
                portRanges: const [
                  PortRangeUI(protocol: 'TCP', firstPort: 100, lastPort: 50)
                ],
              ),
            );

        expect(
            container.read(ipv6PortServiceRuleProvider.notifier).isRuleValid(),
            false);
      });

      test('returns true for valid complete rule', () {
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(
              IPv6PortServiceRuleUI(
                enabled: true,
                description: 'Valid Rule',
                ipv6Address: '2001:db8::1',
                portRanges: const [
                  PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 8080)
                ],
              ),
            );

        expect(
            container.read(ipv6PortServiceRuleProvider.notifier).isRuleValid(),
            true);
      });

      test('returns true for rule with multiple valid port ranges', () {
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(
              IPv6PortServiceRuleUI(
                enabled: true,
                description: 'Multi Port Rule',
                ipv6Address: '2001:db8::1',
                portRanges: const [
                  PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80),
                  PortRangeUI(protocol: 'TCP', firstPort: 443, lastPort: 443),
                ],
              ),
            );

        expect(
            container.read(ipv6PortServiceRuleProvider.notifier).isRuleValid(),
            true);
      });
    });

    group('isRuleNameValidate', () {
      test('returns false for empty name', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isRuleNameValidate(''),
          false,
        );
      });

      test('returns false for name longer than 32 characters', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isRuleNameValidate('A' * 33),
          false,
        );
      });

      test('returns true for valid name (1-32 chars)', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isRuleNameValidate('Valid Rule'),
          true,
        );
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isRuleNameValidate('A' * 32),
          true,
        );
      });
    });

    group('isDeviceIpValidate', () {
      test('returns true for valid IPv6 address', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isDeviceIpValidate('2001:db8::1'),
          true,
        );
      });

      test('returns false for invalid IPv6 address', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isDeviceIpValidate('not-ipv6'),
          false,
        );
      });

      test('returns false for IPv4 address', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isDeviceIpValidate('192.168.1.1'),
          false,
        );
      });
    });

    group('isPortRangeValid', () {
      test('returns true when firstPort <= lastPort', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortRangeValid(80, 8080),
          true,
        );
      });

      test('returns true when firstPort == lastPort', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortRangeValid(80, 80),
          true,
        );
      });

      test('returns false when firstPort > lastPort', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortRangeValid(8080, 80),
          false,
        );
      });

      test('returns true for boundary values', () {
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortRangeValid(0, 65535),
          true,
        );
      });
    });

    group('isPortConflict', () {
      test('returns false when no rules exist', () {
        container.read(ipv6PortServiceRuleProvider.notifier).updateRule(
              IPv6PortServiceRuleUI(
                enabled: true,
                description: 'Test',
                ipv6Address: '2001:db8::1',
                portRanges: const [
                  PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)
                ],
              ),
            );

        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortConflict(80, 80, 'TCP'),
          false,
        );
      });

      test('detects overlapping port ranges with same protocol', () {
        final rules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule 1',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 100)
            ],
          ),
        ];

        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .init(rules, null, null);
        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .updateRule(rules.first);

        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortConflict(90, 110, 'TCP'),
          true,
        );
      });

      test('allows non-overlapping port ranges', () {
        final rules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Rule 1',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 100)
            ],
          ),
        ];

        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .init(rules, null, null);
        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .updateRule(rules.first);

        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortConflict(200, 300, 'TCP'),
          false,
        );
      });

      test('handles protocol compatibility (TCP and Both overlap)', () {
        final rules = [
          IPv6PortServiceRuleUI(
            enabled: true,
            description: 'Both Rule',
            ipv6Address: '2001:db8::1',
            portRanges: const [
              PortRangeUI(protocol: 'Both', firstPort: 80, lastPort: 100)
            ],
          ),
        ];

        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .init(rules, null, null);
        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .updateRule(rules.first);

        // TCP overlaps with Both
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortConflict(90, 110, 'TCP'),
          true,
        );

        // UDP overlaps with Both
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortConflict(90, 110, 'UDP'),
          true,
        );
      });

      test('skips self when editing existing rule', () {
        final rule = IPv6PortServiceRuleUI(
          enabled: true,
          description: 'Rule 1',
          ipv6Address: '2001:db8::1',
          portRanges: const [
            PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 100)
          ],
        );

        final rules = [rule];

        container
            .read(ipv6PortServiceRuleProvider.notifier)
            .init(rules, rule, 0);

        // Same port range should not conflict with itself when editing
        expect(
          container
              .read(ipv6PortServiceRuleProvider.notifier)
              .isPortConflict(80, 100, 'TCP'),
          false,
        );
      });
    });
  });
}
