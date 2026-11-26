// Apps & Gaming after a refused read (#1974).
//
// Each `Set…Rules` action replaces the router's whole list: "Any existing
// rules are completely replaced by the specified values" (`firewall.hsl`). So
// a tab the page could not read is never saved, and does not count as
// changed: what it shows is not what the router holds.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_provider.dart';

import '../../../../common/router_boundary.dart';
import '../_router_lan_settings.dart';

const _noIpAccount = <String, dynamic>{
  'ddnsProvider': 'No-IP',
  'noipSettings': {
    'username': 'bob',
    'password': 'pw',
    'hostName': 'bob.ddns.net',
  },
};

const _wanStatus = <String, dynamic>{
  'macAddress': '00:11:22:33:44:55',
  'detectedWANType': 'DHCP',
  'wanStatus': 'Connected',
  'wanIPv6Status': 'Connecting',
  'wanConnection': {
    'wanType': 'DHCP',
    'ipAddress': '203.0.113.7',
    'networkPrefixLength': 24,
    'gateway': '203.0.113.1',
    'mtu': 1500,
    'dhcpLeaseMinutes': 1440,
    'dnsServer1': '203.0.113.53',
  },
  'supportedWANTypes': ['DHCP', 'Static', 'PPPoE'],
};

const _xbox = <String, dynamic>{
  'isEnabled': true,
  'externalPort': 3074,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.150',
  'internalPort': 3074,
  'description': 'XBox Live (TM)',
};

const _web = <String, dynamic>{
  'isEnabled': true,
  'externalPort': 8080,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.151',
  'internalPort': 80,
  'description': 'web',
};

/// A port of [_torrent]'s range, moved to a single-port rule.
const _moved = <String, dynamic>{
  'isEnabled': true,
  'externalPort': 6890,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.150',
  'internalPort': 6890,
  'description': 'Moved',
};

const _torrent = <String, dynamic>{
  'isEnabled': true,
  'firstExternalPort': 6888,
  'lastExternalPort': 6900,
  'protocol': 'Both',
  'internalServerIPAddress': '192.168.1.150',
  'description': 'BitTorrent',
};

const _newRange = <String, dynamic>{
  'isEnabled': true,
  'firstExternalPort': 7000,
  'lastExternalPort': 7010,
  'protocol': 'Both',
  'internalServerIPAddress': '192.168.1.150',
  'description': 'new range',
};

const _game = <String, dynamic>{
  'isEnabled': true,
  'firstTriggerPort': 12000,
  'lastTriggerPort': 12050,
  'firstForwardedPort': 12000,
  'lastForwardedPort': 12050,
  'description': 'game',
};

const _newGame = <String, dynamic>{
  'isEnabled': true,
  'firstTriggerPort': 13000,
  'lastTriggerPort': 13010,
  'firstForwardedPort': 13000,
  'lastForwardedPort': 13010,
  'description': 'new game',
};

const _refused = JNAPError(result: 'ErrorUnknown');

const _writes = {
  JNAPAction.setDDNSSetting,
  JNAPAction.setSinglePortForwardingRules,
  JNAPAction.setPortRangeForwardingRules,
  JNAPAction.setPortRangeTriggeringRules,
};

