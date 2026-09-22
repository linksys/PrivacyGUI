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

    // The firmware clears the name whenever the POSIX leaf is written, which is
    // what keeps the two consistent — but that is the firmware's promise, not
    // ours, and something else (the device's own zone list, a CLI, a cloud push)
    // could leave a name behind that the clock contradicts.
    test('a name the reported offset contradicts is not believed', () {
      final tz = resolveTimezone(
        zoneName: 'Asia/Taipei', // GMT+8
        localTimeZone: 'UTC-9', // JST, and what the device is really on
        reportedOffsetMinutes: 540,
      );
      expect(tz?.timeZoneID, 'JST-9-NO-DST',
          reason: 'the POSIX string agrees with the clock; the name does not');
    });

    test('a DST-observing name is believed at its DST offset', () {
      // New York in September: standard -300, reported -240.
      final tz = resolveTimezone(
        zoneName: 'America/New_York',
        localTimeZone: 'EST5EDT,M3.2.0,M11.1.0',
        reportedOffsetMinutes: -240,
      );
      expect(tz?.timeZoneID, 'EST5');
    });

    test('a non-DST name is not believed an hour off', () {
      final tz = resolveTimezone(
        zoneName: 'Asia/Singapore', // no DST, so +540 cannot be right
        localTimeZone: 'JST-9',
        reportedOffsetMinutes: 540,
      );
      expect(tz?.timeZoneID, isNot('SGT-8-NO-DST'));
    });

    test('with no clock reading the name is taken at face value', () {
      final tz = resolveTimezone(
        zoneName: 'Asia/Singapore',
        localTimeZone: 'UTC-9',
        reportedOffsetMinutes: null,
      );
      expect(tz?.timeZoneID, 'SGT-8-NO-DST');
    });
  });

  // Not the same question as `TimeZoneInfo.observesDST`, and conflating them was
  // a live regression: four legacy values are owned by exactly one entry and that
  // entry observes DST, so reading `observesDST` told the user daylight savings
  // was on for a router sitting on a fixed offset.
  group('dstInEffect', () {
    test('a name carries its own DST rule', () {
      expect(
          dstInEffect(
              zoneName: 'America/New_York',
              localTimeZone: 'EST5EDT,M3.2.0,M11.1.0'),
          isTrue);
      expect(dstInEffect(zoneName: 'Asia/Singapore', localTimeZone: '<+08>-8'),
          isFalse);
    });

    test('the four legacy values whose only owner observes DST read Off', () {
      // `UTC8`/`UTC9`/`UTC1`/`UTC3:30` have no non-DST sibling, so they resolve
      // to `PST8`/`AKST9`/`AZOT1`/`NST03:30`. The strings themselves carry no
      // transitions, so the device is not observing DST.
      for (final legacy in ['UTC8', 'UTC9', 'UTC1', 'UTC3:30']) {
        final resolved = matchTimezone(legacy);
        expect(resolved?.observesDST, isTrue,
            reason:
                '$legacy must still resolve to a DST-capable entry, or this '
                'test is no longer measuring the trap');
        expect(dstInEffect(zoneName: '', localTimeZone: legacy), isFalse,
            reason: '$legacy has no DST transitions in it');
      }
    });

    test('a legacy posixWithDST string reads On', () {
      expect(
          dstInEffect(
              zoneName: '',
              localTimeZone: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00'),
          isTrue);
    });

    test('an unresolvable string reads Off rather than throwing', () {
      expect(dstInEffect(zoneName: '', localTimeZone: 'UTC'), isFalse);
      expect(dstInEffect(zoneName: '', localTimeZone: ''), isFalse);
    });

    // The veto has to be applied here as well as in `resolveTimezone`, or the two
    // disagree: the label comes from the POSIX string because the clock
    // contradicts the name, while the DST state still comes off the name. The
    // card would then show Hong Kong with daylight savings on.
    // Switching daylight savings off is what used to relabel the zone, and it is
    // safe again because of *what* it writes. `standardTimePosix` is the zone's
    // own abbreviation, which is also its `timeZoneID`, and `matchTimezone` tries
    // ids before anything else — so it comes back as itself rather than as
    // whichever zone happened to share the old `UTC±N`.
    test('every switchable zone round-trips with daylight savings off', () {
      final switchable =
          kTimeZoneDefinitions.where((tz) => tz.canSwitchDstOff).toList();
      expect(switchable, hasLength(11));
      for (final tz in switchable) {
        final written = tz.standardTimePosix!;
        expect(matchTimezone(written)?.timeZoneID, tz.timeZoneID,
            reason: '${tz.timeZoneID} does not read back as itself');
        expect(dstInEffect(zoneName: '', localTimeZone: written), isFalse,
            reason: '$written must not read as daylight savings on');
      }
    });

    test('it stays distinguishable from the sibling non-DST zone', () {
      // The pairs that shared a `UTC±N` and so swapped labels. One goes out as a
      // POSIX abbreviation, the other as an IANA name, on different leaves.
      const pairs = {
        'EST5': 'America/Panama',
        'MST7': 'America/Phoenix',
        'CST6': 'America/Mexico_City',
        'AST4': 'America/Caracas',
        'GMT0': 'Africa/Monrovia',
        'CET-1': 'Africa/Tunis',
      };
      pairs.forEach((posix, name) {
        final dstOff = resolveTimezone(zoneName: '', localTimeZone: posix);
        final sibling = resolveTimezone(zoneName: name, localTimeZone: posix);
        expect(dstOff?.timeZoneID, posix);
        expect(sibling?.ianaName, name);
        expect(dstOff!.timeZoneID, isNot(sibling!.timeZoneID),
            reason:
                '$posix and $name must not resolve to the same entry — that '
                'was the defect');
      });
    });

    test('the four zones the firmware refuses cannot be switched', () {
      // `CLT4`, `NST3:30`, `BRT3` and `AZOT1` are rejected by the validator:
      // obsolete abbreviations that modern tzdata spells `-04`, `-03`, `-01`,
      // and no supported-zone row to fall back on. Bench-measured.
      final unswitchable = kTimeZoneDefinitions
          .where((tz) => tz.observesDST && !tz.canSwitchDstOff)
          .map((tz) => tz.timeZoneID)
          .toSet();
      expect(unswitchable, {'CLT4', 'NST03:30', 'BRT3', 'AZOT1'});
    });

    test('no non-DST zone carries a standardTimePosix', () {
      for (final tz in kTimeZoneDefinitions.where((t) => !t.observesDST)) {
        expect(tz.standardTimePosix, isNull,
            reason: '${tz.timeZoneID} has no daylight savings to switch off');
      }
    });

    test('a vetoed name does not get to decide the DST state', () {
      const args = (
        zoneName: 'America/New_York', // observes DST, standard -300
        localTimeZone: 'UTC-8', // GMT+8, no DST, and what the clock agrees with
        reported: 480,
      );
      expect(
          resolveTimezone(
            zoneName: args.zoneName,
            localTimeZone: args.localTimeZone,
            reportedOffsetMinutes: args.reported,
          )?.timeZoneID,
          'HKT-8-NO-DST');
      expect(
          dstInEffect(
            zoneName: args.zoneName,
            localTimeZone: args.localTimeZone,
            reportedOffsetMinutes: args.reported,
          ),
          isFalse,
          reason: 'the label resolved to Hong Kong, so the DST row must not be '
              'answering for New York');
    });
  });
}
