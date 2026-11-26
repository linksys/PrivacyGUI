import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_state.dart';

import '../../../../../common/router_boundary.dart';

const _custom = <String, dynamic>{
  'isEnabled': true,
  'firstTriggerPort': 12000,
  'lastTriggerPort': 12050,
  'firstForwardedPort': 12000,
  'lastForwardedPort': 12050,
  'description': 'custom',
};

const _irc = <String, dynamic>{
  'isEnabled': false,
  'firstTriggerPort': 6667,
  'lastTriggerPort': 6667,
  'firstForwardedPort': 113,
  'lastForwardedPort': 113,
  'description': 'IRC',
};

/// `GetPortRangeTriggeringRules` output, after the legacy JNAP reference's
/// sample.
Map<String, dynamic> _rules(List<Map<String, dynamic>> rules) =>
    {'rules': rules, 'maxDescriptionLength': 12, 'maxRules': 15};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late PortRangeTriggeringListNotifier notifier;

  PortRangeTriggeringListState page() =>
      container.read(portRangeTriggeringListProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getPortRangeTriggeringRules, _rules([_custom, _irc]));
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(portRangeTriggeringListProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('lists the rules the router holds, with its limits', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(page().rules, [
        PortRangeTriggeringRule.fromMap(_custom),
        PortRangeTriggeringRule.fromMap(_irc),
      ]);
      expect(page().maxRules, 15);
      expect(page().maxDescriptionLength, 12);
    });

    test('falls back to 50 rules of 32 characters when the router omits them',
        () async {
      router.holds(JNAPAction.getPortRangeTriggeringRules, {'rules': []});

      await notifier.fetch();

      expect(page().maxRules, 50);
      expect(page().maxDescriptionLength, 32);
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router.sent.clear();
    });

    test('writes the rules the user kept, without the one they deleted',
        () async {
      notifier.deleteRule(PortRangeTriggeringRule.fromMap(_irc));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setPortRangeTriggeringRules).single, {
        'rules': [_custom],
      });
    });

    test('reads the rules back from the router after the write', () async {
      router.holds(JNAPAction.getPortRangeTriggeringRules, _rules([_irc]));

      final saved = await notifier.save();

      expect(router.actions, [
        JNAPAction.setPortRangeTriggeringRules,
        JNAPAction.getPortRangeTriggeringRules,
      ]);
      expect(saved.rules, [PortRangeTriggeringRule.fromMap(_irc)]);
      expect(page(), saved);
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.refuses(JNAPAction.setPortRangeTriggeringRules,
          result: 'ErrorRulesOverlap');
      notifier.deleteRule(PortRangeTriggeringRule.fromMap(_irc));

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setPortRangeTriggeringRules]);
      expect(page().rules, [PortRangeTriggeringRule.fromMap(_custom)]);
    });
  });

  group('editing the list', () {
    setUp(() => notifier.fetch());

    final added = PortRangeTriggeringRule.fromMap(const {
      'isEnabled': true,
      'firstTriggerPort': 7000,
      'lastTriggerPort': 7010,
      'firstForwardedPort': 7100,
      'lastForwardedPort': 7110,
      'description': 'Game',
    });

    test('adds a rule at the end', () {
      notifier.addRule(added);

      expect(page().rules.last, added);
    });

    test('replaces a rule in place', () {
      notifier.editRule(0, added);

      expect(page().rules, [added, PortRangeTriggeringRule.fromMap(_irc)]);
    });

    test('is full once it holds as many rules as the router allows', () {
      expect(notifier.isExceedMax(), isFalse);

      for (var i = 0; i < 13; i++) {
        notifier.addRule(added.copyWith(description: 'Game $i'));
      }

      expect(notifier.isExceedMax(), isTrue);
    });
  });
}
