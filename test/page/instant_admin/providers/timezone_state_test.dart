import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';

const _state = <String, dynamic>{
  'isDaylightSaving': true,
  'timezoneId': 'NST03:30',
  'supportedTimezones': [
    {
      'observesDST': true,
      'timeZoneID': 'NST03:30',
      'description': '(GMT-03:30) Newfoundland',
      'utcOffsetMinutes': -210,
    },
  ],
  'error': null,
};

void main() {
  group('TimezoneState', () {
    test('starts on PST8 with DST on and no zones', () {
      final state = TimezoneState.init();

      expect(state.timezoneId, 'PST8');
      expect(state.isDaylightSaving, isTrue);
      expect(state.supportedTimezones, isEmpty);
      expect(state.error, isNull);
    });

    test('reads and writes the same map', () {
      final state = TimezoneState.fromMap(_state);

      expect(state.timezoneId, 'NST03:30');
      expect(state.supportedTimezones.single.utcOffsetMinutes, -210);
      expect(state.toMap(), _state);
    });

    test('survives a JSON round trip', () {
      final state = TimezoneState.fromMap(_state);
      final copy = TimezoneState.fromJson(state.toJson());

      expect(copy, state);
      expect(copy.supportedTimezones, state.supportedTimezones);
    });

    test('copyWith changes what it is given and keeps the rest', () {
      final state = TimezoneState.fromMap(_state)
          .copyWith(timezoneId: 'PST8', isDaylightSaving: false);

      expect(state.timezoneId, 'PST8');
      expect(state.isDaylightSaving, isFalse);
      expect(state.supportedTimezones.single.timeZoneID, 'NST03:30');
      expect(state, isNot(TimezoneState.fromMap(_state)));
    });

    test('two states with different zone lists are different', () {
      // Both read from maps, so neither is a canonical const instance.
      final state = TimezoneState.fromMap(_state);
      final noZones = TimezoneState.fromMap(
          Map.of(_state)..['supportedTimezones'] = <Object>[]);

      expect(noZones, isNot(state));
      expect(TimezoneState.fromMap(Map.of(_state)), state);
    });

    test('copyWith keeps the DST switch when it is given none', () {
      final state = TimezoneState.fromMap(_state).copyWith(timezoneId: 'PST8');

      expect(state.timezoneId, 'PST8');
      expect(state.isDaylightSaving, isTrue);
    });
  });
}
