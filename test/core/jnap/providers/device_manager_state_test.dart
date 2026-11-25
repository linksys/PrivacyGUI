// DeviceManagerState compares by value (constitution 4.2): the device manager's
// listeners and selects only hear of a change that equality sees.

import 'package:flutter_test/flutter_test.dart';
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
}
