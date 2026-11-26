// The device detail page's state as a map: the shape test/test_data gives the
// views, and what the state writes.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/external_device_detail_state.dart';

import '../../../test_data/device_details_test_state.dart';

void main() {
  test('reads the device as the test data writes it', () {
    final state = ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);

    expect(state.item.deviceId, '807fc47c-fad4-4c5e-92b1-fe580415bfd5');
    expect(state.item.macAddress, '3C:22:FB:E4:4F:18');
  });

  test('writes back the map it was read from, and reads its JSON back', () {
    final state = ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);

    expect(state.toMap(), deviceDetailsTestState1);
    expect(ExternalDeviceDetailState.fromJson(state.toJson()), state);
  });

  test('a state read twice is the same state; another device is not', () {
    final state = ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);

    expect(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1), state);
    expect(state.copyWith(item: state.item.copyWith(name: 'Renamed')),
        isNot(state));
  });

  test('an edit with no device keeps the device', () {
    final state = ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);

    expect(state.copyWith().item, same(state.item));
    expect(
        state
            .copyWith(item: const DeviceListItem(deviceId: 'other'))
            .item
            .deviceId,
        'other');
  });
}
