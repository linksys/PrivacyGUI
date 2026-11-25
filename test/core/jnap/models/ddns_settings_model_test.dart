import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ddns_settings_model.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';

/// `GetDDNSSettings` output, the legacy JNAP reference's sample.
const _dynDns = <String, dynamic>{
  'ddnsProvider': 'DynDNS',
  'dynDNSSettings': {
    'username': 'bob',
    'password': 'iambob',
    'hostName': 'kingdomofbob',
    'isWildcardEnabled': false,
    'mode': 'Dynamic',
    'isMailExchangeEnabled': true,
    'mailExchangeSettings': {'hostName': 'bobsmail', 'isBackup': true},
  },
};

void main() {
  test('reads a DynDNS account', () {
    final settings = DDNSSettings.fromMap(_dynDns);

    expect(settings.ddnsProvider, 'DynDNS');
    expect(settings.dynDNSSettings?.hostName, 'kingdomofbob');
    expect(settings.noIPSettings, isNull);
    expect(settings.tzoSettings, isNull);
  });

  test('reads a No-IP account under noipSettings', () {
    final settings = DDNSSettings.fromMap(const {
      'ddnsProvider': 'No-IP',
      'noipSettings': {'username': 'u', 'password': 'p', 'hostName': 'h'},
    });

    expect(settings.noIPSettings,
        const NoIPSettings(username: 'u', password: 'p', hostName: 'h'));
  });

  test('reads a TZO account', () {
    final settings = DDNSSettings.fromMap(const {
      'ddnsProvider': 'TZO',
      'tzoSettings': {'username': 'u', 'password': 'p', 'hostName': 'h'},
    });

    expect(settings.tzoSettings,
        const TZOSettings(username: 'u', password: 'p', hostName: 'h'));
  });

  test('writes the fields it read, null for the other providers', () {
    expect(DDNSSettings.fromMap(_dynDns).toMap(), {
      ..._dynDns,
      'tzoSettings': null,
      'noipSettings': null,
    });
  });

  test('survives a trip through JSON text', () {
    final settings = DDNSSettings.fromMap(_dynDns);

    expect(DDNSSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = DDNSSettings.fromMap(_dynDns);
    const tzo = TZOSettings(username: 'u', password: 'p', hostName: 'h');

    final changed = settings.copyWith(ddnsProvider: 'TZO', tzoSettings: tzo);

    expect(changed.ddnsProvider, 'TZO');
    expect(changed.tzoSettings, tzo);
    expect(changed.dynDNSSettings, isA<DynDNSSettings>());
    expect(settings.copyWith(), settings);
  });
}
