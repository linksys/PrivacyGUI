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
}
