import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ddns_settings_model.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';

const _dynDns = DynDNSSettings(
  username: 'alice',
  password: 'secret',
  hostName: 'home.dyndns.org',
  isWildcardEnabled: false,
  mode: 'Dynamic',
  isMailExchangeEnabled: false,
);
const _noIp = NoIPSettings(username: 'bob', password: 'pw', hostName: 'b.net');
const _tzo = TZOSettings(username: 'carol', password: 'pw', hostName: 'c.com');

void main() {
  group('DDNSProvider.reslove', () {
    test('picks the provider whose account the router holds', () {
      expect(
        DDNSProvider.reslove(
            DDNSSettings(ddnsProvider: 'DynDNS', dynDNSSettings: _dynDns)),
        const DynDNSProvider(settings: _dynDns),
      );
      expect(
        DDNSProvider.reslove(
            DDNSSettings(ddnsProvider: 'No-IP', noIPSettings: _noIp)),
        const NoIPDNSProvider(settings: _noIp),
      );
      expect(
        DDNSProvider.reslove(
            DDNSSettings(ddnsProvider: 'TZO', tzoSettings: _tzo)),
        const TzoDNSProvider(settings: _tzo),
      );
    });

    test('is off when the router holds no account', () {
      expect(DDNSProvider.reslove(null), isA<NoDDNSProvider>());
      expect(DDNSProvider.reslove(DDNSSettings(ddnsProvider: 'None')),
          isA<NoDDNSProvider>());
    });
  });

  group('DDNSProvider.create', () {
    test('starts each provider with a blank account', () {
      expect(DDNSProvider.create('DynDNS').settings,
          isA<DynDNSSettings>().having((s) => s.mode, 'mode', 'Dynamic'));
      expect(DDNSProvider.create('No-IP').settings,
          const NoIPSettings(username: '', password: '', hostName: ''));
      expect(DDNSProvider.create('TZO').settings,
          const TZOSettings(username: '', password: '', hostName: ''));
    });

    test('is off for a name it does not know', () {
      expect(DDNSProvider.create('Unknown'), isA<NoDDNSProvider>());
    });
  });

  group('applySettings', () {
    test('keeps the provider and takes the new account', () {
      const edited = NoIPSettings(username: 'x', password: 'y', hostName: 'z');

      expect(DDNSProvider.create('No-IP').applySettings(edited),
          const NoIPDNSProvider(settings: edited));
      expect(DDNSProvider.create('DynDNS').applySettings(_dynDns),
          const DynDNSProvider(settings: _dynDns));
      expect(DDNSProvider.create('TZO').applySettings(_tzo),
          const TzoDNSProvider(settings: _tzo));
    });

    test('stays off whatever it is given', () {
      expect(
          const NoDDNSProvider().applySettings(_noIp), isA<NoDDNSProvider>());
    });
  });

  group('DDNSProvider map form', () {
    test('writes each provider as its name and account', () {
      expect(const TzoDNSProvider(settings: _tzo).toMap(), {
        'name': 'TZO',
        'settings': {
          'username': 'carol',
          'password': 'pw',
          'hostName': 'c.com'
        },
      });
      expect(const NoDDNSProvider().toMap(), {'name': 'None'});
    });

    test('reads back each provider it wrote', () {
      for (final provider in <DDNSProvider>[
        const DynDNSProvider(settings: _dynDns),
        const NoIPDNSProvider(settings: _noIp),
        const TzoDNSProvider(settings: _tzo),
        const NoDDNSProvider(),
      ]) {
        expect(DDNSProvider.fromJson(provider.toJson()), provider,
            reason: provider.name);
      }
    });
  });

  group('DDNSState', () {
    const state = DDNSState(
      supportedProvider: ['None', 'No-IP'],
      provider: NoIPDNSProvider(settings: _noIp),
      status: 'Success',
      ipAddress: '203.0.113.7',
    );

    test('survives a trip through JSON text', () {
      expect(DDNSState.fromJson(state.toJson()), state);
    });

    test('reads a missing status and address as empty', () {
      final read = DDNSState.fromMap(const {
        'supportedProvider': ['None'],
        'provider': {'name': 'None'},
      });

      expect(read.status, '');
      expect(read.ipAddress, '');
    });

    test('copyWith changes only what it names', () {
      final changed = state.copyWith(status: 'Failed');

      expect(changed.status, 'Failed');
      expect(changed.copyWith(status: 'Success'), state);
    });

    test('describes itself by its fields', () {
      expect(state.toString(), contains('ipAddress: 203.0.113.7'));
    });
  });
}
