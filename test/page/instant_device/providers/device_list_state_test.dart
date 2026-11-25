import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

import '../../../test_data/device_details_test_state.dart';
import '../../../test_data/device_list_test_state.dart';

/// A device item as test/test_data writes it, with every field.
Map<String, dynamic> get _itemMap =>
    deviceDetailsTestState1['item'] as Map<String, dynamic>;

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
      expect(renamed, isNot(phone));
      expect(renamed.copyWith(name: 'Alice iPhone'), phone);
    });

    test('reads an item as the test data writes it', () {
      final item = DeviceListItem.fromMap(_itemMap);

      expect(item.deviceId, '807fc47c-fad4-4c5e-92b1-fe580415bfd5');
      expect(item.name, 'ASTWP-29134');
      expect(item.ipv4Address, '10.216.1.30');
      expect(item.band, '5GHz');
      expect(item.signalStrength, -34);
      expect(item.isOnline, isTrue);
      expect(item.isWired, isFalse);
      expect(item.type, WifiConnectionType.main);
      expect(item.ssid, 'Linksys03041');
      expect(item.isMLO, isFalse);
    });

    test('writes back the map it was read from, and reads its JSON back', () {
      final item = DeviceListItem.fromMap(_itemMap);

      expect(item.toMap(), _itemMap);
      expect(DeviceListItem.fromJson(item.toJson()), item);
    });

    test('reads an item written before MLO as not MLO', () {
      final first = ((deviceListTestState['devices'] as List).first as Map)
          .cast<String, dynamic>();

      expect(first.containsKey('isMLO'), isFalse);
      expect(DeviceListItem.fromMap(first).isMLO, isFalse);
    });

    test('an item read twice is the same item; a change to any field is not',
        () {
      final item = DeviceListItem.fromMap(_itemMap);

      expect(DeviceListItem.fromMap(_itemMap), item);
      final edits = [
        item.copyWith(deviceId: 'other'),
        item.copyWith(name: 'other'),
        item.copyWith(icon: 'other'),
        item.copyWith(upstreamDevice: 'other'),
        item.copyWith(upstreamDeviceID: 'other'),
        item.copyWith(upstreamIcon: 'other'),
        item.copyWith(ipv4Address: 'other'),
        item.copyWith(ipv6Address: 'other'),
        item.copyWith(macAddress: 'other'),
        item.copyWith(manufacturer: 'other'),
        item.copyWith(model: 'other'),
        item.copyWith(operatingSystem: 'other'),
        item.copyWith(band: 'other'),
        item.copyWith(signalStrength: -90),
        item.copyWith(isOnline: false),
        item.copyWith(isWired: true),
        item.copyWith(type: WifiConnectionType.guest),
        item.copyWith(ssid: 'other'),
        item.copyWith(isMLO: true),
      ];
      for (final edited in edits) {
        expect(edited, isNot(item));
      }
    });
  });

  group('DeviceListState', () {
    test('reads the list as the test data writes it', () {
      final state = DeviceListState.fromMap(deviceListTestState);

      expect(state.devices,
          hasLength((deviceListTestState['devices'] as List).length));
      expect(
          state.devices.first.deviceId, '290a9b5e-2e5d-452b-a18b-8cb4d6a303e3');
    });

    test('writes each device as its map, and reads its JSON back', () {
      final state =
          DeviceListState(devices: [DeviceListItem.fromMap(_itemMap)]);

      expect(state.toMap(), {
        'devices': [_itemMap],
      });
      expect(DeviceListState.fromJson(state.toJson()), state);
    });

    test('a list read twice is the same list; another list is not', () {
      final state = DeviceListState.fromMap(deviceListTestState);

      expect(DeviceListState.fromMap(deviceListTestState), state);
      expect(state.copyWith(devices: state.devices.skip(1).toList()),
          isNot(state));
      expect(state.copyWith().devices, same(state.devices));
    });
  });
}
