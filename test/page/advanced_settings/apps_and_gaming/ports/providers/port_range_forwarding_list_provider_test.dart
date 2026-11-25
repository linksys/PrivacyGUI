import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_list_state.dart';

import '../../../../../common/router_boundary.dart';
import '_router_lan.dart';

const _torrent = <String, dynamic>{
  'isEnabled': true,
  'firstExternalPort': 6888,
  'lastExternalPort': 6900,
  'protocol': 'Both',
  'internalServerIPAddress': '192.168.1.150',
  'description': 'BitTorrent',
};

const _voip = <String, dynamic>{
  'isEnabled': true,
  'firstExternalPort': 10000,
  'lastExternalPort': 20000,
  'protocol': 'UDP',
  'internalServerIPAddress': '192.168.1.40',
  'description': 'VoIP',
};

/// `GetPortRangeForwardingRules` output, after the spec's sample.
Map<String, dynamic> _rules(List<Map<String, dynamic>> rules) =>
    {'rules': rules, 'maxDescriptionLength': 12, 'maxRules': 15};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late PortRangeForwardingListNotifier notifier;

  PortRangeForwardingListState page() =>
      container.read(portRangeForwardingListProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getLANSettings, routerLan)
      ..holds(
          JNAPAction.getPortRangeForwardingRules, _rules([_torrent, _voip]));
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(portRangeForwardingListProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('lists the rules the router holds, with its limits and LAN', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(page().rules, [
        PortRangeForwardingRule.fromMap(_torrent),
        PortRangeForwardingRule.fromMap(_voip),
      ]);
      expect(page().maxRules, 15);
      expect(page().maxDescriptionLength, 12);
      expect(page().routerIp, '192.168.1.1');
      expect(page().subnetMask, '255.255.255.0');
    });

    test('falls back to 50 rules of 32 characters when the router omits them',
        () async {
      router.holds(JNAPAction.getPortRangeForwardingRules, {'rules': []});

      await notifier.fetch();

      expect(page().maxRules, 50);
      expect(page().maxDescriptionLength, 32);
    });

    test('reports a read the router refuses, and keeps the page', () async {
      router.refuses(JNAPAction.getPortRangeForwardingRules);

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page(), const PortRangeForwardingListState());
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router.sent.clear();
    });

    test('writes the rules the user kept, without the one they deleted',
        () async {
      notifier.deleteRule(PortRangeForwardingRule.fromMap(_voip));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setPortRangeForwardingRules).single, {
        'rules': [_torrent],
      });
    });

    test('reads the rules back from the router after the write', () async {
      router.holds(JNAPAction.getPortRangeForwardingRules, _rules([_voip]));

      final saved = await notifier.save();

      expect(router.actions, [
        JNAPAction.setPortRangeForwardingRules,
        JNAPAction.getLANSettings,
        JNAPAction.getPortRangeForwardingRules,
      ]);
      expect(saved.rules, [PortRangeForwardingRule.fromMap(_voip)]);
      expect(page(), saved);
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.refuses(JNAPAction.setPortRangeForwardingRules,
          result: 'ErrorInvalidExternalPortRange');
      notifier.deleteRule(PortRangeForwardingRule.fromMap(_voip));

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setPortRangeForwardingRules]);
      expect(page().rules, [PortRangeForwardingRule.fromMap(_torrent)]);
    });
  });

  group('editing the list', () {
    setUp(() => notifier.fetch());

    final added = PortRangeForwardingRule.fromMap(const {
      'isEnabled': true,
      'firstExternalPort': 27015,
      'lastExternalPort': 27030,
      'protocol': 'TCP',
      'internalServerIPAddress': '192.168.1.60',
      'description': 'Steam',
    });

    test('adds a rule at the end', () {
      notifier.addRule(added);

      expect(page().rules.last, added);
    });

    test('replaces a rule in place', () {
      notifier.editRule(1, added);

      expect(page().rules, [PortRangeForwardingRule.fromMap(_torrent), added]);
    });

    test('is full once it holds as many rules as the router allows', () {
      expect(notifier.isExceedMax(), isFalse);

      for (var i = 0; i < 13; i++) {
        notifier.addRule(added.copyWith(description: 'Steam $i'));
      }

      expect(notifier.isExceedMax(), isTrue);
    });
  });
}
