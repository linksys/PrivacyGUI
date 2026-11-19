import 'package:flutter_test/flutter_test.dart';

import 'incident.dart';

void main() {
  String reportOf(String overflowText) =>
      'A RenderFlex overflowed by $overflowText.';

  group('OverflowIncident.parse', () {
    test('reads the pixel count and the side', () {
      final incident =
          OverflowIncident.parse(reportOf('41 pixels on the right'));

      expect(incident.pixels, 41);
      expect(incident.side, 'right');
    });

    test('reports the worst side when one report names several', () {
      // Flutter lists the sides in a fixed order, so the first clause is not
      // the largest: a 2px tolerance would drop this 41px overflow.
      final incident = OverflowIncident.parse(
        reportOf('0.500 pixels on the bottom and 41 pixels on the right'),
      );

      expect(incident.pixels, 41);
      expect(incident.side, 'right');
    });

    test('reads a sub-pixel amount written in exponent form', () {
      final incident =
          OverflowIncident.parse(reportOf('1.00e-7 pixels on the right'));

      expect(incident.pixels, closeTo(1e-7, 1e-12));
    });

    test('an unreadable report survives every tolerance', () {
      // A zero would be dropped by the 2px filter, so a report this parser
      // stopped understanding would read as a clean layout.
      final incident = OverflowIncident.parse(
        reportOf('a whole bunch of pixels on the right'),
      );

      expect(incident.side, 'unknown');
      expect(incident.pixels, greaterThan(kOverflowTolerancePx));
      expect(incident.pixels, greaterThan(1e9));
    });
  });

  group('isOverflowError', () {
    test("accepts Flutter's overflow report", () {
      expect(isOverflowError(reportOf('41 pixels on the right')), isTrue);
    });

    test('rejects other errors that merely use the word', () {
      // A swallowed error does not fail the test it happened in.
      for (final unrelated in [
        'Bad state: receive buffer overflowed',
        'The stack overflowed while resolving the theme',
      ]) {
        expect(isOverflowError(unrelated), isFalse, reason: unrelated);
      }
    });
  });

  group('OverflowIncident source location', () {
    const report = 'A RenderFlex overflowed by 41 pixels on the right.';

    test('reads the widget and the repo-relative file:line', () {
      const dump = '''
The following assertion was thrown during layout:
A RenderFlex overflowed by 41 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///home/runner/work/PrivacyGUI/PrivacyGUI/lib/page/nodes/views/node_detail_view.dart:120:14
''';

      final incident = OverflowIncident.parse(
        report,
        fullLog: dump,
        runDirectory: '/home/runner/work/PrivacyGUI/PrivacyGUI',
      );

      expect(incident.widget, 'Row');
      expect(incident.site, 'lib/page/nodes/views/node_detail_view.dart:120');
      expect(incident.pixels, 41);
    });

    test('reads the location from the error-causing widget block only', () {
      const dump = '''
The specific RenderFlex in question is: RenderFlex#9e273 OVERFLOWING:
  creator: Column:file:///repo/lib/page/other/wrong.dart:7:3

The relevant error-causing widget was:
  Row
  Row:file:///repo/lib/page/dhcp/leases_card.dart:101:12
''';

      final incident =
          OverflowIncident.parse(report, fullLog: dump, runDirectory: '/repo');

      expect(incident.site, 'lib/page/dhcp/leases_card.dart:101');
    });

    test('has no site when the dump names no location', () {
      final incident = OverflowIncident.parse(
        report,
        fullLog: '$report\nNo creation location anywhere in here.',
        runDirectory: '/repo',
      );

      expect(incident.site, isNull);
      expect(incident.widget, isNull);
      expect(incident.pixels, 41, reason: 'the measurement still stands');
    });

    test('has no site for a file outside the run directory', () {
      // An absolute path differs per machine, so it cannot key an incident.
      const dump = '''
The relevant error-causing widget was:
  Row
  Row:file:///Users/dev/.pub-cache/hosted/pub.dev/some_pkg-1.2.3/lib/x.dart:9:2
''';

      final incident =
          OverflowIncident.parse(report, fullLog: dump, runDirectory: '/repo');

      expect(incident.site, isNull);
      expect(incident.widget, 'Row');
    });

    test('decodes a percent-encoded run directory before comparing', () {
      const dump = '''
The relevant error-causing widget was:
  Row
  Row:file:///Users/my%20name/PrivacyGUI/lib/page/x.dart:5:1
''';

      final incident = OverflowIncident.parse(
        report,
        fullLog: dump,
        runDirectory: '/Users/my name/PrivacyGUI',
      );

      expect(incident.site, 'lib/page/x.dart:5');
    });
  });
}
