import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';

/// One entry of `GetTimeSettings`' `supportedTimeZones`, as the router lists it.
const _newfoundland = <String, dynamic>{
  'observesDST': true,
  'timeZoneID': 'NST03:30',
  'description': '(GMT-03:30) Newfoundland',
  'utcOffsetMinutes': -210,
};

void main() {
  group('SupportedTimezone', () {
    test('reads the zone the router lists', () {
      final zone = SupportedTimezone.fromMap(_newfoundland);

      expect(zone.timeZoneID, 'NST03:30');
      expect(zone.description, '(GMT-03:30) Newfoundland');
      expect(zone.utcOffsetMinutes, -210);
      expect(zone.observesDST, isTrue);
    });

    test('writes back the shape it read', () {
      expect(SupportedTimezone.fromMap(_newfoundland).toMap(), _newfoundland);
    });

    test('survives a JSON round trip', () {
      final zone = SupportedTimezone.fromMap(_newfoundland);

      expect(SupportedTimezone.fromJson(zone.toJson()), zone);
    });

    test('copyWith changes what it is given and keeps the rest', () {
      final zone =
          SupportedTimezone.fromMap(_newfoundland).copyWith(observesDST: false);

      expect(zone.observesDST, isFalse);
      expect(zone.timeZoneID, 'NST03:30');
      expect(zone.utcOffsetMinutes, -210);
      expect(zone, isNot(SupportedTimezone.fromMap(_newfoundland)));
    });

    test('copyWith keeps the DST flag when it is given none', () {
      final zone = SupportedTimezone.fromMap(_newfoundland)
          .copyWith(description: 'Newfoundland');

      expect(zone.description, 'Newfoundland');
      expect(zone.observesDST, isTrue);
    });

    test('describes itself by its fields', () {
      expect(SupportedTimezone.fromMap(_newfoundland).toString(),
          allOf(contains('SupportedTimezone'), contains('NST03:30')));
    });

    test('two zones with the same fields are equal', () {
      expect(SupportedTimezone.fromMap(_newfoundland),
          SupportedTimezone.fromMap(Map.of(_newfoundland)));
    });
  });
}
