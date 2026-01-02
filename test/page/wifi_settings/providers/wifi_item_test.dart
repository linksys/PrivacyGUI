import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';

void main() {
  WiFiItem createTestItem({
    WifiRadioBand radioID = WifiRadioBand.radio_5_1,
    String ssid = 'TestNetwork',
    String password = 'password123',
    WifiSecurityType securityType = WifiSecurityType.wpa2Personal,
    WifiWirelessMode wirelessMode = WifiWirelessMode.ac,
    WifiChannelWidth channelWidth = WifiChannelWidth.auto,
    int channel = 36,
    bool isBroadcast = true,
    bool isEnabled = true,
    int numOfDevices = 5,
  }) {
    return WiFiItem(
      radioID: radioID,
      ssid: ssid,
      password: password,
      securityType: securityType,
      wirelessMode: wirelessMode,
      channelWidth: channelWidth,
      channel: channel,
      isBroadcast: isBroadcast,
      isEnabled: isEnabled,
      availableSecurityTypes: const [
        WifiSecurityType.wpa2Personal,
        WifiSecurityType.wpa3Personal
      ],
      availableWirelessModes: const [WifiWirelessMode.ac, WifiWirelessMode.ax],
      availableChannels: const {
        WifiChannelWidth.auto: [36, 40, 44, 48]
      },
      numOfDevices: numOfDevices,
    );
  }

  group('WiFiItem', () {
    test('creates instance with required fields', () {
      final item = createTestItem();
      expect(item.radioID, WifiRadioBand.radio_5_1);
      expect(item.ssid, 'TestNetwork');
      expect(item.password, 'password123');
      expect(item.isEnabled, true);
    });

    test('copyWith updates specified fields', () {
      final original = createTestItem();
      final copied = original.copyWith(ssid: 'NewName', isEnabled: false);
      expect(copied.ssid, 'NewName');
      expect(copied.isEnabled, false);
      expect(copied.password, 'password123');
    });

    test('toMap converts to map correctly', () {
      final item = createTestItem(ssid: 'Test', channel: 40);
      final map = item.toMap();
      expect(map['ssid'], 'Test');
      expect(map['channel'], 40);
      expect(map['isEnabled'], true);
    });

    test('fromMap creates instance from map', () {
      final item = createTestItem();
      final map = item.toMap();
      final restored = WiFiItem.fromMap(map);
      expect(restored.ssid, item.ssid);
      expect(restored.channel, item.channel);
    });

    test('toJson/fromJson round-trip works', () {
      final original = createTestItem();
      final json = original.toJson();
      final restored = WiFiItem.fromJson(json);
      expect(restored.ssid, original.ssid);
      expect(restored.channel, original.channel);
    });

    test('equality comparison works', () {
      final item1 = createTestItem(ssid: 'Network1');
      final item2 = createTestItem(ssid: 'Network1');
      expect(item1, item2);
    });

    test('distinguishes different items', () {
      final item1 = createTestItem(ssid: 'Network1');
      final item2 = createTestItem(ssid: 'Network2');
      expect(item1, isNot(item2));
    });

    test('stringify returns true', () {
      final item = createTestItem();
      expect(item.stringify, true);
    });

    test('props contains all relevant fields', () {
      final item = createTestItem();
      expect(item.props, hasLength(14));
    });
  });
}
