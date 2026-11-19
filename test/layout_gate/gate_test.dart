import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../common/config.dart';
import 'gate.dart';
import 'incident.dart';

void main() {
  group('gateScreensFor', () {
    List<String> names(List<dynamic> screens) =>
        [for (final s in screens) s.name as String];

    test('runs a case that renders both layouts at every gate size', () {
      expect(names(gateScreensFor('a case', responsiveAllScreens)),
          ['480', '905', '1241', '1280x420']);
    });

    test('runs a mobile case at the mobile size and a desktop one at the rest',
        () {
      expect(names(gateScreensFor('a case', responsiveMobileScreens)), ['480']);
      expect(names(gateScreensFor('a case', responsiveDesktopScreens)),
          ['905', '1241', '1280x420']);
    });

    test('keeps a case on the short-viewport list off 1280x420 only', () {
      final listed = shortViewportSkips.first;

      expect(names(gateScreensFor(listed, responsiveAllScreens)),
          ['480', '905', '1241']);
    });
  });

  group('gateLocalesFor', () {
    test('runs the five gate locales when no locale was asked for', () {
      const all = [
        Locale('en'), Locale('de'), Locale('el'), Locale('fr'), //
        Locale('ja'), Locale('nl'), Locale('ru'),
      ];

      expect(
        gateLocalesFor(all, configured: false).map((l) => l.toLanguageTag()),
        ['ja', 'ru', 'el', 'nl', 'de'],
      );
    });

    test('runs only the gate locales a case renders', () {
      expect(
        gateLocalesFor(const [Locale('en'), Locale('ja')], configured: false)
            .map((l) => l.toLanguageTag()),
        ['ja'],
      );
    });

    test('runs the locales the locales define asks for', () {
      // CI runs one job per locale (#1802, Decision 4).
      expect(
        gateLocalesFor(const [Locale('ru')], configured: true)
            .map((l) => l.toLanguageTag()),
        ['ru'],
      );
    });
  });

  group('the width oracle', () {
    test('derives 905 and 1241, where the desktop content box is narrowest',
        () {
      // #1802's content-box table: 841px at 905, the first desktop width, and
      // at 1241, the first width with the 200px margin.
      expect(requiredGateWidths(), {905, 1241});
    });

    test('the gate runs at every width derived from ResponsiveLayout', () {
      // Moving a breakpoint fails this until gateScreens follows.
      expect(gateScreens.map((s) => s.width), containsAll(requiredGateWidths()));
    });
  });

  group('gateFailures', () {
    test('fails on an overflow over 2.0px and passes one of 2.0px or less', () {
      const over = OverflowIncident(pixels: 2.5, side: 'right', site: 'a:1');
      const atTolerance =
          OverflowIncident(pixels: 2.0, side: 'bottom', site: 'b:2');
      const subPixel = OverflowIncident(pixels: 0.4, side: 'right', site: 'c:3');

      expect(gateFailures([over, atTolerance, subPixel]), [over]);
    });

    test('fails on a report whose amount could not be read', () {
      const unread = OverflowIncident(
          pixels: OverflowIncident.unparseablePixels, side: 'unknown');

      expect(gateFailures([unread]), [unread]);
    });
  });

  group('describeGateFailures', () {
    test('names the case, size and locale, and each site with its amount', () {
      final message = describeGateFailures(
        const [
          OverflowIncident(
              pixels: 41, side: 'right', widget: 'Row', site: 'lib/a.dart:12'),
          OverflowIncident(pixels: 7.25, side: 'bottom', widget: 'Column'),
        ],
        caseName: 'Dashboard Home View - init',
        size: '905',
        locale: 'ja',
      );

      expect(message, contains('Dashboard Home View - init'));
      expect(message, contains('905'));
      expect(message, contains('ja'));
      expect(message, contains('lib/a.dart:12'));
      expect(message, contains('41.0px on the right'));
      expect(message, contains('Row'));
      // A site outside the repository is still listed, by its widget.
      expect(message, contains('Column'));
      expect(message, contains('7.3px on the bottom'));
    });
  });
}
