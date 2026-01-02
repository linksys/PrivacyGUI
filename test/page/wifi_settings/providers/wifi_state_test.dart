import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';

void main() {
  WiFiItem createWifiItem() {
    return const WiFiItem(
      radioID: WifiRadioBand.radio_5_1,
      ssid: 'Network',
      password: 'password',
      securityType: WifiSecurityType.wpa2Personal,
      wirelessMode: WifiWirelessMode.ac,
      channelWidth: WifiChannelWidth.auto,
      channel: 36,
      isBroadcast: true,
      isEnabled: true,
      availableSecurityTypes: [WifiSecurityType.wpa2Personal],
      availableWirelessModes: [WifiWirelessMode.ac],
      availableChannels: {},
      numOfDevices: 5,
    );
  }

  GuestWiFiItem createGuestItem() {
    return const GuestWiFiItem(
      isEnabled: false,
      ssid: 'Guest',
      password: 'secret',
      numOfDevices: 0,
    );
  }

  group('WiFiListSettings', () {
    test('creates instance with required fields', () {
      final settings = WiFiListSettings(
        mainWiFi: [createWifiItem()],
        guestWiFi: createGuestItem(),
        simpleModeWifi: createWifiItem(),
      );
      expect(settings.mainWiFi, hasLength(1));
      expect(settings.isSimpleMode, true);
    });

    test('copyWith updates specified fields', () {
      final original = WiFiListSettings(
        mainWiFi: [createWifiItem()],
        guestWiFi: createGuestItem(),
        simpleModeWifi: createWifiItem(),
      );
      final copied = original.copyWith(isSimpleMode: false);
      expect(copied.isSimpleMode, false);
      expect(copied.mainWiFi, hasLength(1));
    });

    test('toMap/fromMap serialization works', () {
      final original = WiFiListSettings(
        mainWiFi: [createWifiItem()],
        guestWiFi: createGuestItem(),
        simpleModeWifi: createWifiItem(),
      );
      final map = original.toMap();
      final restored = WiFiListSettings.fromMap(map);
      expect(restored.mainWiFi, hasLength(1));
      expect(restored.isSimpleMode, true);
    });

    test('equality comparison works', () {
      final s1 = WiFiListSettings(
        mainWiFi: [],
        guestWiFi: createGuestItem(),
        simpleModeWifi: createWifiItem(),
      );
      final s2 = WiFiListSettings(
        mainWiFi: [],
        guestWiFi: createGuestItem(),
        simpleModeWifi: createWifiItem(),
      );
      expect(s1, s2);
    });
  });

  group('WiFiListStatus', () {
    test('creates instance with default values', () {
      const status = WiFiListStatus();
      expect(status.canDisableMainWiFi, true);
    });

    test('creates instance with custom values', () {
      const status = WiFiListStatus(canDisableMainWiFi: false);
      expect(status.canDisableMainWiFi, false);
    });

    test('copyWith updates specified fields', () {
      const status = WiFiListStatus();
      final copied = status.copyWith(canDisableMainWiFi: false);
      expect(copied.canDisableMainWiFi, false);
    });

    test('toMap/fromMap serialization works', () {
      const original = WiFiListStatus(canDisableMainWiFi: false);
      final map = original.toMap();
      final restored = WiFiListStatus.fromMap(map);
      expect(restored.canDisableMainWiFi, false);
    });

    test('equality comparison works', () {
      const s1 = WiFiListStatus(canDisableMainWiFi: true);
      const s2 = WiFiListStatus(canDisableMainWiFi: true);
      expect(s1, s2);
    });

    test('props returns correct list', () {
      const status = WiFiListStatus();
      expect(status.props, [status.canDisableMainWiFi]);
    });
  });
}
