import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';

void main() {
  group('InternetSettingsReadOnlyInfo', () {
    test('hostName defaults to empty string', () {
      const info = InternetSettingsReadOnlyInfo();
      expect(info.hostName, '');
    });

    test('hostName is stored and surfaced', () {
      const info = InternetSettingsReadOnlyInfo(hostName: 'Community00080');
      expect(info.hostName, 'Community00080');
    });

    test('hostName participates in equality', () {
      const a = InternetSettingsReadOnlyInfo(hostName: 'A');
      const b = InternetSettingsReadOnlyInfo(hostName: 'B');
      const c = InternetSettingsReadOnlyInfo(hostName: 'A');
      expect(a, isNot(equals(b)));
      expect(a, equals(c));
    });
  });
}
