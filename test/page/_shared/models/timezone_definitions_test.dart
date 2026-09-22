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

  // #1609. `matchTimezone` reads a POSIX string, which is a clock rule and not
  // an identity, so it cannot tell two zones sharing one rule apart. The zone
  // *name* can: it is what we now write, and the device hands it straight back.
  group('matchByZoneName', () {
    test('resolves the zone the user actually chose', () {
      expect(matchByZoneName('Asia/Singapore')?.timeZoneID, 'SGT-8-NO-DST');
      expect(matchByZoneName('Asia/Hong_Kong')?.timeZoneID, 'HKT-8-NO-DST');
    });

    test('tells apart the pair no POSIX string can', () {
      // Both zones are GMT+8 with no DST, so both used to store `UTC-8` and
      // both came back as Hong Kong.
      final sg = matchByZoneName('Asia/Singapore');
      final hk = matchByZoneName('Asia/Hong_Kong');
      expect(sg, isNotNull);
      expect(hk, isNotNull);
      expect(sg!.timeZoneID, isNot(hk!.timeZoneID));
      expect(sg.posixNoDST, hk.posixNoDST,
          reason:
              'the legacy strings really were identical — that was the bug');
    });

    test('is null for an empty name', () {
      expect(matchByZoneName(''), isNull);
    });

    test('is null for a name no entry of ours claims', () {
      // A real IANA zone, and one the device offers, but outside our 39.
      expect(matchByZoneName('Europe/Dublin'), isNull);
    });

    test('every ianaName is unique across the table', () {
      final names = kTimeZoneDefinitions
          .map((tz) => tz.ianaName)
          .whereType<String>()
          .toList();
      expect(names.length, 36);
      expect(names.toSet().length, names.length,
          reason: 'a shared ianaName would reintroduce the ambiguity this '
              'replaces');
    });

    test('the three entries with stale data carry no ianaName', () {
      // Kwajalein is UTC+12 since 1993, Brazil dropped DST in 2019, and Guyana
      // is UTC-4 — so no IANA name means what these labels say. They keep
      // writing POSIX until the data is settled.
      final unnamed = kTimeZoneDefinitions
          .where((tz) => tz.ianaName == null)
          .map((tz) => tz.timeZoneID)
          .toSet();
      expect(unnamed, {'MHT12-NO-DST', 'BRT3', 'ART3-NO-DST'});
    });

    test('a named entry agrees with its own DST flag', () {
      // A DST-observing entry must not point at a zone with no DST rule, or the
      // indicator would contradict the firmware.
      for (final tz in kTimeZoneDefinitions.where((t) => t.ianaName != null)) {
        expect(matchByZoneName(tz.ianaName!)?.observesDST, tz.observesDST,
            reason: '${tz.timeZoneID} round-trips to a different DST flag');
      }
    });
  });

  group('resolveTimezone', () {
    test('prefers the zone name when the device sent one', () {
      final tz = resolveTimezone(
        zoneName: 'Asia/Singapore',
        localTimeZone: 'CST-8',
      );
      expect(tz?.timeZoneID, 'SGT-8-NO-DST');
    });

    test('falls back to POSIX when the zone name is empty', () {
      // What a router written by 2.7.1 or earlier looks like: the POSIX string
      // is set and `X_LINKSYS_LocalTimeZoneName` is empty (#1609 AC8).
      final tz = resolveTimezone(zoneName: '', localTimeZone: 'UTC-8');
      expect(tz?.timeZoneID, 'HKT-8-NO-DST');
    });

    test('falls back to POSIX when the zone name is not one of ours', () {
      final tz = resolveTimezone(
        zoneName: 'Europe/Dublin',
        localTimeZone: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00',
      );
      expect(tz?.timeZoneID, 'PST8');
    });

    test('is null when neither resolves', () {
      expect(resolveTimezone(zoneName: '', localTimeZone: 'UTC'), isNull);
      expect(resolveTimezone(zoneName: 'Europe/Dublin', localTimeZone: 'CST-8'),
          isNull);
    });
  });
}
