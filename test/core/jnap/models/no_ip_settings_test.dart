import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';

const _account = <String, dynamic>{
  'username': 'bob',
  'password': 'pw',
  'hostName': 'bob.ddns.net',
};

void main() {
  test('reads and writes a No-IP account', () {
    final settings = NoIPSettings.fromMap(_account);

    expect(
        settings,
        const NoIPSettings(
            username: 'bob', password: 'pw', hostName: 'bob.ddns.net'));
    expect(settings.toMap(), _account);
  });

  test('survives a trip through JSON text', () {
    final settings = NoIPSettings.fromMap(_account);

    expect(NoIPSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = NoIPSettings.fromMap(_account);

    expect(settings.copyWith(username: 'u', password: 'p', hostName: 'h'),
        const NoIPSettings(username: 'u', password: 'p', hostName: 'h'));
    expect(settings.copyWith(), settings);
  });
}
