import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';
import 'package:privacy_gui/page/admin/views/dialogs/timezone_edit_dialog.dart';

/// Tests for the timezone edit dialog's data model and logic.
///
/// The actual dialog widget depends on showSubmitAppDialog → AppDialog → GoRouter
/// + localization + Material ancestry, making isolated widget tests impractical.
/// These tests verify the result model, search logic, and integration behavior
/// that the dialog relies on.
void main() {
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

  // linksys/FWDEV#198. What a Save hands back: a catalogue row's ID and the DST
  // setting, which `SetTimeSettings` saves together.
  group('buildTimezoneEditResult', () {
    // `buildTimezoneEditResult` is the real thing the dialog calls, not a copy.
    TimezoneEditResult? save(
      TimeZoneInfo selected, {
      required bool dstEnabled,
      TimeZoneInfo? from,
      bool fromDst = true,
      String ntp = 'pool.ntp.org',
      String currentNtp = 'pool.ntp.org',
    }) =>
        buildTimezoneEditResult(
          selected: selected,
          dstEnabled: dstEnabled,
          currentTz: from,
          currentDst: fromDst,
          ntpValue: ntp,
          currentNtp: currentNtp,
        );

    TimeZoneInfo zone(String id) =>
        kTimeZoneDefinitions.firstWhere((tz) => tz.timeZoneID == id);

    test('a chosen zone is sent as its ID, with its DST setting', () {
      final result = save(zone('EST5'), dstEnabled: true)!;

      expect(result.zone?.id, 'EST5');
      expect(result.zone?.autoAdjustForDst, isTrue);
      expect(result.ntpServer1, isNull);
    });

    test('daylight savings off is the same ID with DST false', () {
      final result = save(zone('EST5'), dstEnabled: false)!;

      expect(result.zone?.id, 'EST5',
          reason: 'not the non-DST sibling EST5-NO-DST — that is Panama');
      expect(result.zone?.autoAdjustForDst, isFalse);
    });

    test('a zone without DST keeps its -NO-DST ID', () {
      final result = save(zone('JST-9-NO-DST'), dstEnabled: false)!;

      expect(result.zone?.id, 'JST-9-NO-DST',
          reason: 'the bare JST-9 is ErrorUnknownTimeZone on the device');
    });

    test('a zone without DST never sends DST true', () {
      // The firmware answers ErrorTimeZoneDoesNotObserveDST, so a stale switch
      // value must not reach it.
      final result = save(zone('JST-9-NO-DST'), dstEnabled: true)!;

      expect(result.zone?.autoAdjustForDst, isFalse);
    });

    test('changing nothing writes nothing at all', () {
      final result = save(zone('EST5'), dstEnabled: true, from: zone('EST5'));

      expect(result, isNull,
          reason:
              'both call sites already return early on a null result, which '
              'is exactly the handling a no-change Save needs');
    });

    test('changing only the NTP server leaves the zone alone', () {
      final result = save(
        zone('EST5'),
        dstEnabled: true,
        from: zone('EST5'),
        ntp: 'time.cloudflare.com',
      )!;

      expect(result.ntpServer1, 'time.cloudflare.com');
      expect(result.zone?.id, isNull,
          reason: 'writing the resolved zone back would commit a guess for a '
              'zone the device could not name');
      expect(result.zone?.autoAdjustForDst, isNull);
    });

    test('flipping only the switch still writes the zone', () {
      final result = save(zone('EST5'), dstEnabled: false, from: zone('EST5'))!;

      expect(result.zone?.id, 'EST5');
      expect(result.zone?.autoAdjustForDst, isFalse);
    });

    test('a zone change and an NTP change travel together', () {
      final result = save(
        zone('SGT-8-NO-DST'),
        dstEnabled: false,
        from: zone('HKT-8-NO-DST'),
        fromDst: false,
        ntp: 'time.cloudflare.com',
      )!;

      expect(result.zone?.id, 'SGT-8-NO-DST');
      expect(result.ntpServer1, 'time.cloudflare.com');
    });

    test('NTP cleared is sent as an empty string', () {
      final result = save(
        zone('EST5'),
        dstEnabled: true,
        from: zone('EST5'),
        ntp: '',
      )!;

      expect(result.ntpServer1, '');
    });
  });
}
