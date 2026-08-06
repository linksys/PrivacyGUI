@Tags(['ui'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'overflow_diagnostics.dart';

/// Guards the parsing of Flutter's overflow error message and diagnostics dump.
///
/// Both formats are Flutter implementation details rather than API contracts,
/// so an SDK upgrade can change them silently. These tests pin the shapes this
/// code depends on (#1197).
void main() {
  group('parseOverflowAmount', () {
    test('reads the pixel count and side from a whole-pixel message', () {
      final parsed = parseOverflowAmount(
        'A RenderFlex overflowed by 50 pixels on the right.',
      );

      expect(parsed, {'pixels': '50', 'side': 'right'});
    });

    test('reads a fractional pixel count', () {
      // _formatPixels emits one decimal for values in (1, 10] and three
      // significant digits at or below 1.0, so the pattern must accept a
      // decimal point.
      expect(
        parseOverflowAmount(
            'A RenderFlex overflowed by 5.5 pixels on the bottom.'),
        {'pixels': '5.5', 'side': 'bottom'},
      );
      expect(
        parseOverflowAmount(
            'A RenderFlex overflowed by 0.500 pixels on the top.'),
        {'pixels': '0.500', 'side': 'top'},
      );
    });

    test('keeps the first side when one overflow reports two', () {
      expect(
        parseOverflowAmount(
          'A RenderFlex overflowed by 12 pixels on the left and 8 pixels on the top.',
        ),
        {'pixels': '12', 'side': 'left'},
      );
    });

    test('returns empty fields when the message does not match', () {
      expect(parseOverflowAmount('Some unrelated error.'), <String, String>{});
    });
  });

  group('normalizeSourcePath', () {
    test('strips the run directory so the path is repo-relative', () {
      expect(
        normalizeSourcePath(
          '/Users/dev/Documents/workspace/PrivacyGUI/lib/page/admin/x.dart',
          runDirectory: '/Users/dev/Documents/workspace/PrivacyGUI',
        ),
        'lib/page/admin/x.dart',
      );
    });

    test('strips a CI run directory that is not named PrivacyGUI', () {
      // golden-ci clones the app into "app" under its own workspace, so no
      // path segment is ever "/PrivacyGUI/".
      expect(
        normalizeSourcePath(
          '/home/runner/work/PrivacyGUI-golden-ci/PrivacyGUI-golden-ci/app/lib/page/admin/x.dart',
          runDirectory:
              '/home/runner/work/PrivacyGUI-golden-ci/PrivacyGUI-golden-ci/app',
        ),
        'lib/page/admin/x.dart',
      );
    });

    test('collapses a pub-cache git dependency to package-relative form', () {
      // Widgets built inside a git dependency report a pub-cache path carrying
      // the resolved commit SHA, which differs per machine and per bump.
      expect(
        normalizeSourcePath(
          '/Users/dev/.pub-cache/git/privacyGUI-UI-kit-628f62fd51c9dd39b127843d41fcb4c9c07c937f/lib/src/molecules/buttons/app_button.dart',
          runDirectory: '/Users/dev/Documents/workspace/PrivacyGUI',
        ),
        'privacyGUI-UI-kit/lib/src/molecules/buttons/app_button.dart',
      );
    });

    test('collapses a hosted pub-cache dependency to package-relative form',
        () {
      expect(
        normalizeSourcePath(
          '/Users/dev/.pub-cache/hosted/pub.dev/some_pkg-1.2.3/lib/src/thing.dart',
          runDirectory: '/Users/dev/Documents/workspace/PrivacyGUI',
        ),
        'some_pkg/lib/src/thing.dart',
      );
    });

    test('returns an unrecognized path unchanged', () {
      expect(
        normalizeSourcePath('/opt/elsewhere/x.dart',
            runDirectory: '/Users/dev/PrivacyGUI'),
        '/opt/elsewhere/x.dart',
      );
    });
  });

  group('parseOverflowSource', () {
    testWidgets('reads widget, file and line from a real diagnostics dump',
        (tester) async {
      final dumps = <String>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          dumps.add(details.toDiagnosticsNode().toStringDeep());
          return;
        }
        original?.call(details);
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: const [
              SizedBox(
                width: 100,
                child: Row(children: [SizedBox(width: 150, height: 10)]),
              ),
            ],
          ),
        ),
      );
      FlutterError.onError = original;

      expect(dumps, hasLength(1),
          reason: 'the constrained Row must report exactly one overflow');

      final parsed = parseOverflowSource(dumps.single,
          runDirectory: Directory.current.path);

      expect(parsed['widget'], 'Row');
      expect(
          parsed['file'],
          'test/golden_test/golden_framework/'
          'overflow_diagnostics_test.dart');
      expect(parsed['line'], isNotEmpty);
    });

    test('resolves a widget created inside a pub-cache dependency', () {
      // Flutter's inspector treats anything outside packages/flutter/ as user
      // code, so a widget built inside the ui-kit reports its pub-cache path.
      // Verified against a real AppButton: the culprit Row resolves to
      // app_button.dart under .pub-cache/git/privacyGUI-UI-kit-<sha>/.
      const dump = '''
Exception caught by rendering library
   A RenderFlex overflowed by 50 pixels on the right.

   The relevant error-causing widget was:
     Row
     Row:file:///Users/dev/.pub-cache/git/privacyGUI-UI-kit-628f62fd51c9dd39b127843d41fcb4c9c07c937f/lib/src/molecules/buttons/app_button.dart:447:13
''';

      final parsed = parseOverflowSource(dump,
          runDirectory: '/Users/dev/Documents/workspace/PrivacyGUI');

      expect(parsed['widget'], 'Row');
      expect(parsed['file'],
          'privacyGUI-UI-kit/lib/src/molecules/buttons/app_button.dart');
      expect(parsed['line'], '447');
      expect(parsed['file'], isNot(startsWith('/')),
          reason: 'no absolute path may reach the report');
    });

    test('anchors the search inside the error-causing-widget block', () {
      // The deep dump also carries a "creator:" chain whose entries match the
      // same pattern. Their relative order is a Flutter implementation detail,
      // so the search must be scoped rather than run over the whole dump.
      const dump = '''
Exception caught by rendering library
   The following assertion was thrown during layout:
   A RenderFlex overflowed by 50 pixels on the right.

   The relevant error-causing widget was:
     Row
     Row:file:///repo/lib/page/dhcp/leases_card.dart:101:12

   The specific RenderFlex in question is: RenderFlex#9e273 OVERFLOWING:
     creator: Column:file:///repo/lib/page/other/wrong.dart:7:3
''';

      final parsed = parseOverflowSource(dump, runDirectory: '/repo');

      expect(parsed['file'], 'lib/page/dhcp/leases_card.dart');
      expect(parsed['line'], '101');
    });

    test('ignores a creator chain that precedes the widget block', () {
      const dump = '''
Exception caught by rendering library
   The specific RenderFlex in question is: RenderFlex#9e273 OVERFLOWING:
     creator: Column:file:///repo/lib/page/other/wrong.dart:7:3

   The relevant error-causing widget was:
     Row
     Row:file:///repo/lib/page/dhcp/leases_card.dart:101:12
''';

      final parsed = parseOverflowSource(dump, runDirectory: '/repo');

      expect(parsed['file'], 'lib/page/dhcp/leases_card.dart');
      expect(parsed['widget'], 'Row');
    });

    test('returns empty fields when the widget block is absent', () {
      expect(
        parseOverflowSource('no location here', runDirectory: '/repo'),
        <String, String>{},
      );
    });
  });

  group('stripEphemeralIds', () {
    test('removes the object hash Flutter appends to render object names', () {
      // The id is a per-object allocation detail: the same overflow reported in
      // 24 goldens carried 24 different ids, so nothing downstream could tell
      // that one culprit explained them all, and the recorded JSON changed on
      // every run.
      expect(
        stripEphemeralIds(
          'The specific RenderFlex in question is: '
          'RenderFlex#4195b relayoutBoundary=up14 OVERFLOWING:',
        ),
        'The specific RenderFlex in question is: '
        'RenderFlex relayoutBoundary=up14 OVERFLOWING:',
      );
    });

    test('removes ids from the creator chain', () {
      expect(
        stripEphemeralIds(
            'creator: Row ← RepaintBoundary-[GlobalKey#18e2d] ← Column'),
        'creator: Row ← RepaintBoundary-[GlobalKey] ← Column',
      );
    });

    test('leaves the geometry that explains the overflow intact', () {
      // Sibling rows legitimately differ here, and that difference is the
      // diagnostic — it must survive.
      const line = '     size: Size(398.0, 532.0)';

      expect(stripEphemeralIds(line), line);
    });

    test('leaves text that merely looks like an id alone', () {
      // Only a '#' directly following an identifier is an object id.
      expect(stripEphemeralIds('Reservation #12345 for host'),
          'Reservation #12345 for host');
    });
  });

  group('buildOverflowRecord', () {
    /// Triggers a real overflow and returns the record built from it.
    Future<Map<String, String>> recordFor(WidgetTester tester) async {
      final records = <Map<String, String>>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          records.add(buildOverflowRecord(
            goldenName: 'demo-data-phone480-fr',
            details: details,
            runDirectory: Directory.current.path,
          ));
          return;
        }
        original?.call(details);
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: const [
              SizedBox(
                width: 100,
                child: Row(children: [SizedBox(width: 150, height: 10)]),
              ),
            ],
          ),
        ),
      );
      FlutterError.onError = original;

      return records.single;
    }

    testWidgets('keeps the full diagnostics dump for the report', (
      tester,
    ) async {
      // The dump is the only lead on an overflow whose location did not resolve
      // — the ~120 admin cases where the badge was set but nothing was visible
      // in the image. Computing it and throwing it away left them undiagnosable
      // (#1197).
      final record = await recordFor(tester);

      expect(record['log'], contains('A RenderFlex overflowed'));
      expect(record['log'], contains('The relevant error-causing widget was'));
      expect(record['log'], contains('constraints:'),
          reason: 'the deep dump carries the RenderFlex constraints, which is '
              'what explains an overflow the one-line message does not');
    });

    testWidgets('strips absolute run paths out of the dump', (tester) async {
      // The dump embeds the run directory in every creation location. Left in,
      // a report generated on CI would carry the runner's workspace path, and
      // two machines would produce different bytes for the same overflow.
      final record = await recordFor(tester);

      expect(record['log'], isNot(contains(Directory.current.path)));
      expect(
          record['log'],
          contains('test/golden_test/golden_framework/'
              'overflow_diagnostics_test.dart'));
    });

    testWidgets('records the amount and location alongside the dump', (
      tester,
    ) async {
      final record = await recordFor(tester);

      expect(record['golden'], 'demo-data-phone480-fr');
      expect(record['pixels'], '50');
      expect(record['side'], 'right');
      expect(record['widget'], 'Row');
    });

    testWidgets('leaves no per-run object id in the dump', (tester) async {
      // Object ids are reallocated every run, so leaving them in made the same
      // overflow record different bytes each time and defeated the report's log
      // deduplication entirely: 24 records for one culprit stayed 24 distinct
      // logs (#1197).
      final record = await recordFor(tester);

      expect(record['log'], contains('RenderFlex relayoutBoundary'));
      expect(record['log'], isNot(matches(RegExp(r'#[0-9a-f]{5}\b'))));
    });
  });
}
