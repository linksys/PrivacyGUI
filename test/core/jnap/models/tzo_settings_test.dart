import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';

const _account = <String, dynamic>{
  'username': 'carol',
  'password': 'pw',
  'hostName': 'carol.tzo.com',
};

void main() {
  test('reads and writes a TZO account', () {
    final settings = TZOSettings.fromMap(_account);

    expect(
        settings,
        const TZOSettings(
            username: 'carol', password: 'pw', hostName: 'carol.tzo.com'));
    expect(settings.toMap(), _account);
  });

  test('survives a trip through JSON text', () {
    final settings = TZOSettings.fromMap(_account);

    expect(TZOSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = TZOSettings.fromMap(_account);

    expect(settings.copyWith(username: 'u', password: 'p', hostName: 'h'),
        const TZOSettings(username: 'u', password: 'p', hostName: 'h'));
    expect(settings.copyWith(), settings);
  });
}
