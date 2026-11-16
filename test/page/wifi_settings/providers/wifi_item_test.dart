import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';

void main() {
  // Simple mode pushes one security mode onto every band, but 6 GHz only
  // takes WPA3 or Enhanced Open.
  group('WifiRadioBand.simpleModeSecurityType', () {
    test('6 GHz turns any WPA mode into WPA3 Personal', () {
      expect(
        [
          WifiSecurityType.wpa2Personal,
          WifiSecurityType.wpa2Or3MixedPersonal,
          WifiSecurityType.wpa3Personal,
        ].map(WifiRadioBand.radio_6.simpleModeSecurityType),
        everyElement(WifiSecurityType.wpa3Personal),
      );
    });

    test('6 GHz turns any open mode into Enhanced Open only', () {
      expect(
        [
          WifiSecurityType.open,
          WifiSecurityType.enhancedOpenNone,
          WifiSecurityType.enhancedOpenOnly,
        ].map(WifiRadioBand.radio_6.simpleModeSecurityType),
        everyElement(WifiSecurityType.enhancedOpenOnly),
      );
    });

    test('the other bands keep the security mode simple mode pushes', () {
      for (final band in [
        WifiRadioBand.radio_24,
        WifiRadioBand.radio_5_1,
        WifiRadioBand.radio_5_2,
      ]) {
        expect(
          band.simpleModeSecurityType(WifiSecurityType.open),
          WifiSecurityType.open,
        );
        expect(
          band.simpleModeSecurityType(WifiSecurityType.wpa2Personal),
          WifiSecurityType.wpa2Personal,
        );
      }
    });
  });
}
