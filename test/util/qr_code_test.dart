import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';

void main() {
  group('createWiFiQRCode', () {
    // Codes that fit version 4 must keep printing and downloading exactly as
    // they always have. The digest was recorded from the version-4-only
    // implementation before longer codes were allowed.
    test('a name and password that fit version 4 keep their image', () async {
      final bytes = await createWiFiQRCode(const WiFiCredential(
        ssid: 'Linksys03041',
        password: '7sVzt65hf@',
        type: SecurityType.wpa,
      ));

      expect(md5.convert(bytes).toString(), 'fd10428cf2c9ffde9076f80859bea400');
    });

    // 32 characters of name and a 64-character key are the longest WiFi
    // Settings accepts - far more than version 4 holds.
    test('the longest name and password still make an image', () async {
      final bytes = await createWiFiQRCode(WiFiCredential(
        ssid: 'N' * 32,
        password: 'a' * 64,
        type: SecurityType.wpa,
      ));

      expect(image.decodePng(bytes), isNotNull);
    });
  });
}
