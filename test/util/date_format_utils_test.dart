import 'package:privacy_gui/util/date_format_utils.dart';
import 'package:test/test.dart';

void main() {
  group('test date format utils', () {
    test('formatDuration: formats simple duration correctly', () {
      const duration = Duration(hours: 1, minutes: 30, seconds: 15);
      expect(DateFormatUtils.formatDuration(duration), '1h 30m 15s');
    });

    test('formatDuration: formats duration with multiple units', () {
      const duration = Duration(days: 2, hours: 5, minutes: 20, seconds: 30);
      expect(DateFormatUtils.formatDuration(duration), '2d 5h 20m 30s');
    });

    test('formatDuration: formats zero-value durations', () {
      expect(DateFormatUtils.formatDuration(Duration.zero), '0s');
    });

    test('formatDuration: handles duration exceeding day unit', () {
      const duration = Duration(days: 100);
      expect(DateFormatUtils.formatDuration(duration), '100d 0h 0m 0s');
    });

    test('formatTimeMSS: formats single-digit minutes correctly', () {
      expect(DateFormatUtils.formatTimeMSS(123), '2:03');
    });

    test('formatTimeMSS: formats double-digit minutes correctly', () {
      expect(DateFormatUtils.formatTimeMSS(620), '10:20');
    });

    test('formatTimeMSS: formats zero minutes correctly', () {
      expect(DateFormatUtils.formatTimeMSS(59), '0:59');
    });

    test('formatTimeAmPm: formats single-digit hours correctly', () {
      expect(DateFormatUtils.formatTimeAmPm(3600), '01:00 am');
    });

    test('formatTimeAmPm: formats double-digit hours correctly', () {
      expect(DateFormatUtils.formatTimeAmPm(57600), '04:00 pm');
    });

    test('formatTimeAmPm: formats midnight correctly', () {
      expect(DateFormatUtils.formatTimeAmPm(0), '00:00 am');
    });

    test('formatTimeAmPm: formats midday correctly', () {
      expect(DateFormatUtils.formatTimeAmPm(43200), '12:00 pm');
    });

    test('formatTimeInterval: formats same-day time interval correctly', () {
      expect(DateFormatUtils.formatTimeInterval(61200, 67500),
          '05:00 pm - 06:45 pm');
    });

    test('formatTimeInterval: formats next-day time interval correctly', () {
      expect(DateFormatUtils.formatTimeInterval(86340, 3600),
          '11:59 pm - 01:00 am next day');
    });

    test(
        'formatTimeInterval: formats time interval spanning midnight correctly',
        () {
      expect(DateFormatUtils.formatTimeInterval(79200, 10800),
          '10:00 pm - 03:00 am next day');
    });

    test('formatTimeInterval: handles equal start and end times', () {
      expect(DateFormatUtils.formatTimeInterval(43200, 43200),
          '12:00 pm - 12:00 pm');
    });

    test('formatTimeHM: formats single-digit hours correctly', () {
      expect(DateFormatUtils.formatTimeHM(3600), '01 hr,00 min');
    });

    test('formatTimeHM: formats double-digit hours correctly', () {
      expect(DateFormatUtils.formatTimeHM(14400), '04 hr,00 min');
    });

    test('formatTimeHM: formats single-digit minutes correctly', () {
      expect(DateFormatUtils.formatTimeHM(60), '00 hr,01 min');
    });

    test('formatTimeHM: formats double-digit minutes correctly', () {
      expect(DateFormatUtils.formatTimeHM(1200), '00 hr,20 min');
    });

    test('formatTimeHM: formats zero time correctly', () {
      expect(DateFormatUtils.formatTimeHM(0), '00 hr,00 min');
    });

    test('formatTimeHM: handles large input (exceeding 24 hours)', () {
      expect(DateFormatUtils.formatTimeHM(86400 * 2), '48 hr,00 min');
    });
  });
}