/// A `Get…Rules` output holding [rules].
Map<String, dynamic> _list(List<Map<String, dynamic>> rules) =>
    {'rules': rules, 'maxRules': 50, 'maxDescriptionLength': 32};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late AppsAndGamingViewNotifier notifier;

  /// The writes the router received, in order.
  List<JNAPAction> writes() =>
      router.actions.where((action) => _writes.contains(action)).toList();

  /// Opens the page. The view reports a refused read in a snackbar; what the
  /// page does after it is what these tests check.
  Future<void> openPage() async {
    try {
      await notifier.fetch();
    } on JNAPError {
      // Reported by the view.
    }
  }

  setUp(() {
    // The router holds a DDNS account and one rule in each list.
    router = RouterBoundary()
      ..holds(JNAPAction.getDDNSSettings, _noIpAccount)
      ..holds(JNAPAction.getSupportedDDNSProviders, {
        'supportedDDNSProviders': ['DynDNS', 'No-IP', 'TZO'],
      })
      ..holds(JNAPAction.getDDNSStatus, {'status': 'Success'})
      ..holds(JNAPAction.getWANStatus, _wanStatus)
      ..holds(JNAPAction.getLANSettings, routerLanSettings)
      ..holds(JNAPAction.getSinglePortForwardingRules, _list([_xbox]))
      ..holds(JNAPAction.getPortRangeForwardingRules, _list([_torrent]))
      ..holds(JNAPAction.getPortRangeTriggeringRules, _list([_game]));
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(appsAndGamingProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('a save after a refused read', () {
    test(
        'single-port read refused, the user adds a rule: '
        'the save leaves the router\'s single-port rules alone', () async {
      router.holdsInTurn(JNAPAction.getSinglePortForwardingRules, [
        _refused,
        _list([_xbox])
      ]);
      await openPage();
      container
          .read(singlePortForwardingListProvider.notifier)
          .addRule(SinglePortForwardingRule.fromMap(_web));

      await notifier.save();

      expect(
          router.payloadsOf(JNAPAction.setSinglePortForwardingRules), isEmpty);
      expect(writes(), isEmpty);
    });

    test(
        'triggering read refused, the user adds a rule: '
        'the save leaves the router\'s triggering rules alone', () async {
      router.holdsInTurn(JNAPAction.getPortRangeTriggeringRules, [
        _refused,
        _list([_game])
      ]);
      await openPage();
      container
          .read(portRangeTriggeringListProvider.notifier)
          .addRule(PortRangeTriggeringRule.fromMap(_newGame));

      await notifier.save();

      expect(
          router.payloadsOf(JNAPAction.setPortRangeTriggeringRules), isEmpty);
      expect(writes(), isEmpty);
    });

    test(
        'port-range read refused, the user adds a port-range rule: '
        'the save writes no list, the triggering tab included', () async {
      router.holdsInTurn(JNAPAction.getPortRangeForwardingRules, [
        _refused,
        _list([_torrent])
      ]);
      await openPage();
      container
          .read(portRangeForwardingListProvider.notifier)
          .addRule(PortRangeForwardingRule.fromMap(_newRange));

      await notifier.save();

      expect(
          router.payloadsOf(JNAPAction.setPortRangeTriggeringRules), isEmpty);
      expect(
          router.payloadsOf(JNAPAction.setPortRangeForwardingRules), isEmpty);
      expect(writes(), isEmpty);
    });

    test('port-range read refused, no edit: nothing counts as changed',
        () async {
      router.refuses(JNAPAction.getPortRangeForwardingRules);
      await openPage();

      expect(notifier.isChanged(), isFalse);
    });

    test(
        'port-range read refused, no edit: the save writes nothing, '
        'and reports the read it still cannot make', () async {
      router.refuses(JNAPAction.getPortRangeForwardingRules);
      await openPage();

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(
          router.payloadsOf(JNAPAction.setPortRangeForwardingRules), isEmpty);
      expect(writes(), isEmpty);
    });

    test(
        'DDNS read refused, no edit: '
        'the save leaves the DDNS account and every list alone', () async {
      router.holdsInTurn(JNAPAction.getDDNSSettings, [_refused, _noIpAccount]);
      await openPage();

      expect(notifier.isReadComplete(), isFalse);
      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDDNSSetting), isEmpty);
      expect(writes(), isEmpty);
    });

    test('a tab that was read and edited is still saved', () async {
      router.holdsInTurn(JNAPAction.getSinglePortForwardingRules, [
        _refused,
        _list([_xbox])
      ]);
      await openPage();
      container
          .read(singlePortForwardingListProvider.notifier)
          .addRule(SinglePortForwardingRule.fromMap(_web));
      container
          .read(portRangeTriggeringListProvider.notifier)
          .addRule(PortRangeTriggeringRule.fromMap(_newGame));

      await notifier.save();

      expect(writes(), [JNAPAction.setPortRangeTriggeringRules]);
      expect(router.payloadsOf(JNAPAction.setPortRangeTriggeringRules), [
        {
          'rules': [_game, _newGame],
        },
      ]);
    });

    test(
        'the forwarding lists still go in the other order '
        'when the single ports overlap a range not yet deleted', () async {
      router
        ..holdsInTurn(JNAPAction.getPortRangeTriggeringRules, [
          _refused,
          _list([_game])
        ])
        ..holdsInTurn(JNAPAction.setSinglePortForwardingRules, [
          const JNAPError(result: 'ErrorRulesOverlap'),
          <String, dynamic>{},
        ]);
      await openPage();
      // Moving a port from a range to a single-port rule.
      container
          .read(portRangeForwardingListProvider.notifier)
          .deleteRule(PortRangeForwardingRule.fromMap(_torrent));
      container
          .read(singlePortForwardingListProvider.notifier)
          .addRule(SinglePortForwardingRule.fromMap(_moved));

      await notifier.save();

      expect(writes(), [
        JNAPAction.setSinglePortForwardingRules,
        JNAPAction.setPortRangeForwardingRules,
        JNAPAction.setSinglePortForwardingRules,
      ]);
      expect(router.payloadsOf(JNAPAction.setPortRangeForwardingRules), [
        {'rules': []},
      ]);
      expect(router.payloadsOf(JNAPAction.setSinglePortForwardingRules), [
        {
          'rules': [_xbox, _moved],
        },
        {
          'rules': [_xbox, _moved],
        },
      ]);
    });
  });

  group('fetch', () {
    test('reads every tab even when one is refused, then reports the refusal',
        () async {
      router.refuses(JNAPAction.getSinglePortForwardingRules);

      await expectLater(
        notifier.fetch(),
        throwsA(isA<JNAPError>()
            .having((error) => error.result, 'result', 'ErrorUnknown')),
      );

      expect(router.actions, [
        JNAPAction.getDDNSSettings,
        JNAPAction.getSupportedDDNSProviders,
        JNAPAction.getDDNSStatus,
        JNAPAction.getWANStatus,
        JNAPAction.getLANSettings,
        JNAPAction.getSinglePortForwardingRules,
        JNAPAction.getLANSettings,
        JNAPAction.getPortRangeForwardingRules,
        JNAPAction.getPortRangeTriggeringRules,
      ]);
      final page = container.read(appsAndGamingProvider);
      expect(page.preserveDDNSState?.provider, isA<NoIPDNSProvider>());
      expect(page.preserveSinglePortForwardingListState, isNull);
      expect(page.preservePortRangeForwardingListState?.rules,
          [PortRangeForwardingRule.fromMap(_torrent)]);
      expect(page.preservePortRangeTriggeringListState?.rules,
          [PortRangeTriggeringRule.fromMap(_game)]);
      expect(notifier.isReadComplete(), isFalse);
    });

    test('reports the first refusal when two tabs are refused', () async {
      router
        ..refuses(JNAPAction.getSinglePortForwardingRules)
        ..refuses(JNAPAction.getPortRangeTriggeringRules,
            result: '_ErrorUnauthorized');

      await expectLater(
        notifier.fetch(),
        throwsA(isA<JNAPError>()
            .having((error) => error.result, 'result', 'ErrorUnknown')),
      );

      final page = container.read(appsAndGamingProvider);
      expect(page.preserveSinglePortForwardingListState, isNull);
      expect(page.preservePortRangeTriggeringListState, isNull);
    });

    test('a refused read drops what an earlier visit read', () async {
      await openPage();
      expect(notifier.isReadComplete(), isTrue);
      router.refuses(JNAPAction.getPortRangeForwardingRules);

      await openPage();
      // The tab still shows the earlier visit's list, and the user edits it.
      container
          .read(portRangeForwardingListProvider.notifier)
          .deleteRule(PortRangeForwardingRule.fromMap(_torrent));

      expect(
          container
              .read(appsAndGamingProvider)
              .preservePortRangeForwardingListState,
          isNull);
      expect(notifier.isReadComplete(), isFalse);
      expect(notifier.isChanged(), isFalse);
      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));
      expect(writes(), isEmpty);
    });
  });

  test('a later read that succeeds makes the page saveable again', () async {
    router.holdsInTurn(JNAPAction.getSinglePortForwardingRules, [
      _refused,
      _list([_xbox])
    ]);
    await openPage();
    expect(notifier.isReadComplete(), isFalse);

    // The user opens the page again.
    await openPage();

    expect(notifier.isReadComplete(), isTrue);
    expect(notifier.isChanged(), isFalse);
    container
        .read(singlePortForwardingListProvider.notifier)
        .addRule(SinglePortForwardingRule.fromMap(_web));
    expect(notifier.isChanged(), isTrue);

    await notifier.save();

    expect(writes(), [JNAPAction.setSinglePortForwardingRules]);
    expect(router.payloadsOf(JNAPAction.setSinglePortForwardingRules), [
      {
        'rules': [_xbox, _web],
      },
    ]);
  });
}
