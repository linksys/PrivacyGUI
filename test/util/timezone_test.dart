// The names the time zone page and Instant Admin show for the router's time
// zones (getTimeZoneRegionName), and the GMT offset they put before each name
// (getTimezoneGMT), read from the router's own description.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/util/timezone.dart';

import '../test_data/timezone_test_state.dart';

/// Each time zone ID the app names, with its English name (app_en.arb).
const _englishNames = {
  'GMT0-NO-DST': 'Gambia, Liberia, Morocco',
  'GST-4-NO-DST': 'Armenia',
  'EST5-NO-DST': 'Indiana East, Colombia, Panama',
  'AEST-10': 'Australia',
  'MST7-NO-DST': 'Arizona',
  'PKT-5-NO-DST': 'Pakistan, Russia',
  'ALMT-6-NO-DST': 'Bangladesh, Russia',
  'AZOT1': 'Azores',
  'BRT3': 'Brazil East, Greenland',
  'HST10-NO-DST': 'Hawaii',
  'CST6': 'Central Time (USA & Canada)',
  'PST8': 'Pacific Time (USA & Canada)',
  'JST-9-NO-DST': 'Japan, Korea',
  'EST5': 'Eastern Time (USA & Canada)',
  'ICT-7-NO-DST': 'Thailand, Russia',
  'HKT-8-NO-DST': 'China, Hong Kong, Australia Western',
  'WST11-NO-DST': 'Midway Island, Samoa',
  'FJT-12-NO-DST': 'Fiji',
  'NZST-12': 'New Zealand',
  'SBT-11-NO-DST': 'Solomon Islands',
  'CET-1': 'France, Germany, Italy',
  'MAT2-NO-DST': 'Mid-Atlantic',
  'MHT12-NO-DST': 'Kwajalein',
  'AST-3-NO-DST': 'Turkey, Iraq, Jordan, Kuwait',
  'CET-1-NO-DST': 'Tunisia',
  'ART3-NO-DST': 'Guyana',
  'IST-05:30-NO-DST': 'Mumbai, Kolkata, Chennai, New Delhi',
  'VET4-NO-DST': 'Bolivia, Venezuela',
  'GMT0': 'England',
  'SAST-2-NO-DST': 'South Africa',
  'AKST9': 'Alaska',
  'MST7': 'Mountain Time (USA & Canada)',
  'CLT4': 'Chile Time (Chile, Antarctica)',
  'AST4': 'Atlantic Time (Canada, Greenland, Atlantic Islands)',
  'NST03:30': 'Newfoundland',
  'EET-2': 'Greece, Ukraine, Romania',
  'GST-10-NO-DST': 'Guam, Russia',
  'CST6-NO-DST': 'Mexico',
  'SGT-8': 'Singapore, Taiwan, Russia',
  'SGT-8-NO-DST': 'Singapore, Taiwan, Russia',
};

void main() {
  late BuildContext context;

  Future<void> openEnglishApp(WidgetTester tester) =>
      tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (built) {
          context = built;
          return const SizedBox();
        }),
      ));

  group('getTimeZoneRegionName', () {
    testWidgets('names each time zone in English', (tester) async {
      await openEnglishApp(tester);

      for (final MapEntry(key: id, value: name) in _englishNames.entries) {
        expect(getTimeZoneRegionName(context, id), name, reason: id);
      }
    });

    testWidgets('names every time zone the router lists', (tester) async {
      await openEnglishApp(tester);
      final zones = timezoneTestState['supportedTimezones'] as List;

      for (final zone in zones) {
        final id = (zone as Map)['timeZoneID'] as String;
        expect(getTimeZoneRegionName(context, id), isNotEmpty, reason: id);
      }
    });

    testWidgets('gives no name to a time zone it does not know',
        (tester) async {
      await openEnglishApp(tester);

      expect(getTimeZoneRegionName(context, 'XYZ-5'), '');
    });
  });

  group('getTimezoneGMT', () {
    test('is the offset the router puts in brackets before its description',
        () {
      expect(getTimezoneGMT('(GMT+05:30) Bombay, Kalkutta, Madras, Neu Delhi'),
          'GMT+05:30');
      expect(getTimezoneGMT('(GMT-03:30) Newfoundland'), 'GMT-03:30');
      expect(getTimezoneGMT('(GMT) England'), 'GMT');
    });

    test('is empty for a description that does not start with one', () {
      expect(getTimezoneGMT('England (GMT)'), '');
      expect(getTimezoneGMT('England'), '');
    });
  });
}
