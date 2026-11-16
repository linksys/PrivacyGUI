import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/util/wifi_credential.dart';

void main() {
  group('WiFiCredential.generate', () {
    test('a secured network carries its password and WPA type', () {
      const credential = WiFiCredential(
        ssid: 'MyHome',
        password: 'abcd1234',
        type: SecurityType.wpa,
      );

      expect(
        credential.generate(),
        'WIFI:S:MyHome;P:abcd1234;T:WPA;H:false;;',
      );
    });

    // Phones read T:nopass as "join without a password"; the spec has no NONE
    // value, and a leftover password would make them try WPA.
    test('an open network is written as nopass without a password', () {
      const credential = WiFiCredential(
        ssid: 'MyHome',
        password: 'leftover-password',
        type: SecurityType.none,
      );

      expect(credential.generate(), 'WIFI:S:MyHome;T:nopass;H:false;;');
    });

    // ; : , separate the fields, \ escapes and " quotes, so a name or password
    // holding one of them must escape it - unescaped, a phone reads the name
    // or password cut short at the first one and cannot join.
    test('special characters in the name and password are escaped', () {
      const credential = WiFiCredential(
        ssid: r'Home;Net',
        password: r'a\b;c,d:e"f',
        type: SecurityType.wpa,
      );

      expect(
        credential.generate(),
        r'WIFI:S:Home\;Net;P:a\\b\;c\,d\:e\"f;T:WPA;H:false;;',
      );
    });

    test('special characters in an open network name are escaped', () {
      const credential = WiFiCredential(
        ssid: r'Cafe:Guest',
        type: SecurityType.none,
      );

      expect(credential.generate(), r'WIFI:S:Cafe\:Guest;T:nopass;H:false;;');
    });
  });
}
