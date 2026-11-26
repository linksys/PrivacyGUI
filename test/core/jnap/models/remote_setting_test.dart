import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/remote_setting.dart';

void main() {
  test('reads and writes whether remote management is on', () {
    final setting = RemoteSetting.fromJson(const {'isEnabled': true});

    expect(setting.isEnabled, isTrue);
    expect(setting.toJson(), {'isEnabled': true});
  });

  test('copyWith changes only what it names', () {
    const setting = RemoteSetting(isEnabled: false);

    expect(setting.copyWith(isEnabled: true),
        const RemoteSetting(isEnabled: true));
    expect(setting.copyWith(), setting);
  });
}
