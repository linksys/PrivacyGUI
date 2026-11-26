import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';

import '../../../../common/router_boundary.dart';
import '../../../../test_data/ipv6_port_service_list_test_state.dart';

/// The two rules of the router-shaped test data: "222" and "777".
final _first = Map<String, dynamic>.from(
    (ipv6PortServiceListTestState['rules'] as List)[0] as Map);
final _second = Map<String, dynamic>.from(
    (ipv6PortServiceListTestState['rules'] as List)[1] as Map);

/// `GetIPv6FirewallRules` output holding [rules], with the test data's
/// limits: 15 rules of 64 characters.
Map<String, dynamic> _rules(List<Map<String, dynamic>> rules) =>
    {...ipv6PortServiceListTestState, 'rules': rules};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late Ipv6PortServiceListNotifier notifier;

  Ipv6PortServiceListState page() =>
      container.read(ipv6PortServiceListProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getIPv6FirewallRules, _rules([_first, _second]));
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(ipv6PortServiceListProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('lists the rules the router holds, with its limits', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(page().rules, [
        IPv6FirewallRule.fromMap(_first),
        IPv6FirewallRule.fromMap(_second)
      ]);
      expect(page().maxRules, 15);
      expect(page().maxDescriptionLength, 64);
    });

    test('falls back to 50 rules of 32 characters when the router omits them',
        () async {
      router.holds(JNAPAction.getIPv6FirewallRules, {'rules': []});

      await notifier.fetch();

      expect(page().maxRules, 50);
      expect(page().maxDescriptionLength, 32);
    });

    test('reports a read the router refuses, and keeps what it showed',
        () async {
      await notifier.fetch();
      router.refuses(JNAPAction.getIPv6FirewallRules);

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page().rules, [
        IPv6FirewallRule.fromMap(_first),
        IPv6FirewallRule.fromMap(_second)
      ]);
      expect(page().maxRules, 15);
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router.sent.clear();
    });

    test('writes the rules the user kept, without the one they deleted',
        () async {
      notifier.deleteRule(IPv6FirewallRule.fromMap(_second));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setIPv6FirewallRules).single, {
        'rules': [_first],
      });
    });

    test('reads the rules back from the router after the write', () async {
      router.holds(JNAPAction.getIPv6FirewallRules, _rules([_second]));

      final saved = await notifier.save();

      expect(router.actions,
          [JNAPAction.setIPv6FirewallRules, JNAPAction.getIPv6FirewallRules]);
      expect(saved.rules, [IPv6FirewallRule.fromMap(_second)]);
      expect(page().rules, saved.rules);
    });

    test('reports a write the router refuses, and keeps the user edit',
        () async {
      router.refuses(JNAPAction.setIPv6FirewallRules,
          result: 'ErrorRulesOverlap');
      notifier.deleteRule(IPv6FirewallRule.fromMap(_second));

      await expectLater(
        notifier.save(),
        throwsA(isA<JNAPError>()
            .having((error) => error.result, 'result', 'ErrorRulesOverlap')),
      );

      expect(router.actions, [JNAPAction.setIPv6FirewallRules]);
      expect(page().rules, [IPv6FirewallRule.fromMap(_first)]);
    });
  });

  group('editing the list', () {
    setUp(() => notifier.fetch());

    final added = IPv6FirewallRule.fromMap(const {
      'isEnabled': true,
      'ipv6Address': '2001:db8::30',
      'portRanges': [
        {'protocol': 'Both', 'firstPort': 8080, 'lastPort': 8080},
      ],
      'description': 'Web',
    });

    test('adds a rule at the end', () {
      notifier.addRule(added);

      expect(page().rules.last, added);
      expect(page().rules, hasLength(3));
    });

    test('replaces a rule in place', () {
      notifier.editRule(0, added);

      expect(page().rules, [added, IPv6FirewallRule.fromMap(_second)]);
    });

    test('is full once it holds as many rules as the router allows', () {
      expect(notifier.isExceedMax(), isFalse);

      for (var i = 0; i < 13; i++) {
        notifier.addRule(added.copyWith(description: 'Web $i'));
      }

      expect(page().rules, hasLength(15));
      expect(notifier.isExceedMax(), isTrue);
    });
  });
}
