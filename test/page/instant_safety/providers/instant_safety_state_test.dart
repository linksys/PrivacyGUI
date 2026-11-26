// Instant Safety's state as a map: the shape test/test_data gives the views,
// and what the state writes.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';

import '../../../test_data/safe_browsing_test_state.dart';

void main() {
  test('reads each safe browsing type by name, and anything else as off', () {
    expect(InstantSafetyType.reslove('fortinet'), InstantSafetyType.fortinet);
    expect(InstantSafetyType.reslove('openDNS'), InstantSafetyType.openDNS);
    expect(InstantSafetyType.reslove('off'), InstantSafetyType.off);
    expect(InstantSafetyType.reslove('OpenDNS'), InstantSafetyType.off);
  });

  test('reads the state as the test data writes it', () {
    final state = InstantSafetyState.fromMap(instantSafetyTestState);

    expect(state.lanSetting?.ipAddress, '10.137.1.1');
    expect(state.lanSetting?.dhcpSettings.leaseMinutes, 1440);
    expect(state.safeBrowsingType, InstantSafetyType.off);
    expect(state.hasFortinet, isTrue);
  });

  test('writes back the map it was read from', () {
    final state = InstantSafetyState.fromMap(instantSafetyTestState);

    expect(state.toMap(), instantSafetyTestState);
    expect(InstantSafetyState.fromJson(state.toJson()), state);
  });

  test('without LAN settings, writes none and reads none back', () {
    final state = InstantSafetyState.fromMap(const {
      'safeBrowsingType': 'openDNS',
      'hasFortinet': false,
    });

    expect(state.lanSetting, isNull);
    expect(state.toMap(), {
      'lanSetting': null,
      'safeBrowsingType': 'openDNS',
      'hasFortinet': false,
    });
    expect(InstantSafetyState.fromJson(state.toJson()), state);
  });

  test('reads a state with no type as off', () {
    expect(
      InstantSafetyState.fromMap(const {'hasFortinet': false}).safeBrowsingType,
      InstantSafetyType.off,
    );
  });

  test('a state read twice is the same state; a changed field is not', () {
    final state = InstantSafetyState.fromMap(instantSafetyTestState);

    expect(InstantSafetyState.fromMap(instantSafetyTestState), state);
    for (final edited in [
      state.copyWith(safeBrowsingType: InstantSafetyType.openDNS),
      state.copyWith(hasFortinet: false),
      state.copyWith(
          lanSetting: state.lanSetting!.copyWith(hostName: 'Renamed')),
    ]) {
      expect(edited, isNot(state));
    }
  });

  test('an edit keeps the fields it does not name', () {
    final state = InstantSafetyState.fromMap(instantSafetyTestState);

    final edited = state.copyWith(safeBrowsingType: InstantSafetyType.openDNS);

    expect(edited.lanSetting, same(state.lanSetting));
    expect(edited.hasFortinet, isTrue);
    expect(state.copyWith(hasFortinet: false).safeBrowsingType,
        InstantSafetyType.off);
  });
}
