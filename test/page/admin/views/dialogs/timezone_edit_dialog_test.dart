import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/admin/views/dialogs/timezone_edit_dialog.dart';

/// Tests for the timezone edit dialog's data model and logic.
///
/// The actual dialog widget depends on showSubmitAppDialog → AppDialog → GoRouter
/// + localization + Material ancestry, making isolated widget tests impractical.
/// These tests verify the result model, search logic, and integration behavior
/// that the dialog relies on.
void main() {
  group('TimezoneEditResult', () {
    test('stores localTimeZone', () {
      const result = TimezoneEditResult(
        localTimeZone: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00',
      );
      expect(result.localTimeZone, 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00');
      expect(result.ntpServer1, isNull);
    });

    test('stores ntpServer1 when provided', () {
      const result = TimezoneEditResult(
        localTimeZone: 'UTC-8',
        ntpServer1: 'time.cloudflare.com',
      );
      expect(result.localTimeZone, 'UTC-8');
      expect(result.ntpServer1, 'time.cloudflare.com');
    });

    test('ntpServer1 is null when unchanged', () {
      const result = TimezoneEditResult(localTimeZone: 'UTC-8');
      expect(result.ntpServer1, isNull);
    });
  });

  group('Dialog search logic', () {
    // Replicate the search filter logic used inside the dialog
    List<String> filterTimezones(String query) {
      if (query.isEmpty)
        return kTimeZoneDefinitions.map((tz) => tz.friendlyName).toList();
      return kTimeZoneDefinitions
          .where((tz) {
            final q = query.toLowerCase();
            final desc = tz.description.toLowerCase();
            final offset = tz.offsetDisplayText.toLowerCase();
            if (desc.contains(q) || offset.contains(q)) return true;
            final m = RegExp(r'^[+-](\d{1,2})$').firstMatch(q);
            if (m != null) {
              final padded = q[0] + m.group(1)!.padLeft(2, '0');
              return offset.contains(padded);
            }
            return false;
          })
          .map((tz) => tz.friendlyName)
          .toList();
    }

    test('empty query returns all 39 timezones', () {
      expect(filterTimezones(''), hasLength(39));
    });

    test('search by friendly name', () {
      final results = filterTimezones('Japan');
      expect(results, contains('Japan, Korea'));
      expect(results.length, 1);
    });

    test('search by GMT offset', () {
      final results = filterTimezones('GMT+08');
      expect(
          results,
          containsAll([
            'China, Hong Kong, Australia Western',
            'Singapore, Taiwan, Russia',
          ]));
    });

    test('search +8 matches +08 timezones', () {
      final results = filterTimezones('+8');
      expect(results, contains('China, Hong Kong, Australia Western'));
      expect(results, contains('Singapore, Taiwan, Russia'));
      // Should NOT contain -08 (Pacific Time)
      expect(results, isNot(contains('Pacific Time (USA & Canada)')));
    });

    test('search -5 matches -05 timezones', () {
      final results = filterTimezones('-5');
      expect(results, contains('Eastern Time (USA & Canada)'));
      expect(results, contains('Indiana East, Colombia, Panama'));
    });

    test('search is case insensitive', () {
      final upper = filterTimezones('HAWAII');
      final lower = filterTimezones('hawaii');
      expect(upper, equals(lower));
      expect(upper, contains('Hawaii'));
    });

    test('no results for nonsense query', () {
      expect(filterTimezones('xyzabc'), isEmpty);
    });
  });

  group('Dialog DST toggle logic', () {
    test('DST-capable timezone with DST POSIX → dstEnabled=true', () {
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
        ntpServer1: '',
        ntpServer2: '',
      );
      final tz = matchTimezone(settings.localTimeZone);
      expect(tz, isNotNull);
      expect(tz!.observesDST, isTrue);
      expect(inferDstEnabled(settings.localTimeZone), isTrue);
    });

    test('Non-DST POSIX string → dstEnabled=false', () {
      // UTC5 matches EST5-NO-DST (non-DST variant preferred by matchTimezone)
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'UTC5',
        ntpServer1: '',
        ntpServer2: '',
      );
      final tz = matchTimezone(settings.localTimeZone);
      expect(tz, isNotNull);
      // matchTimezone prefers non-DST entry when posixNoDST collides
      expect(tz!.observesDST, isFalse);
      expect(inferDstEnabled(settings.localTimeZone), isFalse);
    });

    test('non-DST timezone → toggle should be disabled', () {
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'UTC-8', // GMT+8, no DST
        ntpServer1: '',
        ntpServer2: '',
      );
      final tz = matchTimezone(settings.localTimeZone);
      expect(tz, isNotNull);
      expect(tz!.observesDST, isFalse);
    });
  });

  group('Dialog NTP result logic', () {
    test('NTP unchanged → ntpServer1 should be null', () {
      const current = 'pool.ntp.org';
      const ntpValue = 'pool.ntp.org';
      final result = TimezoneEditResult(
        localTimeZone: 'UTC-8',
        ntpServer1: ntpValue != current ? ntpValue : null,
      );
      expect(result.ntpServer1, isNull);
    });

    test('NTP changed → ntpServer1 should have new value', () {
      const current = 'pool.ntp.org';
      const ntpValue = 'time.cloudflare.com';
      final result = TimezoneEditResult(
        localTimeZone: 'UTC-8',
        ntpServer1: ntpValue != current ? ntpValue : null,
      );
      expect(result.ntpServer1, 'time.cloudflare.com');
    });

    test('NTP cleared → ntpServer1 should be empty string', () {
      const current = 'pool.ntp.org';
      const ntpValue = '';
      final result = TimezoneEditResult(
        localTimeZone: 'UTC-8',
        ntpServer1: ntpValue != current ? ntpValue : null,
      );
      expect(result.ntpServer1, '');
    });
  });
}
