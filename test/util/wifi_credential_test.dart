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

  group('WiFiCredential.parse', () {
    test('reads the name, password and hidden flag, in any field order', () {
      final credential =
          WiFiCredential.parse('WIFI:T:WPA;S:MyHome;P:abcd1234;H:true;;');

      expect(credential.ssid, 'MyHome');
      expect(credential.password, 'abcd1234');
      expect(credential.isHidden, isTrue);
    });

    // generate writes the type as WPA or WEP, the way phones read it.
    test('reads the security type', () {
      expect(
          WiFiCredential.parse('WIFI:S:MyHome;P:abcd1234;T:WPA;H:false;;').type,
          SecurityType.wpa);
      expect(WiFiCredential.parse('WIFI:S:Old;T:WEP;P:12345;;').type,
          SecurityType.wep);
      expect(WiFiCredential.parse('WIFI:S:MyHome;T:wpa;P:abcd1234;;').type,
          SecurityType.wpa);
    });

    test('reads back the type of the code generate writes', () {
      for (final type in SecurityType.values) {
        final credential =
            WiFiCredential(ssid: 'MyHome', password: 'abcd1234', type: type);

        expect(WiFiCredential.parse(credential.generate()).type, type,
            reason: type.name);
      }
    });

    // generate escapes ; : , " and \ with a backslash.
    test('undoes the escapes in a name and password', () {
      final credential = WiFiCredential.parse(
          r'WIFI:S:Home\;Net;P:a\\b\;c\,d\:e\"f;T:WPA;H:false;;');

      expect(credential.ssid, 'Home;Net');
      expect(credential.password, r'a\b;c,d:e"f');
    });

    test('reads back the name and password of the code generate writes', () {
      const credential = WiFiCredential(
        ssid: r'Cafe;Guest:2,"A"\',
        password: r'p\a;s:s,"w"',
        type: SecurityType.wpa,
        isHidden: true,
      );

      final parsed = WiFiCredential.parse(credential.generate());

      expect(parsed.ssid, r'Cafe;Guest:2,"A"\');
      expect(parsed.password, r'p\a;s:s,"w"');
      expect(parsed.isHidden, isTrue);
    });

    test('reads an open network as open, with no password', () {
      final credential =
          WiFiCredential.parse('WIFI:S:Cafe Guest;T:nopass;H:false;;');

      expect(credential.ssid, 'Cafe Guest');
      expect(credential.password, '');
      expect(credential.type, SecurityType.none);
      expect(credential.isHidden, isFalse);
    });

    test('reads a text that is not a Wi-Fi code as an empty credential', () {
      final credential = WiFiCredential.parse('https://www.linksys.com');

      expect(credential.ssid, '');
      expect(credential.password, '');
      expect(credential.type, SecurityType.none);
      expect(credential.isHidden, isFalse);
    });
  });

  group('WiFiCredential.copyWith', () {
    const home = WiFiCredential(
      ssid: 'MyHome',
      password: 'abcd1234',
      type: SecurityType.wpa,
      isHidden: true,
    );

    test('keeps every field it is not given', () {
      final copy = home.copyWith();

      expect(copy.ssid, 'MyHome');
      expect(copy.password, 'abcd1234');
      expect(copy.type, SecurityType.wpa);
      expect(copy.isHidden, isTrue);
    });

    test('replaces each field it is given', () {
      final copy = home.copyWith(
        ssid: 'MyHome-Guest',
        password: 'guest-pass',
        type: SecurityType.none,
        isHidden: false,
      );

      expect(copy.ssid, 'MyHome-Guest');
      expect(copy.password, 'guest-pass');
      expect(copy.type, SecurityType.none);
      expect(copy.isHidden, isFalse);
    });
  });
}
