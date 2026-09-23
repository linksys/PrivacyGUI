import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';

TimeSettingsUIModel _model({
  String currentLocalTime = '',
  String localTimeZone = '',
  String localTimeZoneName = '',
}) {
  return TimeSettingsUIModel(
    enable: true,
    status: 'Synchronized',
    currentLocalTime: currentLocalTime,
    localTimeZone: localTimeZone,
    localTimeZoneName: localTimeZoneName,
    ntpServer1: 'pool.ntp.org',
    ntpServer2: '',
  );
}

void main() {
  group('TimeSettingsUIModel', () {
    group('parsedLocalTime', () {
      test('returns null for empty currentLocalTime', () {
        final m = _model(currentLocalTime: '');
        expect(m.parsedLocalTime, isNull);
      });

      test('returns null for unparseable date', () {
        final m = _model(currentLocalTime: 'not-a-date');
        expect(m.parsedLocalTime, isNull);
      });

      test('parses ISO 8601 with Z suffix', () {
        final m = _model(currentLocalTime: '2026-04-17T12:00:00Z');
        expect(m.parsedLocalTime, DateTime(2026, 4, 17, 12, 0, 0));
      });

      test('parses ISO 8601 without Z suffix', () {
        final m = _model(currentLocalTime: '2026-04-17T04:00:00');
        expect(m.parsedLocalTime, DateTime(2026, 4, 17, 4, 0, 0));
      });

      test('parses date/time with space separator', () {
        final m = _model(currentLocalTime: '2026-04-17 22:30:15');
        expect(m.parsedLocalTime, DateTime(2026, 4, 17, 22, 30, 15));
      });

      test('converts offset to target timezone (offset matches timezone)', () {
        final m = _model(
          currentLocalTime: '2026-04-17T08:00:00+08:00',
          localTimeZone: 'UTC-8',
        );
        expect(m.parsedLocalTime, DateTime(2026, 4, 17, 8, 0, 0));
      });

      // These two replace `converts stale offset to correct target timezone`
      // and `converts negative offset to target timezone` (#1609). Those pinned
      // a re-derivation of the wall clock from `kTimeZoneDefinitions`, which
      // existed to compensate for a `CurrentLocalTime` whose offset lagged
      // behind `LocalTimeZone`. That premise does not hold: on FLWRT 2.0 the
      // offset is current the instant the zone is set, and `timeDataProvider`
      // reads all six `Device.Time.*` paths in one `Get` under a single
      // throttler cacheKey, so the offset and the zone cannot diverge on the
      // way in. Re-deriving cost us an hour under DST and the whole offset for
      // any zone the table does not carry.
      test('trusts the device offset rather than re-deriving it', () {
        final m = _model(
          currentLocalTime: '2026-04-27T17:28:51+08:00',
          localTimeZone: 'AKST9AKDT,M3.2.0/02:00,M11.1.0/02:00',
        );
        expect(m.parsedLocalTime, DateTime(2026, 4, 27, 17, 28, 51));
      });

      test('trusts a negative device offset rather than re-deriving it', () {
        final m = _model(
          currentLocalTime: '2026-04-27T01:29:04-08:00',
          localTimeZone: 'UTC-8',
        );
        expect(m.parsedLocalTime, DateTime(2026, 4, 27, 1, 29, 4));
      });
    });

    // #1609 defect 1. Every case here is a real reading from the bench
    // (M60TB-EU, FLWRT 2.0.x): the firmware applies the POSIX DST rule itself,
    // so the offset it reports is already the one in force at that instant.
    group('parsedLocalTime — the clock the device reports is the clock we show',
        () {
      test('DST in force: Pacific in July is -07:00, not the table\'s -08:00',
          () {
        final m = _model(
          currentLocalTime: '2026-07-15T14:00:00-07:00',
          localTimeZone: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00',
        );
        expect(m.parsedLocalTime, DateTime(2026, 7, 15, 14, 0, 0));
      });

      test('DST in force: CEST in July is +02:00', () {
        final m = _model(
          currentLocalTime: '2026-07-15T14:00:00+02:00',
          localTimeZone: 'CET-1CEST,M3.5.0/02:00,M10.5.0/03:00',
        );
        expect(m.parsedLocalTime, DateTime(2026, 7, 15, 14, 0, 0));
      });

      test('DST in force: NZDT in January is +13:00', () {
        final m = _model(
          currentLocalTime: '2026-01-15T14:00:00+13:00',
          localTimeZone: 'NZST-12NZDT,M9.5.0/02:00,M4.1.0/03:00',
        );
        expect(m.parsedLocalTime, DateTime(2026, 1, 15, 14, 0, 0));
      });

      test('standard time on a DST-capable zone is unchanged', () {
        final m = _model(
          currentLocalTime: '2026-01-15T14:00:00-08:00',
          localTimeZone: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00',
        );
        expect(m.parsedLocalTime, DateTime(2026, 1, 15, 14, 0, 0));
      });

      // The table carries none of these four, and dropping the offset without
      // putting one back showed UTC. `CST-8` and `<+08>-8` are the device's own
      // values (`X_LINKSYS_SupportedZones`) for Taipei and Singapore, `SGT-8`
      // is the 1.x JNAP id, and the last is how the device spells the same
      // Pacific rule we write with explicit `/02:00` suffixes.
      for (final tz in const [
        'CST-8',
        '<+08>-8',
        'SGT-8',
        'PST-8',
      ]) {
        test('unrecognized zone $tz keeps the device offset', () {
          final m = _model(
            currentLocalTime: '2026-09-22T18:30:00+08:00',
            localTimeZone: tz,
          );
          expect(m.parsedLocalTime, DateTime(2026, 9, 22, 18, 30, 0));
        });
      }

      test("unrecognized zone in the device's own DST spelling keeps -07:00",
          () {
        final m = _model(
          currentLocalTime: '2026-07-15T14:00:00-07:00',
          localTimeZone: 'PST8PDT,M3.2.0,M11.1.0',
        );
        expect(m.parsedLocalTime, DateTime(2026, 7, 15, 14, 0, 0));
      });
    });

    // #1609 AC9. The device reports its offset on every read, so an
    // unrecognized `LocalTimeZone` still has one true fact to show. Without
    // this the cards printed the raw POSIX string — `UTC` on a factory-fresh
    // box, `<+08>-8` once anything sets the zone from the device's own list.
    group('reportedOffsetMinutes', () {
      test('reads a positive offset', () {
        expect(
            _model(currentLocalTime: '2026-09-22T18:30:00+08:00')
                .reportedOffsetMinutes,
            480);
      });

      test('reads a negative offset', () {
        expect(
            _model(currentLocalTime: '2026-07-15T14:00:00-07:00')
                .reportedOffsetMinutes,
            -420);
      });

      test('reads a fractional offset', () {
        expect(
            _model(currentLocalTime: '2026-09-22T18:30:00+05:30')
                .reportedOffsetMinutes,
            330);
      });

      test('Z means zero, not absent', () {
        expect(
            _model(currentLocalTime: '2026-09-22T10:30:00Z')
                .reportedOffsetMinutes,
            0);
      });

      test('is null when the string carries no offset at all', () {
        expect(
            _model(currentLocalTime: '2026-09-22T10:30:00')
                .reportedOffsetMinutes,
            isNull);
      });

      test('is null for an empty or unparseable string', () {
        expect(_model(currentLocalTime: '').reportedOffsetMinutes, isNull);
        expect(_model(currentLocalTime: 'not-a-date').reportedOffsetMinutes,
            isNull);
      });
    });

    // #1609. The identity the device hands back, alongside the POSIX string.
    // It has to reach `props`, or a change of zone that leaves the offset alone
    // — Singapore to Hong Kong — would not notify a watcher.
    group('localTimeZoneName', () {
      test('defaults to empty, which is what a 2.7.1-era router reports', () {
        const m = TimeSettingsUIModel(
          enable: true,
          status: 'Synchronized',
          currentLocalTime: '2026-09-22T18:30:00+08:00',
          localTimeZone: 'UTC-8',
          ntpServer1: '',
          ntpServer2: '',
        );
        expect(m.localTimeZoneName, '');
      });

      test('two models differing only by zone name are not equal', () {
        final sg = _model(
          currentLocalTime: '2026-09-22T18:30:00+08:00',
          localTimeZone: 'CST-8',
          localTimeZoneName: 'Asia/Singapore',
        );
        final hk = _model(
          currentLocalTime: '2026-09-22T18:30:00+08:00',
          localTimeZone: 'CST-8',
          localTimeZoneName: 'Asia/Hong_Kong',
        );
        expect(sg, isNot(hk));
      });
    });

    group('formattedDateTime', () {
      test('returns N/A for empty currentLocalTime', () {
        final m = _model(currentLocalTime: '');
        expect(m.formattedDateTime, 'N/A');
      });

      test('returns raw string for unparseable date', () {
        final m = _model(currentLocalTime: 'not-a-date');
        expect(m.formattedDateTime, 'not-a-date');
      });

      test('formats parsed date/time correctly', () {
        final m = _model(currentLocalTime: '2026-04-17T12:00:00Z');
        expect(m.formattedDateTime, '2026-04-17 12:00:00');
      });

      test('timezone string does not affect output', () {
        final a = _model(
          currentLocalTime: '2026-04-17T12:00:00Z',
          localTimeZone: 'UTC-8',
        );
        final b = _model(
          currentLocalTime: '2026-04-17T12:00:00Z',
          localTimeZone: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
        );
        expect(a.formattedDateTime, b.formattedDateTime);
      });
    });

    group('formatDateTime', () {
      test('formats DateTime with zero-padded fields', () {
        expect(
          TimeSettingsUIModel.formatDateTime(DateTime(2026, 1, 5, 3, 7, 9)),
          '2026-01-05 03:07:09',
        );
      });
    });

    group('isSynchronized', () {
      test('returns true when status is Synchronized', () {
        expect(
          TimeSettingsUIModel(
            enable: true,
            status: 'Synchronized',
            currentLocalTime: '',
            localTimeZone: '',
            ntpServer1: '',
            ntpServer2: '',
          ).isSynchronized,
          isTrue,
        );
      });

      test('returns false for other status', () {
        expect(
          TimeSettingsUIModel(
            enable: true,
            status: 'Unsynchronized',
            currentLocalTime: '',
            localTimeZone: '',
            ntpServer1: '',
            ntpServer2: '',
          ).isSynchronized,
          isFalse,
        );
      });
    });

    group('equality', () {
      test('equal models have same props', () {
        final a = _model(currentLocalTime: '2026-01-01T00:00:00Z');
        final b = _model(currentLocalTime: '2026-01-01T00:00:00Z');
        expect(a, equals(b));
      });

      test('different models are not equal', () {
        final a = _model(currentLocalTime: '2026-01-01T00:00:00Z');
        final b = _model(currentLocalTime: '2026-01-02T00:00:00Z');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
