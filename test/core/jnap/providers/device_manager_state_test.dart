// DeviceManagerState compares by value (constitution 4.2): the device manager's
// listeners and selects only hear of a change that equality sees.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

/// `GetGuestRadioSettings` output, with the guest network on or off.
GuestRadioSettings _guest({required bool enabled}) =>
    GuestRadioSettings.fromMap({
      'isGuestNetworkACaptivePortal': false,
      'isGuestNetworkEnabled': enabled,
      'radios': [
        {
          'radioID': 'RADIO_5GHz',
          'isEnabled': enabled,
          'broadcastGuestSSID': true,
          'guestSSID': 'fee_guest_qa_velop',
          'guestWPAPassphrase': 'TestWifi1!',
          'canEnableRadio': true,
        },
      ],
    });

void main() {
  test('two states that differ only in the guest network are not equal', () {
    final guestOn = DeviceManagerState(
        guestRadioSettings: _guest(enabled: true), lastUpdateTime: 1);
    final guestOff = DeviceManagerState(
        guestRadioSettings: _guest(enabled: false), lastUpdateTime: 1);

    expect(guestOff, isNot(guestOn));
    expect(
        DeviceManagerState(
            guestRadioSettings: _guest(enabled: true), lastUpdateTime: 1),
        guestOn);
  });

  test('a device reads back the MLO radios it wrote, from JSON text', () {
    final laptop = LinksysDevice(
      connections: const [
        RawDeviceConnection(
            macAddress: 'F2:B7:56:06:DD:D9', ipAddress: '192.168.1.130'),
      ],
      properties: const [],
      unit: const RawDeviceUnit(),
      deviceID: '667f4f5b-8b9a-4724-9171-97e01952a740',
      maxAllowedProperties: 16,
      model: const RawDeviceModel(deviceType: 'Computer'),
      isAuthority: false,
      lastChangeRevision: 6022,
      mloList: const ['RADIO_5GHz', 'RADIO_6GHz'],
    );

    final restored = LinksysDevice.fromJson(laptop.toJson());

    expect(restored.mloList, ['RADIO_5GHz', 'RADIO_6GHz']);
    expect(restored.deviceID, '667f4f5b-8b9a-4724-9171-97e01952a740');
  });
}
