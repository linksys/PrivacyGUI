import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/config.dart';
import '../constitution/source_scan.dart';
import 'case_names.dart';
import 'collector.dart';
import 'gate.dart';
import 'incident.dart';

void main() {
  group('gateScreensFor', () {
    List<String> names(List<dynamic> screens) =>
        [for (final s in screens) s.name as String];

    test('runs a case that renders both layouts at every gate size', () {
      expect(names(gateScreensFor('a case', responsiveAllScreens)),
          ['360', '480', '905', '1240', '1280x420']);
    });

    test('runs a mobile case at the mobile size and a desktop one at the rest',
        () {
      expect(names(gateScreensFor('a case', responsiveMobileScreens)),
          ['360', '480']);
      expect(names(gateScreensFor('a case', responsiveDesktopScreens)),
          ['905', '1240', '1280x420']);
    });

    test('keeps a case on the short-viewport list off 1280x420 only', () {
      final listed = shortViewportSkips.first;

      expect(names(gateScreensFor(listed, responsiveAllScreens)),
          ['360', '480', '905', '1240']);
    });
  });

  group('gateLocalesFor', () {
    test('runs every gate locale when no locale was asked for', () {
      // English, the common western European locales, and the three that
      // expose what no other locale does (#1802, Decision 7).
      const all = [
        Locale('ar'), Locale('de'), Locale('el'), Locale('en'), Locale('es'),
        Locale('fr'), Locale('it'), Locale('ja'), Locale('nl'), Locale('pt'),
        Locale('ru'), Locale('zh'),
      ];

      expect(
        gateLocalesFor(all, localesDefined: false)
            .map((l) => l.toLanguageTag()),
        ['en', 'de', 'fr', 'es', 'it', 'nl', 'ja', 'ru', 'el'],
      );
    });

    test('runs only the gate locales a case renders', () {
      expect(
        gateLocalesFor(const [Locale('ar'), Locale('ja')],
                localesDefined: false)
            .map((l) => l.toLanguageTag()),
        ['ja'],
      );
    });

    test('runs the locales the locales define asks for', () {
      // A PR's CI job runs en only (#1802, Decision 4).
      expect(
        gateLocalesFor(const [Locale('en')], localesDefined: true)
            .map((l) => l.toLanguageTag()),
        ['en'],
      );
    });
  });

  test('every case on the short-viewport list exists', () {
    final names = {
      for (final source in dartSources('test').values) ...caseNamesIn(source),
    };
    final dead = shortViewportSkips.difference(names);

    expect(
      dead,
      isEmpty,
      reason: 'These entries of shortViewportSkips in '
          'test/layout_gate/gate.dart name no testLocalizations case. '
          'Delete them:\n${bulletList(dead)}',
    );
  });

  group('a pumped overflow', () {
    Future<List<OverflowIncident>> overflowBy(
        WidgetTester tester, double pixels) {
      return runWithOverflowCollection((sink) async {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            // Narrower than the 800px test surface, so the Row gets this width.
            child: SizedBox(
              width: 400,
              child: Row(children: [SizedBox(width: 400 + pixels, height: 1)]),
            ),
          ),
        ));
        return sink;
      });
    }

    testWidgets('fails the gate when it is over the tolerance', (tester) async {
      final failures = gateFailures(await overflowBy(tester, 19));

      expect(failures, hasLength(1));
      expect(failures.single.pixels, 19);
      expect(failures.single.site, startsWith('test/layout_gate/gate_test.dart:'));
    });

    testWidgets('passes the gate when it is within the tolerance',
        (tester) async {
      expect(gateFailures(await overflowBy(tester, 1)), isEmpty);
    });
  });

  group('the width oracle', () {
    test('derives 905 and 1240, where a desktop content box is narrowest', () {
      // 905 is the first desktop width (a 24px margin, 857px since #1855), and
      // 1240 the first with the 200px margin (840px since #1876).
      expect(requiredGateWidths(), {905, 1240});
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
