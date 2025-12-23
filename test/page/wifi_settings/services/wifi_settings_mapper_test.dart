import 'package:flutter_test/flutter_test.dart';

import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_mapper.dart';

void main() {
  final defaultWifiItem = WiFiItem(
    radioID: WifiRadioBand.radio_24,
    ssid: 'test',
    password: 'test',
    securityType: WifiSecurityType.wpa2Personal,
    wirelessMode: WifiWirelessMode.bgn,
    channelWidth: WifiChannelWidth.auto,
    channel: 1,
    isBroadcast: false,
    isEnabled: true,
    availableSecurityTypes: const [
      WifiSecurityType.wpa2Personal,
      WifiSecurityType.wpa3Personal,
      WifiSecurityType.wpa2Or3MixedPersonal,
    ],
    availableWirelessModes: const [WifiWirelessMode.bgn],
    availableChannels: const {
      WifiChannelWidth.auto: [1, 2, 3]
    },
    numOfDevices: 0,
  );
  group('WifiSettingsMapper - Security Type Logic', () {
    group('getSimpleModeAvailableSecurityTypeList', () {
      test('should return intersection of security types', () {
        final wifiItem1 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_24,
          availableSecurityTypes: const [
            WifiSecurityType.wpa2Personal,
            WifiSecurityType.wpa3Personal,
            WifiSecurityType.wpa2Or3MixedPersonal,
          ],
        );
        final wifiItem2 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_5_1,
          availableSecurityTypes: const [
            WifiSecurityType.wpa2Personal,
            WifiSecurityType.wpa3Personal,
          ],
        );

        final result =
            WifiSettingsMapper.getSimpleModeAvailableSecurityTypeList(
                [wifiItem1, wifiItem2]);

        expect(
            result,
            containsAll([
              WifiSecurityType.wpa2Personal,
              WifiSecurityType.wpa3Personal
            ]));
        expect(result.length, 2);
      });

      test('should return empty list for no common types', () {
        final wifiItem1 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_24,
          availableSecurityTypes: const [WifiSecurityType.wpa2Personal],
        );
        final wifiItem2 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_5_1,
          availableSecurityTypes: const [WifiSecurityType.wpa3Personal],
        );

        final result =
            WifiSettingsMapper.getSimpleModeAvailableSecurityTypeList(
                [wifiItem1, wifiItem2]);

        expect(result, isEmpty);
      });

      test('should return full list for a single wifi item', () {
        final wifiItem1 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_24,
          availableSecurityTypes: const [
            WifiSecurityType.wpa2Personal,
            WifiSecurityType.wpa3Personal,
          ],
        );

        final result =
            WifiSettingsMapper.getSimpleModeAvailableSecurityTypeList(
                [wifiItem1]);

        expect(result,
            [WifiSecurityType.wpa2Personal, WifiSecurityType.wpa3Personal]);
      });

      test('should return empty list when mainWiFi is empty', () {
        final result =
            WifiSettingsMapper.getSimpleModeAvailableSecurityTypeList([]);
        expect(result, isEmpty);
      });
    });

    group('getSimpleModeAvailableSecurityType', () {
      final availableList = [
        WifiSecurityType.wpa2Personal,
        WifiSecurityType.wpa3Personal,
        WifiSecurityType.wpa2Or3MixedPersonal,
        WifiSecurityType.wep,
      ];

      test('should return current type if it is in the available list', () {
        const current = WifiSecurityType.wpa2Personal;
        final result = WifiSettingsMapper.getSimpleModeAvailableSecurityType(
            current, availableList);
        expect(result, current);
      });

      test(
          'should return wpa3Personal if current is not available but wpa3Personal is',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final result = WifiSettingsMapper.getSimpleModeAvailableSecurityType(
            current, availableList);
        expect(result, WifiSecurityType.wpa3Personal);
      });

      test(
          'should return wpa2Or3MixedPersonal if wpa3Personal is not available',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final listWithoutWpa3 = [
          WifiSecurityType.wpa2Personal,
          WifiSecurityType.wpa2Or3MixedPersonal,
          WifiSecurityType.wep,
        ];
        final result = WifiSettingsMapper.getSimpleModeAvailableSecurityType(
            current, listWithoutWpa3);
        expect(result, WifiSecurityType.wpa2Or3MixedPersonal);
      });

      test('should return wpa2Personal if wpa3 and mixed are not available',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final listWithoutWpa3AndMixed = [
          WifiSecurityType.wpa2Personal,
          WifiSecurityType.wep,
        ];
        final result = WifiSettingsMapper.getSimpleModeAvailableSecurityType(
            current, listWithoutWpa3AndMixed);
        expect(result, WifiSecurityType.wpa2Personal);
      });

      test('should return the first item if no preferred types are available',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final listWithoutPreferred = [
          WifiSecurityType.wep,
          WifiSecurityType.open,
        ];
        final result = WifiSettingsMapper.getSimpleModeAvailableSecurityType(
            current, listWithoutPreferred);
        expect(result, WifiSecurityType.wep);
      });

      test('should return current type if available list is empty', () {
        const current = WifiSecurityType.wpaPersonal;
        final emptyList = <WifiSecurityType>[];
        final result = WifiSettingsMapper.getSimpleModeAvailableSecurityType(
            current, emptyList);
        expect(result, current);
      });
    });
  });
}
