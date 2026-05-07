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

      test('converts stale offset to correct target timezone', () {
        // Device returns +08:00 offset but timezone was changed to Alaska
        final m = _model(
          currentLocalTime: '2026-04-27T17:28:51+08:00',
          localTimeZone: 'AKST9AKDT,M3.2.0/02:00,M11.1.0/02:00',
        );
        // UTC = 17:28:51 - 8h = 09:28:51, Alaska = UTC-9 = 00:28:51
        expect(m.parsedLocalTime, DateTime(2026, 4, 27, 0, 28, 51));
      });

      test('converts negative offset to target timezone', () {
        // Device returns -08:00 offset but timezone was changed to GMT+8
        final m = _model(
          currentLocalTime: '2026-04-27T01:29:04-08:00',
          localTimeZone: 'UTC-8',
        );
        // UTC = 01:29:04 + 8h = 09:29:04, GMT+8 = UTC+8 = 17:29:04
        expect(m.parsedLocalTime, DateTime(2026, 4, 27, 17, 29, 4));
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
