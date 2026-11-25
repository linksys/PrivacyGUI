import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

void main() {
  group('DeviceListItem', () {
    test('has a signal strength to show only while online over Wi-Fi', () {
      const onWifi = DeviceListItem(isOnline: true, isWired: false);

      expect(onWifi.isOnlineWireless, isTrue);
      expect(onWifi.copyWith(isWired: true).isOnlineWireless, isFalse);
      expect(onWifi.copyWith(isOnline: false).isOnlineWireless, isFalse);
    });

    test('an edit to one field keeps the others', () {
      const phone = DeviceListItem(
        deviceId: 'phone',
        name: 'Alice iPhone',
        ipv4Address: '192.168.1.120',
        signalStrength: -48,
        isOnline: true,
      );

      final renamed = phone.copyWith(name: 'Bob iPhone');

      expect(renamed.name, 'Bob iPhone');
      expect(renamed, phone.copyWith(name: 'Bob iPhone'));
      expect(renamed, isNot(phone));
      expect(renamed.copyWith(name: 'Alice iPhone'), phone);
    });
  });
}
