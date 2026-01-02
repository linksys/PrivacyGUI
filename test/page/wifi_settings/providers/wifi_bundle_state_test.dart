import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  WiFiItem createWifiItem() {
    return const WiFiItem(
      radioID: WifiRadioBand.radio_5_1,
      ssid: 'TestNetwork',
      password: 'password123',
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

  WiFiListSettings createWifiListSettings() {
    return WiFiListSettings(
      mainWiFi: [createWifiItem()],
      guestWiFi: createGuestItem(),
      simpleModeWifi: createWifiItem(),
    );
  }

  group('WifiBundleSettings', () {
    test('creates instance with required fields', () {
      final settings = WifiBundleSettings(
        wifiList: createWifiListSettings(),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      expect(settings.wifiList.mainWiFi, hasLength(1));
      expect(settings.advanced.isIptvEnabled, isNull);
    });

    test('copyWith updates specified fields', () {
      final original = WifiBundleSettings(
        wifiList: createWifiListSettings(),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      const newAdvanced =
          WifiAdvancedSettingsState(isClientSteeringEnabled: true);
      final copied = original.copyWith(advanced: newAdvanced);
      expect(copied.advanced.isClientSteeringEnabled, true);
    });

    test('equality comparison works', () {
      final s1 = WifiBundleSettings(
        wifiList: createWifiListSettings(),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      final s2 = WifiBundleSettings(
        wifiList: createWifiListSettings(),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      expect(s1, s2);
    });
  });

  group('WifiBundleStatus', () {
    test('creates instance with required fields', () {
      final status = WifiBundleStatus(
        wifiList: const WiFiListStatus(),
        privacy: InstantPrivacyStatus.init(),
      );
      expect(status.wifiList.canDisableMainWiFi, true);
    });

    test('copyWith updates specified fields', () {
      final original = WifiBundleStatus(
        wifiList: const WiFiListStatus(),
        privacy: InstantPrivacyStatus.init(),
      );
      const newWifiList = WiFiListStatus(canDisableMainWiFi: false);
      final copied = original.copyWith(wifiList: newWifiList);
      expect(copied.wifiList.canDisableMainWiFi, false);
    });

    test('equality comparison works', () {
      final s1 = WifiBundleStatus(
        wifiList: const WiFiListStatus(),
        privacy: InstantPrivacyStatus.init(),
      );
      final s2 = WifiBundleStatus(
        wifiList: const WiFiListStatus(),
        privacy: InstantPrivacyStatus.init(),
      );
      expect(s1, s2);
    });
  });

  group('WifiBundleState', () {
    test('creates instance with required fields', () {
      final settings = WifiBundleSettings(
        wifiList: createWifiListSettings(),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      final status = WifiBundleStatus(
        wifiList: const WiFiListStatus(),
        privacy: InstantPrivacyStatus.init(),
      );
      final state = WifiBundleState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      expect(state.settings.original.wifiList.mainWiFi, hasLength(1));
      expect(state.status.wifiList.canDisableMainWiFi, true);
    });

    test('copyWith updates specified fields', () {
      final settings = WifiBundleSettings(
        wifiList: createWifiListSettings(),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      final status = WifiBundleStatus(
        wifiList: const WiFiListStatus(),
        privacy: InstantPrivacyStatus.init(),
      );
      final state = WifiBundleState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      final newStatus = WifiBundleStatus(
        wifiList: const WiFiListStatus(canDisableMainWiFi: false),
        privacy: InstantPrivacyStatus.init(),
      );
      final copied = state.copyWith(status: newStatus);
      expect(copied.status.wifiList.canDisableMainWiFi, false);
    });

    test('isDirty returns false when original equals current', () {
      final settings = WifiBundleSettings(
        wifiList: createWifiListSettings(),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      final status = WifiBundleStatus(
        wifiList: const WiFiListStatus(),
        privacy: InstantPrivacyStatus.init(),
      );
      final state = WifiBundleState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      expect(state.isDirty, false);
    });
  });
}
