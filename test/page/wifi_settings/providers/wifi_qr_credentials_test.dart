import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_qr_credentials.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/util/wifi_credential.dart';

import '../../../test_data/wifi_list_test_state.dart';

void main() {
  // What the router broadcasts today: 2.4 GHz and 5 GHz share one name,
  // password and WPA2/WPA3 mixed security.
  final saved = WiFiState.fromMap(wifiListTestState);

  group('wifiQRCredentialsChanged - simple mode', () {
    WiFiState simple(
      WiFiState from, {
      String? ssid,
      WifiSecurityType? securityType,
    }) =>
        from.copyWith(
          isSimpleMode: true,
          simpleModeWifi: from.simpleModeWifi
              .copyWith(ssid: ssid, securityType: securityType),
        );

    test('a new WiFi name changes what the printed QR codes encode', () {
      expect(
        wifiQRCredentialsChanged(
          state: simple(saved, ssid: 'MyNewWiFi'),
          preserved: saved,
        ),
        isTrue,
      );
    });

    // The printed codes carry the security type too, and some phones cannot
    // join a WPA3-only network with them, so any security mode change counts.
    test('a new security mode alone changes what the printed QR codes encode',
        () {
      expect(
        wifiQRCredentialsChanged(
          state: simple(saved, securityType: WifiSecurityType.wpa3Personal),
          preserved: saved,
        ),
        isTrue,
      );
    });

    // Simple mode saves 6 GHz as WPA3 whatever mixed mode the other bands use,
    // so a 6 GHz band already on WPA3 is not a change.
    test('a 6 GHz band kept on WPA3 is not a change', () {
      final withSixGHz = saved.copyWith(mainWiFi: [
        ...saved.mainWiFi,
        saved.mainWiFi.first.copyWith(
          radioID: WifiRadioBand.radio_6,
          securityType: WifiSecurityType.wpa3Personal,
        ),
      ]);

      expect(
        wifiQRCredentialsChanged(
          state: simple(withSixGHz),
          preserved: withSixGHz,
        ),
        isFalse,
      );
    });
  });

  group('wifiQRCredentialsChanged - advanced mode', () {
    WiFiState withBand(
      int index, {
      String? ssid,
      WifiSecurityType? securityType,
    }) =>
        saved.copyWith(
          mainWiFi: [
            for (final (i, radio) in saved.mainWiFi.indexed)
              i == index
                  ? radio.copyWith(ssid: ssid, securityType: securityType)
                  : radio,
          ],
        );

    test('a new name on one band changes what its QR code encodes', () {
      expect(
        wifiQRCredentialsChanged(
          state: withBand(1, ssid: 'MyNew5GHz'),
          preserved: saved,
        ),
        isTrue,
      );
    });

    test('a new security mode on one band changes what its QR code encodes',
        () {
      expect(
        wifiQRCredentialsChanged(
          state: withBand(1, securityType: WifiSecurityType.open),
          preserved: saved,
        ),
        isTrue,
      );
    });
  });

  group('wifiQRSecurityType', () {
    test('open and Enhanced Open networks join without a password', () {
      expect(
        [
          WifiSecurityType.open,
          WifiSecurityType.enhancedOpenNone,
          WifiSecurityType.enhancedOpenOnly,
        ].map(wifiQRSecurityType),
        everyElement(SecurityType.none),
      );
    });

    test('every personal WPA mode joins as WPA with its password', () {
      expect(
        [
          WifiSecurityType.wpaPersonal,
          WifiSecurityType.wpa2Personal,
          WifiSecurityType.wpa1Or2MixedPersonal,
          WifiSecurityType.wpa2Or3MixedPersonal,
          WifiSecurityType.wpa3Personal,
        ].map(wifiQRSecurityType),
        everyElement(SecurityType.wpa),
      );
    });
  });

  group('wifiQRBandsFor', () {
    // Bands sharing one name, password and QR type are one network to the
    // user, so the dialog shows one code rather than the same code per band.
    test('bands that share their credentials collapse into one QR code', () {
      final bands = wifiQRBandsFor(saved);

      expect(bands, hasLength(1));
      expect(
        bands.single.credential.generate(),
        'WIFI:S:Linksys03041;P:7sVzt65hf@;T:WPA;H:false;;',
      );
    });

    test('bands broadcasting different names each get their own QR code', () {
      final perBand = saved.copyWith(mainWiFi: [
        saved.mainWiFi[0].copyWith(ssid: 'Home-2.4'),
        saved.mainWiFi[1].copyWith(ssid: 'Home-5'),
      ]);

      expect(
        wifiQRBandsFor(perBand).map((band) => band.credential.ssid),
        ['Home-2.4', 'Home-5'],
      );
    });

    test('an open band gets a code that joins without a password', () {
      final open = saved.copyWith(mainWiFi: [
        for (final radio in saved.mainWiFi)
          radio.copyWith(securityType: WifiSecurityType.open),
      ]);

      expect(
        wifiQRBandsFor(open).single.credential.generate(),
        'WIFI:S:Linksys03041;T:nopass;H:false;;',
      );
    });

    // Phones only look for a network that does not broadcast its name when
    // the code says it is hidden.
    test('a band that hides its name gets a code marked hidden', () {
      final hidden = saved.copyWith(mainWiFi: [
        for (final radio in saved.mainWiFi) radio.copyWith(isBroadcast: false),
      ]);

      expect(
        wifiQRBandsFor(hidden).single.credential.generate(),
        'WIFI:S:Linksys03041;P:7sVzt65hf@;T:WPA;H:true;;',
      );
    });
  });
}
