import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';

void main() {
  group('kTimeZoneDefinitions', () {
    test('contains exactly 39 entries', () {
      expect(kTimeZoneDefinitions.length, 39);
    });

    test('all timeZoneIDs are unique', () {
      final ids = kTimeZoneDefinitions.map((tz) => tz.timeZoneID).toSet();
      expect(ids.length, kTimeZoneDefinitions.length);
    });

    test('sorted by utcOffsetMinutes ascending', () {
      for (int i = 1; i < kTimeZoneDefinitions.length; i++) {
        expect(
          kTimeZoneDefinitions[i].utcOffsetMinutes,
          greaterThanOrEqualTo(kTimeZoneDefinitions[i - 1].utcOffsetMinutes),
          reason:
              '${kTimeZoneDefinitions[i].timeZoneID} should come after ${kTimeZoneDefinitions[i - 1].timeZoneID}',
        );
      }
    });

    test('non-DST timezones have posixWithDST == posixNoDST', () {
      for (final tz in kTimeZoneDefinitions.where((tz) => !tz.observesDST)) {
        expect(tz.posixWithDST, tz.posixNoDST,
            reason: '${tz.timeZoneID} (no DST) should have matching POSIX');
      }
    });

    test('DST timezones have posixWithDST != posixNoDST', () {
      for (final tz in kTimeZoneDefinitions.where((tz) => tz.observesDST)) {
        expect(tz.posixWithDST, isNot(tz.posixNoDST),
            reason: '${tz.timeZoneID} (DST) should have different POSIX');
      }
    });

    test('DST count is 15, non-DST count is 24', () {
      final dstCount =
          kTimeZoneDefinitions.where((tz) => tz.observesDST).length;
      expect(dstCount, 15);
      expect(kTimeZoneDefinitions.length - dstCount, 24);
    });
  });

  group('matchTimezone', () {
    test('matches by timeZoneID', () {
      final result = matchTimezone('PST8');
      expect(result, isNotNull);
      expect(result!.timeZoneID, 'PST8');
    });

    test('matches by posixNoDST', () {
      final result = matchTimezone('UTC8');
      expect(result, isNotNull);
      expect(result!.utcOffsetMinutes, -480);
    });

    test('posixNoDST match prefers non-DST entry over DST entry', () {
      // UTC5 is shared by EST5 (DST) and EST5-NO-DST (no DST).
      // A bare "UTC5" string has no DST rules, so should match non-DST.
      final result = matchTimezone('UTC5');
      expect(result, isNotNull);
      expect(result!.observesDST, isFalse);
      expect(result.timeZoneID, 'EST5-NO-DST');
    });

    test('matches by posixWithDST', () {
      final result = matchTimezone('PST8PDT,M3.2.0/02:00,M11.1.0/02:00');
      expect(result, isNotNull);
      expect(result!.timeZoneID, 'PST8');
    });

    test('returns null for unknown string', () {
      expect(matchTimezone('UNKNOWN_TZ'), isNull);
    });

    test('matches fractional offset UTC-5:30', () {
      final result = matchTimezone('UTC-5:30');
      expect(result, isNotNull);
      expect(result!.timeZoneID, 'IST-05:30-NO-DST');
    });

    test('matches CST-8 by timeZoneID (not in definitions as ID)', () {
      final result = matchTimezone('CST-8');
      expect(result, isNull);
    });
  });

  group('inferDstEnabled', () {
    test('returns true when posixWithDST matches', () {
      final result = inferDstEnabled('PST8PDT,M3.2.0/02:00,M11.1.0/02:00');
      expect(result, isTrue);
    });

    test('returns false when posixNoDST matches', () {
      final result = inferDstEnabled('UTC8');
      expect(result, isFalse);
    });

    test('returns false for unknown string', () {
      final result = inferDstEnabled('UNKNOWN');
      expect(result, isFalse);
    });

    test('returns false for non-DST timezone ID match', () {
      final result = inferDstEnabled('HST10-NO-DST');
      expect(result, isFalse);
    });
  });
}
