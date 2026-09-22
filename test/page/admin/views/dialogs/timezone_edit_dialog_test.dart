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

  // #1609 replaces the old `Dialog DST toggle logic` group. Daylight savings is
  // no longer an input: it was writable, and switching it off wrote the zone's
  // no-DST POSIX string — which is not a distinguishable thing, because
  // "Eastern Time without DST" is the same clock rule as Panama and the device's
  // own `EST5` row *is* Panama. The zone therefore came back relabelled. The
  // list already carries both variants as separate entries, so the choice is
  // still there; it is made by picking a zone, the way 1.x did it.
  group('Dialog daylight-savings display', () {
    test('a DST zone read from the device reports DST on', () {
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
        ntpServer1: '',
        ntpServer2: '',
      );
      final tz = resolveTimezone(
        zoneName: settings.localTimeZoneName,
        localTimeZone: settings.localTimeZone,
      );
      expect(tz?.observesDST, isTrue);
    });

    test('a non-DST zone reports DST off', () {
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'CST-8',
        localTimeZoneName: 'Asia/Singapore',
        ntpServer1: '',
        ntpServer2: '',
      );
      final tz = resolveTimezone(
        zoneName: settings.localTimeZoneName,
        localTimeZone: settings.localTimeZone,
      );
      expect(tz?.observesDST, isFalse);
    });

    test('a legacy UTC±N string still resolves, to its non-DST sibling', () {
      // AC8: what releases up to 2.7.1 wrote is still readable.
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'UTC5',
        ntpServer1: '',
        ntpServer2: '',
      );
      final tz = resolveTimezone(
        zoneName: settings.localTimeZoneName,
        localTimeZone: settings.localTimeZone,
      );
      expect(tz?.timeZoneID, 'EST5-NO-DST');
      expect(tz?.observesDST, isFalse);
    });
  });

  // #1609 AC5. The dialog's own contract: what it hands back for a chosen zone.
  group('Dialog result carries an identity', () {
    test('a named zone is written by name, never by POSIX string', () {
      final sg = kTimeZoneDefinitions
          .firstWhere((tz) => tz.timeZoneID == 'SGT-8-NO-DST');
      final result = TimezoneEditResult(
        zoneName: sg.ianaName,
        localTimeZone: sg.ianaName == null
            ? sg.posixFor(dstEnabled: sg.observesDST)
            : null,
      );
      expect(result.zoneName, 'Asia/Singapore');
      expect(result.localTimeZone, isNull,
          reason: 'the two leaves clobber each other in the firmware, so only '
              'one may be sent');
    });

    test('an unnamed zone falls back to its POSIX string', () {
      // Brazil East has no `ianaName`: Brazil abolished DST in 2019, so no IANA
      // zone matches this entry's `observesDST: true`.
      final br =
          kTimeZoneDefinitions.firstWhere((tz) => tz.timeZoneID == 'BRT3');
      final result = TimezoneEditResult(
        zoneName: br.ianaName,
        localTimeZone: br.ianaName == null
            ? br.posixFor(dstEnabled: br.observesDST)
            : null,
      );
      expect(result.zoneName, isNull);
      expect(result.localTimeZone, br.posixWithDST);
    });

    test('every named zone round-trips to the entry it came from', () {
      for (final tz in kTimeZoneDefinitions.where((t) => t.ianaName != null)) {
        expect(matchByZoneName(tz.ianaName!)?.timeZoneID, tz.timeZoneID,
            reason: '${tz.timeZoneID} does not read back as itself');
      }
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
