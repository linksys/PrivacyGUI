// The list, duration and locale helpers in util/extensions.dart that the app
// calls: de-duplicating lists (Instant Privacy, the device filters), the DHCP
// lease time left (troubleshooting), and the language picker's locales.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/util/extensions.dart';

void main() {
  group('unique', () {
    test('drops repeats, keeping the first of each, in place', () {
      final macs = ['A1:B2', 'C3:D4', 'A1:B2', 'E5:F6', 'C3:D4'];

      final result = macs.unique();

      expect(result, ['A1:B2', 'C3:D4', 'E5:F6']);
      expect(macs, ['A1:B2', 'C3:D4', 'E5:F6']);
    });

    test('tells repeats apart by the key it is given', () {
      final radios = [
        (band: '2.4GHz', ssid: 'Home'),
        (band: '5GHz', ssid: 'Home'),
        (band: '2.4GHz', ssid: 'Guest'),
      ];

      expect(radios.unique((radio) => radio.band), [
        (band: '2.4GHz', ssid: 'Home'),
        (band: '5GHz', ssid: 'Home'),
      ]);
    });

    test('can leave the list it was called on as it was', () {
      final ssids = ['Home', 'Home'];

      expect(ssids.unique(null, false), ['Home']);
      expect(ssids, ['Home', 'Home']);
    });

    test('of an empty list is empty', () {
      expect(<String>[].unique(), isEmpty);
    });
  });

  group('convertToHMS', () {
    test('writes hours, minutes and seconds in two digits each', () {
      expect(const Duration(hours: 1, minutes: 2, seconds: 3).convertToHMS(),
          '01:02:03');
      expect(Duration.zero.convertToHMS(), '00:00:00');
    });

    test('lets the hours run past a day', () {
      expect(const Duration(hours: 26, seconds: 59).convertToHMS(),
          '26:00:59');
    });

    test('puts a minus sign before a time already past', () {
      expect(const Duration(minutes: -5, seconds: -7).convertToHMS(),
          '-00:05:07');
    });
  });

  group('the language picker', () {
    test('shows a locale by its own name for itself', () {
      expect(const Locale('de').displayText, 'Deutsch');
      expect(const Locale('zh', 'TW').displayText, '繁體中文');
      expect(const Locale('es', 'AR').displayText, 'Español - Argentina');
    });

    test('shows a locale it has no name for as English', () {
      expect(const Locale('xx').displayText, 'English - United States');
    });
  });

  group('LocaleExt.fromLanguageTag', () {
    // How AppSettings reads back the locale it saved.
    test('reads a language, a language and region, or all three subtags', () {
      expect(LocaleExt.fromLanguageTag('fr'), const Locale('fr'));
      expect(LocaleExt.fromLanguageTag('fr-CA'), const Locale('fr', 'CA'));
      expect(
          LocaleExt.fromLanguageTag('zh-Hant-TW'),
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'));
    });

    test('reads the first three subtags of a longer tag', () {
      expect(
          LocaleExt.fromLanguageTag('zh-Hant-TW-x'),
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'));
    });
  });
}
