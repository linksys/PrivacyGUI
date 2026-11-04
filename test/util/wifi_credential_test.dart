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
  });
}
