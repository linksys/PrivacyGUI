// Instant Verify's state as a map and as a value: the shape test/test_data
// gives the views, and what the state writes.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';

import '../../../test_data/instant_verify_test_state.dart';

void main() {
  test('reads the state as the test data writes it', () {
    final state = InstantVerifyState.fromMap(instantVerifyTestState);

    expect(state.wanConnection?.wanType, 'DHCP');
    expect(state.wanConnection?.ipAddress, '192.168.50.105');
    expect(state.radioInfo.radios, isNotEmpty);
    expect(state.guestRadioSettings.isGuestNetworkEnabled, isTrue);
    expect(state.guestRadioSettings.radios.map((radio) => radio.radioID),
        ['RADIO_5GHz', 'RADIO_2.4GHz', 'RADIO_6GHz']);
    expect(state.isRunning, isFalse);
  });

  test('reads a state with no WAN connection as none', () {
    final state =
        InstantVerifyState.fromMap(instantVerifyNoWanConnectionTestState);

    expect(state.wanConnection, isNull);
  });

  test('reads back from the map and the JSON it writes', () {
    final state = InstantVerifyState.fromMap(instantVerifyTestState)
        .copyWith(isRunning: true);

    final map = state.toMap();
    expect(map['isRunning'], isTrue);
    expect(map['wanConnection'], state.wanConnection!.toMap());
    expect(InstantVerifyState.fromMap(map), state);
    expect(InstantVerifyState.fromJson(state.toJson()), state);
  });

  test('leaves out a WAN connection it does not have', () {
    final state =
        InstantVerifyState.fromMap(instantVerifyNoWanConnectionTestState);

    expect(state.toMap().containsKey('wanConnection'), isFalse);
    expect(InstantVerifyState.fromJson(state.toJson()).wanConnection, isNull);
  });

  test('an edit keeps the fields it does not name', () {
    final state = InstantVerifyState.fromMap(instantVerifyTestState);

    final running = state.copyWith(isRunning: true);

    expect(running.wanConnection, same(state.wanConnection));
    expect(running.radioInfo, same(state.radioInfo));
    expect(running.guestRadioSettings, same(state.guestRadioSettings));
    expect(
        state
            .copyWith(
                radioInfo: const GetRadioInfo(
                    isBandSteeringSupported: false, radios: []))
            .isRunning,
        isFalse);
  });

  test('a state read twice is the same state', () {
    expect(InstantVerifyState.fromMap(instantVerifyTestState),
        InstantVerifyState.fromMap(instantVerifyTestState));
  });

  test('a change to the WAN connection or the radios is a change', () {
    final state = InstantVerifyState.fromMap(instantVerifyTestState);

    expect(
        state.copyWith(
            wanConnection:
                state.wanConnection!.copyWith(ipAddress: '10.0.0.2')),
        isNot(state));
    expect(
        state.copyWith(
            radioInfo:
                const GetRadioInfo(isBandSteeringSupported: false, radios: [])),
        isNot(state));
  });
}
