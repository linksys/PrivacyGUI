import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';

import '../../../../common/router_boundary.dart';
import '../../_router_lan.dart';

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

const _noIpAccount = <String, dynamic>{
  'ddnsProvider': 'No-IP',
  'noipSettings': {
    'username': 'bob',
    'password': 'pw',
    'hostName': 'bob.ddns.net',
  },
};

const _xbox = <String, dynamic>{
  'isEnabled': true,
  'externalPort': 3074,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.150',
  'internalPort': 3074,
  'description': 'XBox Live (TM)',
};

const _torrent = <String, dynamic>{
  'isEnabled': true,
  'firstExternalPort': 6888,
  'lastExternalPort': 6900,
  'protocol': 'Both',
  'internalServerIPAddress': '192.168.1.150',
  'description': 'BitTorrent',
};

const _custom = <String, dynamic>{
  'isEnabled': true,
  'firstTriggerPort': 12000,
  'lastTriggerPort': 12050,
  'firstForwardedPort': 12000,
  'lastForwardedPort': 12050,
  'description': 'custom',
};

const _writes = {
  JNAPAction.setDDNSSetting,
  JNAPAction.setSinglePortForwardingRules,
  JNAPAction.setPortRangeForwardingRules,
  JNAPAction.setPortRangeTriggeringRules,
};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late AppsAndGamingViewNotifier notifier;

  AppsAndGamingViewState page() => container.read(appsAndGamingProvider);

  /// The writes the router received, in order.
  List<JNAPAction> writes() =>
      router.actions.where((action) => _writes.contains(action)).toList();

  setUp(() async {
    router = RouterBoundary()
      ..holds(JNAPAction.getDDNSSettings, _noIpAccount)
      ..holds(JNAPAction.getSupportedDDNSProviders, {
        'supportedDDNSProviders': ['DynDNS', 'No-IP', 'TZO'],
      })
      ..holds(JNAPAction.getDDNSStatus, {'status': 'Success'})
      ..holds(JNAPAction.getWANStatus, _wanStatus)
      ..holds(JNAPAction.getLANSettings, routerLan)
      ..holds(JNAPAction.getSinglePortForwardingRules, {
        'rules': [_xbox],
        'maxRules': 20,
        'maxDescriptionLength': 12,
      })
      ..holds(JNAPAction.getPortRangeForwardingRules, {
        'rules': [_torrent],
        'maxRules': 15,
        'maxDescriptionLength': 12,
      })
      ..holds(JNAPAction.getPortRangeTriggeringRules, {
        'rules': [_custom],
        'maxRules': 15,
        'maxDescriptionLength': 12,
      });
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(appsAndGamingProvider.notifier);
    await notifier.fetch();
    router.sent.clear();
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('keeps what each tab read, to tell an edit from it', () {
      expect(page().preserveDDNSState, container.read(ddnsProvider));
      expect(page().preserveSinglePortForwardingListState,
          container.read(singlePortForwardingListProvider));
      expect(page().preservePortRangeForwardingListState,
          container.read(portRangeForwardingListProvider));
      expect(page().preservePortRangeTriggeringListState,
          container.read(portRangeTriggeringListProvider));
      expect(page().preserveDDNSState?.provider, isA<NoIPDNSProvider>());
      expect(page().preserveSinglePortForwardingListState?.rules,
          [SinglePortForwardingRule.fromMap(_xbox)]);
    });

    test('shows nothing changed', () {
      expect(notifier.isChanged(), isFalse);
    });
  });

  group('isChanged', () {
    final edits = <String, void Function(ProviderContainer)>{
      'DDNS': (c) =>
          c.read(ddnsProvider.notifier).setProvider(noDNSProviderName),
      'single ports': (c) => c
          .read(singlePortForwardingListProvider.notifier)
          .deleteRule(SinglePortForwardingRule.fromMap(_xbox)),
      'port ranges': (c) => c
          .read(portRangeForwardingListProvider.notifier)
          .deleteRule(PortRangeForwardingRule.fromMap(_torrent)),
      'triggering': (c) => c
          .read(portRangeTriggeringListProvider.notifier)
          .deleteRule(PortRangeTriggeringRule.fromMap(_custom)),
    };

    for (final MapEntry(key: tab, value: edit) in edits.entries) {
      test('sees an edit on the $tab tab', () {
        edit(container);

        expect(notifier.isChanged(), isTrue);
      });
    }
  });

  group('isDataValid', () {
    test('is what the DDNS tab says', () {
      expect(notifier.isDataValid(), isTrue);

      container.read(ddnsProvider.notifier).setProvider(dynDNSProviderName);

      expect(notifier.isDataValid(), isFalse);
    });
  });

  group('save', () {
    test('writes nothing when nothing changed, and reads every tab back',
        () async {
      await notifier.save();

      expect(writes(), isEmpty);
      expect(
          router.actions,
          containsAll([
            JNAPAction.getDDNSSettings,
            JNAPAction.getSinglePortForwardingRules,
            JNAPAction.getPortRangeForwardingRules,
            JNAPAction.getPortRangeTriggeringRules,
          ]));
    });

    test('writes DDNS when the user picked another provider', () async {
      container.read(ddnsProvider.notifier).setProvider(noDNSProviderName);

      await notifier.save();

      expect(writes(), [JNAPAction.setDDNSSetting]);
      expect(router.payloadsOf(JNAPAction.setDDNSSetting).single,
          {'ddnsProvider': 'None'});
    });

    test('writes only the lists the user changed, single ports first',
        () async {
      container
          .read(singlePortForwardingListProvider.notifier)
          .deleteRule(SinglePortForwardingRule.fromMap(_xbox));
      container
          .read(portRangeTriggeringListProvider.notifier)
          .deleteRule(PortRangeTriggeringRule.fromMap(_custom));

      await notifier.save();

      expect(writes(), [
        JNAPAction.setSinglePortForwardingRules,
        JNAPAction.setPortRangeTriggeringRules,
      ]);
      expect(router.payloadsOf(JNAPAction.setSinglePortForwardingRules).single,
          {'rules': []});
    });

    test('writes the port ranges first when the single ports fail first',
        () async {
      // Moving a port from a range to a single-port rule: the single-port
      // write overlaps the range the router still holds, until the range
      // write has gone through.
      router.holdsInTurn(JNAPAction.setSinglePortForwardingRules, [
        const JNAPError(result: 'ErrorRulesOverlap'),
        <String, dynamic>{},
      ]);
      container
          .read(portRangeForwardingListProvider.notifier)
          .deleteRule(PortRangeForwardingRule.fromMap(_torrent));
      container.read(singlePortForwardingListProvider.notifier).addRule(
          SinglePortForwardingRule.fromMap(_xbox).copyWith(
              externalPort: 6890, internalPort: 6890, description: 'Moved'));

      await notifier.save();

      expect(writes(), [
        JNAPAction.setSinglePortForwardingRules,
        JNAPAction.setPortRangeForwardingRules,
        JNAPAction.setSinglePortForwardingRules,
      ]);
      expect(router.payloadsOf(JNAPAction.setPortRangeForwardingRules).single,
          {'rules': []});
    });

    test('reports a write that fails in both orders', () async {
      router.refuses(JNAPAction.setSinglePortForwardingRules,
          result: 'ErrorRulesOverlap');
      container
          .read(singlePortForwardingListProvider.notifier)
          .deleteRule(SinglePortForwardingRule.fromMap(_xbox));

      await expectLater(
        notifier.save(),
        throwsA(isA<JNAPError>()
            .having((error) => error.result, 'result', 'ErrorRulesOverlap')),
      );

      expect(writes(), [
        JNAPAction.setSinglePortForwardingRules,
        JNAPAction.setSinglePortForwardingRules,
      ]);
      expect(router.actions.last, JNAPAction.setSinglePortForwardingRules);
    });

    test('reports a triggering write the router refuses', () async {
      router.refuses(JNAPAction.setPortRangeTriggeringRules);
      container
          .read(portRangeTriggeringListProvider.notifier)
          .deleteRule(PortRangeTriggeringRule.fromMap(_custom));

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions.last, JNAPAction.setPortRangeTriggeringRules);
    });

    test('keeps what the router holds after the write, to tell the next edit',
        () async {
      router.holds(JNAPAction.getPortRangeTriggeringRules, {
        'rules': <Map<String, dynamic>>[],
        'maxRules': 15,
        'maxDescriptionLength': 12,
      });
      container
          .read(portRangeTriggeringListProvider.notifier)
          .deleteRule(PortRangeTriggeringRule.fromMap(_custom));

      final saved = await notifier.save();

      expect(saved, page());
      expect(page().preservePortRangeTriggeringListState?.rules, isEmpty);
      expect(notifier.isChanged(), isFalse);
    });
  });
}
