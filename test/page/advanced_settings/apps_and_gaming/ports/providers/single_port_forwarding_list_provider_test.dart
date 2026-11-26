import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_state.dart';

import '../../../../../common/router_boundary.dart';
import '../../../_router_lan.dart';

const _xbox = <String, dynamic>{
  'isEnabled': true,
  'externalPort': 3074,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.150',
  'internalPort': 3074,
  'description': 'XBox Live (TM)',
};

const _ssh = <String, dynamic>{
  'isEnabled': false,
  'externalPort': 2222,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.20',
  'internalPort': 22,
  'description': 'SSH',
};

/// `GetSinglePortForwardingRules` output, after the legacy JNAP reference's
/// sample. Not the router-shaped test data: its limits, 50 and 32, are the
/// fallbacks, so a test could not tell them from what the router said.
Map<String, dynamic> _rules(List<Map<String, dynamic>> rules) =>
    {'rules': rules, 'maxDescriptionLength': 12, 'maxRules': 20};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late SinglePortForwardingListNotifier notifier;

  SinglePortForwardingListState page() =>
      container.read(singlePortForwardingListProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getLANSettings, routerLan)
      ..holds(JNAPAction.getSinglePortForwardingRules, _rules([_xbox, _ssh]));
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(singlePortForwardingListProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('lists the rules the router holds, with its limits', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(page().rules, [
        SinglePortForwardingRule.fromMap(_xbox),
        SinglePortForwardingRule.fromMap(_ssh),
      ]);
      expect(page().maxRules, 20);
      expect(page().maxDescriptionLength, 12);
    });

    test('takes the LAN a rule\'s device must sit in', () async {
      await notifier.fetch();

      expect(page().routerIp, '192.168.1.1');
      expect(page().subnetMask, '255.255.255.0');
    });

    test('falls back to 50 rules of 32 characters when the router omits them',
        () async {
      router.holds(JNAPAction.getSinglePortForwardingRules, {'rules': []});

      await notifier.fetch();

      expect(page().maxRules, 50);
      expect(page().maxDescriptionLength, 32);
    });

    test('reports a LAN read the router refuses', () async {
      router.refuses(JNAPAction.getLANSettings);

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.getLANSettings]);
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router.sent.clear();
    });

    test('writes the rules the user kept, without the one they deleted',
        () async {
      notifier.deleteRule(SinglePortForwardingRule.fromMap(_ssh));

      await notifier.save();

      expect(
          router.payloadsOf(JNAPAction.setSinglePortForwardingRules).single, {
        'rules': [_xbox],
      });
    });

    test('reads the rules back from the router after the write', () async {
      router.holds(JNAPAction.getSinglePortForwardingRules, _rules([_ssh]));

      final saved = await notifier.save();

      expect(router.actions, [
        JNAPAction.setSinglePortForwardingRules,
        JNAPAction.getLANSettings,
        JNAPAction.getSinglePortForwardingRules,
      ]);
      expect(saved.rules, [SinglePortForwardingRule.fromMap(_ssh)]);
      expect(page(), saved);
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.refuses(JNAPAction.setSinglePortForwardingRules,
          result: 'ErrorRulesOverlap');
      notifier.deleteRule(SinglePortForwardingRule.fromMap(_ssh));

      await expectLater(
        notifier.save(),
        throwsA(isA<JNAPError>()
            .having((error) => error.result, 'result', 'ErrorRulesOverlap')),
      );

      expect(router.actions, [JNAPAction.setSinglePortForwardingRules]);
      expect(page().rules, [SinglePortForwardingRule.fromMap(_xbox)]);
    });
  });

  group('editing the list', () {
    setUp(() => notifier.fetch());

    final added = SinglePortForwardingRule.fromMap(const {
      'isEnabled': true,
      'externalPort': 8080,
      'protocol': 'Both',
      'internalServerIPAddress': '192.168.1.30',
      'internalPort': 80,
      'description': 'Web',
    });

    test('adds a rule at the end', () {
      notifier.addRule(added);

      expect(page().rules.last, added);
      expect(page().rules, hasLength(3));
    });

    test('replaces a rule in place', () {
      notifier.editRule(0, added);

      expect(page().rules, [added, SinglePortForwardingRule.fromMap(_ssh)]);
    });

    test('is full once it holds as many rules as the router allows', () {
      expect(notifier.isExceedMax(), isFalse);

      for (var i = 0; i < 18; i++) {
        notifier.addRule(added.copyWith(externalPort: 9000 + i));
      }

      expect(notifier.isExceedMax(), isTrue);
    });
  });
}
