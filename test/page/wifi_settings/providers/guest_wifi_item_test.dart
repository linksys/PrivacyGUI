import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';

void main() {
  group('GuestWiFiItem', () {
    test('creates instance with required fields', () {
      const item = GuestWiFiItem(
        isEnabled: false,
        ssid: '',
        password: '',
        numOfDevices: 0,
      );
      expect(item.isEnabled, false);
      expect(item.ssid, '');
      expect(item.password, '');
      expect(item.numOfDevices, 0);
    });

    test('creates instance with custom values', () {
      const item = GuestWiFiItem(
        isEnabled: true,
        ssid: 'GuestNetwork',
        password: 'password123',
        numOfDevices: 5,
      );
      expect(item.isEnabled, true);
      expect(item.ssid, 'GuestNetwork');
      expect(item.password, 'password123');
      expect(item.numOfDevices, 5);
    });

    test('copyWith updates specified fields', () {
      const original = GuestWiFiItem(
        isEnabled: false,
        ssid: 'Guest',
        password: 'oldPass',
        numOfDevices: 0,
      );
      final copied = original.copyWith(isEnabled: true, password: 'newPass');
      expect(copied.isEnabled, true);
      expect(copied.ssid, 'Guest');
      expect(copied.password, 'newPass');
    });

    test('toMap converts to map correctly', () {
      const item = GuestWiFiItem(
        isEnabled: true,
        ssid: 'Guest',
        password: 'pass',
        numOfDevices: 3,
      );
      final map = item.toMap();
      expect(map['isEnabled'], true);
      expect(map['ssid'], 'Guest');
      expect(map['password'], 'pass');
      expect(map['numOfDevices'], 3);
    });

    test('fromMap creates instance from map', () {
      final map = {
        'isEnabled': true,
        'ssid': 'GuestNet',
        'password': 'secret',
        'numOfDevices': 2,
      };
      final item = GuestWiFiItem.fromMap(map);
      expect(item.isEnabled, true);
      expect(item.ssid, 'GuestNet');
      expect(item.numOfDevices, 2);
    });

    test('toJson/fromJson round-trip works', () {
      const original = GuestWiFiItem(
        isEnabled: true,
        ssid: 'Guest',
        password: 'pass',
        numOfDevices: 5,
      );
      final json = original.toJson();
      final restored = GuestWiFiItem.fromJson(json);
      expect(restored, original);
    });

    test('equality comparison works', () {
      const item1 = GuestWiFiItem(
        isEnabled: true,
        ssid: 'Guest',
        password: '',
        numOfDevices: 0,
      );
      const item2 = GuestWiFiItem(
        isEnabled: true,
        ssid: 'Guest',
        password: '',
        numOfDevices: 0,
      );
      expect(item1, item2);
    });

    test('distinguishes different items', () {
      const item1 = GuestWiFiItem(
        isEnabled: true,
        ssid: 'Guest1',
        password: '',
        numOfDevices: 0,
      );
      const item2 = GuestWiFiItem(
        isEnabled: true,
        ssid: 'Guest2',
        password: '',
        numOfDevices: 0,
      );
      expect(item1, isNot(item2));
    });

    test('props returns correct list', () {
      const item = GuestWiFiItem(
        isEnabled: true,
        ssid: 'G',
        password: 'p',
        numOfDevices: 1,
      );
      expect(item.props,
          [item.isEnabled, item.ssid, item.password, item.numOfDevices]);
    });

    test('stringify returns true', () {
      const item = GuestWiFiItem(
        isEnabled: true,
        ssid: 'G',
        password: 'p',
        numOfDevices: 1,
      );
      expect(item.stringify, true);
    });
  });
}
