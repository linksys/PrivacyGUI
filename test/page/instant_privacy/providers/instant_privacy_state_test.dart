// Instant Privacy's state as the MAC filtering page compares it: the page
// holds the state it loaded and calls itself changed while the state differs.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

import '../../../test_data/instant_privacy_test_state.dart';

const _loaded = InstantPrivacyState(
  status: InstantPrivacyStatus(mode: MacFilterMode.allow),
  settings: InstantPrivacySettings(
    mode: MacFilterMode.allow,
    macAddresses: ['A4:BB:6D:00:00:10'],
    denyMacAddresses: [],
    maxMacAddresses: 32,
    bssids: ['80:69:1A:00:02:51'],
    myMac: 'A4:BB:6D:00:00:10',
  ),
);

/// The settings map InstantPrivacySettings writes for [_loaded].
const _loadedSettingsMap = <String, dynamic>{
  'mode': 'allow',
  'macAddresses': ['A4:BB:6D:00:00:10'],
  'denyMacAddresses': <String>[],
  'maxMacAddresses': 32,
  'bssids': ['80:69:1A:00:02:51'],
  'myMac': 'A4:BB:6D:00:00:10',
};

void main() {
  test('reads each mode the router names, and anything else as disabled', () {
    expect(MacFilterMode.reslove('Allow'), MacFilterMode.allow);
    expect(MacFilterMode.reslove('Deny'), MacFilterMode.deny);
    expect(MacFilterMode.reslove('Disabled'), MacFilterMode.disabled);
    expect(MacFilterMode.reslove('Block'), MacFilterMode.disabled);
  });

  test('starts with the filter off, no lists and room for 32 addresses', () {
    final state = InstantPrivacyState.init();

    expect(state.status.mode, MacFilterMode.disabled);
    expect(state.settings.mode, MacFilterMode.disabled);
    expect(state.settings.macAddresses, isEmpty);
    expect(state.settings.denyMacAddresses, isEmpty);
    expect(state.settings.maxMacAddresses, 32);
    expect(state.settings.bssids, isEmpty);
    expect(state.settings.myMac, isNull);
  });

  // Built at run time, as a fetch builds it, so that the comparison goes
  // through each class's props and not through one canonical const instance.
  test('the same filter read twice is unchanged', () {
    final readAgain = InstantPrivacyState.init().copyWith(
      status: InstantPrivacyStatus(mode: MacFilterMode.reslove('Allow')),
      settings: InstantPrivacySettings.init().copyWith(
        mode: MacFilterMode.reslove('Allow'),
        macAddresses: ['A4:BB:6D:00:00:10'],
        bssids: ['80:69:1A:00:02:51'],
        myMac: 'A4:BB:6D:00:00:10',
      ),
    );

    expect(readAgain, isNot(same(_loaded)));
    expect(readAgain, _loaded);
  });

  test('a change to the mode or to either list is a change', () {
    final settings = _loaded.settings;
    final edits = [
      _loaded.copyWith(settings: settings.copyWith(mode: MacFilterMode.deny)),
      _loaded.copyWith(
          settings: settings.copyWith(macAddresses: ['D2:60:CB:00:00:20'])),
      _loaded.copyWith(
          settings: settings.copyWith(denyMacAddresses: ['3C:22:FB:00:00:30'])),
      _loaded.copyWith(
          status: const InstantPrivacyStatus(mode: MacFilterMode.deny)),
    ];

    for (final edited in edits) {
      expect(edited, isNot(_loaded));
    }
  });

  test('an edit keeps the fields it does not name', () {
    final edited = _loaded.settings.copyWith(mode: MacFilterMode.deny);

    expect(edited.macAddresses, ['A4:BB:6D:00:00:10']);
    expect(edited.maxMacAddresses, 32);
    expect(edited.bssids, ['80:69:1A:00:02:51']);
    expect(edited.myMac, 'A4:BB:6D:00:00:10');
  });

  group('the status', () {
    test('writes and reads its mode by name', () {
      final status = InstantPrivacyStatus.fromMap(const {'mode': 'deny'});

      expect(status.mode, MacFilterMode.deny);
      expect(status.toMap(), {'mode': 'deny'});
      expect(InstantPrivacyStatus.fromJson(status.toJson()), status);
    });

    test('a changed mode is a change', () {
      final status = InstantPrivacyStatus.init();

      expect(
          status.copyWith(mode: MacFilterMode.allow).mode, MacFilterMode.allow);
      expect(status.copyWith(mode: MacFilterMode.allow), isNot(status));
      expect(status.copyWith(), status);
    });
  });

  group('the settings', () {
    test('write every field, and leave out an own address that is unknown', () {
      expect(_loaded.settings.toMap(), _loadedSettingsMap);
      expect(
        InstantPrivacySettings.init().toMap(),
        {
          'mode': 'disabled',
          'macAddresses': <String>[],
          'denyMacAddresses': <String>[],
          'maxMacAddresses': 32,
          'bssids': <String>[],
        },
      );
    });

    test('read back as the same settings', () {
      final settings = InstantPrivacySettings.fromMap(_loadedSettingsMap);

      expect(settings, _loaded.settings);
      expect(InstantPrivacySettings.fromJson(settings.toJson()), settings);
    });

    test('read as the test data writes them, with no own address', () {
      final settings = InstantPrivacySettings.fromMap(
          instantPrivacyTestState['settings'] as Map<String, dynamic>);

      expect(settings.mode, MacFilterMode.disabled);
      expect(settings.maxMacAddresses, 56);
      expect(settings.bssids, hasLength(4));
      expect(settings.myMac, isNull);
    });

    test('read with no BSSIDs as none', () {
      final settings = InstantPrivacySettings.fromMap(
          Map.of(_loadedSettingsMap)..remove('bssids'));

      expect(settings.bssids, isEmpty);
    });
  });

  test('the state reads as the test data writes it', () {
    final state = InstantPrivacyState.fromMap(instantPrivacyTestState);

    expect(state.status.mode, MacFilterMode.disabled);
    expect(state.settings.mode, MacFilterMode.disabled);
    expect(state.settings.maxMacAddresses, 56);
  });
}
