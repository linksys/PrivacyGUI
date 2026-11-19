import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';

import '../../../../../common/router_boundary.dart';

const _dynDnsAccount = <String, dynamic>{
  'username': 'alice',
  'password': 'secret',
  'hostName': 'home.dyndns.org',
  'isWildcardEnabled': false,
  'mode': 'Dynamic',
  'isMailExchangeEnabled': false,
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

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late DDNSNotifier notifier;

  DDNSState page() => container.read(ddnsProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getDDNSSettings, {
        'ddnsProvider': 'DynDNS',
        'dynDNSSettings': _dynDnsAccount,
      })
      ..holds(JNAPAction.getSupportedDDNSProviders, {
        'supportedDDNSProviders': ['DynDNS', 'No-IP', 'TZO'],
      })
      ..holds(JNAPAction.getDDNSStatus, {'status': 'Success'})
      ..holds(JNAPAction.getWANStatus, _wanStatus);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(ddnsProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('lists None first, then the providers the router supports', () async {
      await notifier.fetch();

      expect(page().supportedProvider, ['None', 'DynDNS', 'No-IP', 'TZO']);
    });

    test('reads the account the router holds', () async {
      await notifier.fetch();

      final provider = page().provider;
      expect(provider, isA<DynDNSProvider>());
      expect((provider as DynDNSProvider).settings.hostName, 'home.dyndns.org');
    });

    test('reads the WAN address and the last update status', () async {
      await notifier.fetch();

      expect(page().ipAddress, '203.0.113.7');
      expect(page().status, 'Success');
    });

    test('shows DDNS off when the router holds no account', () async {
      router.holds(JNAPAction.getDDNSSettings, {'ddnsProvider': 'None'});

      await notifier.fetch();

      expect(page().provider, isA<NoDDNSProvider>());
    });
  });

  group('save', () {
    setUp(() => notifier.fetch());

    test('writes a DynDNS account', () async {
      notifier
        ..setProvider(dynDNSProviderName)
        ..setProviderSettings(DynDNSSettings.fromMap(_dynDnsAccount));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDDNSSetting).single, {
        'ddnsProvider': 'DynDNS',
        'dynDNSSettings': _dynDnsAccount,
      });
    });

    test('writes a No-IP account', () async {
      notifier
        ..setProvider(noIPDNSProviderName)
        ..setProviderSettings(const NoIPSettings(
            username: 'bob', password: 'pw', hostName: 'bob.ddns.net'));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDDNSSetting).single, {
        'ddnsProvider': 'No-IP',
        'noipSettings': {
          'username': 'bob',
          'password': 'pw',
          'hostName': 'bob.ddns.net',
        },
      });
    });

    test('writes a TZO account', () async {
      notifier
        ..setProvider(tzoDNSProviderName)
        ..setProviderSettings(const TZOSettings(
            username: 'carol', password: 'pw', hostName: 'carol.tzo.com'));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDDNSSetting).single, {
        'ddnsProvider': 'TZO',
        'tzoSettings': {
          'username': 'carol',
          'password': 'pw',
          'hostName': 'carol.tzo.com',
        },
      });
    });

    test('turns DDNS off with no account', () async {
      notifier.setProvider(noDNSProviderName);

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDDNSSetting).single,
          {'ddnsProvider': 'None'});
    });

    test('shows what the router holds after the write', () async {
      router
        ..holds(JNAPAction.getDDNSSettings, {'ddnsProvider': 'None'})
        ..sent.clear();
      notifier.setProvider(noDNSProviderName);

      await notifier.save();

      expect(router.actions.first, JNAPAction.setDDNSSetting);
      expect(router.actions, contains(JNAPAction.getDDNSSettings));
      expect(page().provider, isA<NoDDNSProvider>());
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router
        ..refuses(JNAPAction.setDDNSSetting)
        ..sent.clear();

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setDDNSSetting]);
    });
  });

  test('getStatus refreshes the last update status', () async {
    router.holds(JNAPAction.getDDNSStatus, {'status': 'Failed'});

    await notifier.getStatus();

    expect(page().status, 'Failed');
  });

  group('setProvider', () {
    test('starts a blank account for the chosen provider', () {
      notifier.setProvider(noIPDNSProviderName);

      expect(
          page().provider,
          const NoIPDNSProvider(
              settings:
                  NoIPSettings(username: '', password: '', hostName: '')));
    });
  });

  group('isDataValid', () {
    test('needs a username, a password and a host name', () {
      for (final name in [
        dynDNSProviderName,
        noIPDNSProviderName,
        tzoDNSProviderName,
      ]) {
        notifier.setProvider(name);
        expect(notifier.isDataValid(), isFalse, reason: '$name, blank');
      }
    });

    test('accepts a complete account from each provider', () {
      final accounts = <String, Object>{
        dynDNSProviderName: DynDNSSettings.fromMap(_dynDnsAccount),
        noIPDNSProviderName:
            const NoIPSettings(username: 'u', password: 'p', hostName: 'h'),
        tzoDNSProviderName:
            const TZOSettings(username: 'u', password: 'p', hostName: 'h'),
      };
      for (final MapEntry(key: name, value: account) in accounts.entries) {
        notifier
          ..setProvider(name)
          ..setProviderSettings(account);
        expect(notifier.isDataValid(), isTrue, reason: name);
      }
    });

    test('has nothing to check when DDNS is off', () {
      notifier.setProvider(noDNSProviderName);

      expect(notifier.isDataValid(), isTrue);
    });
  });
}
