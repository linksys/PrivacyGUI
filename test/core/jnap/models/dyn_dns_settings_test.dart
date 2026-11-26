import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';

/// The `dynDNSSettings` of `GetDDNSSettings`, the legacy JNAP reference's
/// sample.
const _account = <String, dynamic>{
  'username': 'bob',
  'password': 'iambob',
  'hostName': 'kingdomofbob',
  'isWildcardEnabled': false,
  'mode': 'Dynamic',
  'isMailExchangeEnabled': true,
  'mailExchangeSettings': {'hostName': 'bobsmail', 'isBackup': true},
};

void main() {
  test('reads an account with its mail exchange', () {
    final settings = DynDNSSettings.fromMap(_account);

    expect(settings.username, 'bob');
    expect(settings.password, 'iambob');
    expect(settings.hostName, 'kingdomofbob');
    expect(settings.isWildcardEnabled, isFalse);
    expect(settings.mode, 'Dynamic');
    expect(settings.isMailExchangeEnabled, isTrue);
    expect(settings.mailExchangeSettings,
        const DynDNSMailExchangeSettings(hostName: 'bobsmail', isBackup: true));
  });

  test('writes the mail exchange while it is on', () {
    expect(DynDNSSettings.fromMap(_account).toMap(), _account);
  });

  test('leaves the mail exchange out once it is off', () {
    final off =
        DynDNSSettings.fromMap(_account).copyWith(isMailExchangeEnabled: false);

    expect(off.mailExchangeSettings, isNotNull);
    expect(off.toMap().keys, isNot(contains('mailExchangeSettings')));
  });

  test('reads an account with no mail exchange', () {
    final settings = DynDNSSettings.fromMap(
        Map.of(_account)..remove('mailExchangeSettings'));

    expect(settings.mailExchangeSettings, isNull);
  });

  test('survives a trip through JSON text', () {
    final settings = DynDNSSettings.fromMap(_account);
    final mail = settings.mailExchangeSettings!;

    expect(DynDNSSettings.fromJson(settings.toJson()), settings);
    expect(DynDNSMailExchangeSettings.fromJson(mail.toJson()), mail);
  });

  test('copyWith changes only what it names, and can drop the mail exchange',
      () {
    final settings = DynDNSSettings.fromMap(_account);

    final changed = settings.copyWith(
      username: 'alice',
      password: 'secret',
      hostName: 'home',
      isWildcardEnabled: true,
      mode: 'Static',
      mailExchangeSettings: () => null,
    );

    expect(changed.toMap(), {
      'username': 'alice',
      'password': 'secret',
      'hostName': 'home',
      'isWildcardEnabled': true,
      'mode': 'Static',
      'isMailExchangeEnabled': true,
    });
    expect(settings.copyWith(), settings);
  });

  test('copyWith of a mail exchange changes only what it names', () {
    const mail = DynDNSMailExchangeSettings(hostName: 'mx', isBackup: false);

    expect(mail.copyWith(isBackup: true),
        const DynDNSMailExchangeSettings(hostName: 'mx', isBackup: true));
    expect(mail.copyWith(hostName: 'mx2').hostName, 'mx2');
  });
}
