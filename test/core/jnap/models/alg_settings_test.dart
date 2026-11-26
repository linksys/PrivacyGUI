import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/alg_settings.dart';

void main() {
  test('reads and writes the SIP ALG switch', () {
    final settings = ALGSettings.fromMap(const {'isSIPEnabled': true});

    expect(settings.isSIPEnabled, isTrue);
    expect(settings.toMap(), {'isSIPEnabled': true});
  });

  test('survives a trip through JSON text', () {
    const settings = ALGSettings(isSIPEnabled: false);

    expect(ALGSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    const settings = ALGSettings(isSIPEnabled: false);

    expect(settings.copyWith(isSIPEnabled: true).isSIPEnabled, isTrue);
    expect(settings.copyWith(), settings);
  });
}
