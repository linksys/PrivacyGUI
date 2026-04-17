import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';

TimeSettingsUIModel _model({
  String currentLocalTime = '',
  String localTimeZone = '',
}) {
  return TimeSettingsUIModel(
    enable: true,
    status: 'Synchronized',
    currentLocalTime: currentLocalTime,
    localTimeZone: localTimeZone,
    ntpServer1: 'pool.ntp.org',
    ntpServer2: '',
  );
}

void main() {
  group('TimeSettingsUIModel', () {
    group('formattedDateTime', () {
      test('returns N/A for empty currentLocalTime', () {
        final m = _model(currentLocalTime: '');
        expect(m.formattedDateTime, 'N/A');
      });

      test('returns raw string for unparseable date', () {
        final m = _model(currentLocalTime: 'not-a-date');
        expect(m.formattedDateTime, 'not-a-date');
      });

      test('applies GMT+8 offset to UTC time', () {
        // UTC-8 in POSIX means GMT+8. Router stores POSIX string.
        final m = _model(
          currentLocalTime: '2026-04-17T04:00:00Z',
          localTimeZone: 'UTC-8', // matches SGT-8-NO-DST / HKT-8-NO-DST
        );
        expect(m.formattedDateTime, '2026-04-17 12:00:00');
      });

      test('applies GMT-5 offset (Eastern no DST)', () {
        final m = _model(
          currentLocalTime: '2026-04-17T12:00:00Z',
          localTimeZone: 'UTC5', // matches EST5-NO-DST posixNoDST
        );
        expect(m.formattedDateTime, '2026-04-17 07:00:00');
      });

      test('applies DST offset when DST is enabled', () {
        // EST5EDT,M3.2.0/02:00,M11.1.0/02:00 → base offset -300 min + 60 DST = -240
        final m = _model(
          currentLocalTime: '2026-04-17T12:00:00Z',
          localTimeZone: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
        );
        // -300 + 60 = -240 minutes = -4 hours → 12:00 - 4 = 08:00
        expect(m.formattedDateTime, '2026-04-17 08:00:00');
      });

      test('no offset applied for unrecognized timezone string', () {
        final m = _model(
          currentLocalTime: '2026-04-17T12:00:00Z',
          localTimeZone: 'UNKNOWN_TZ',
        );
        expect(m.formattedDateTime, '2026-04-17 12:00:00');
      });

      test('applies fractional offset GMT+5:30 (India)', () {
        final m = _model(
          currentLocalTime: '2026-04-17T06:00:00Z',
          localTimeZone: 'UTC-5:30', // matches IST-05:30-NO-DST posixNoDST
        );
        // +330 minutes = +5:30 → 06:00 + 5:30 = 11:30
        expect(m.formattedDateTime, '2026-04-17 11:30:00');
      });

      test('handles date rollover across midnight', () {
        final m = _model(
          currentLocalTime: '2026-04-17T22:00:00Z',
          localTimeZone: 'UTC-8', // GMT+8
        );
        // 22:00 + 8 = 30:00 → next day 06:00
        expect(m.formattedDateTime, '2026-04-18 06:00:00');
      });

      test('handles negative offset date rollback', () {
        final m = _model(
          currentLocalTime: '2026-04-17T02:00:00Z',
          localTimeZone: 'UTC5', // GMT-5
        );
        // 02:00 - 5 = -3:00 → previous day 21:00
        expect(m.formattedDateTime, '2026-04-16 21:00:00');
      });

      test('handles non-UTC datetime string (no Z suffix)', () {
        final m = _model(
          currentLocalTime: '2026-04-17T04:00:00',
          localTimeZone: 'UTC-8', // GMT+8
        );
        // DateTime.parse without Z creates local time, .toUtc() converts it.
        // The result depends on the test runner's timezone, so just verify
        // it returns a valid formatted string (not N/A or raw).
        expect(m.formattedDateTime, isNot('N/A'));
        expect(m.formattedDateTime,
            matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')));
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
