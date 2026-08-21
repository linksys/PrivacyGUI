@Tags(['layout-gate'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Deliberately the *only* import: since #1338 the parser, the tolerance and the
// predicate live in `test/layout_gate/incident.dart` and reach this file through
// a re-export. Every symbol used below therefore doubles as proof that the old
// path still resolves them, which is what the 22 untouched importers depend on.
import 'overflow_probe.dart';

/// Tests for the overflow gate's own measuring instrument (#1248).
///
/// ## Why this file exists
///
/// Every #1183 ticket's acceptance criterion is "the gate passes". That makes
/// [OverflowIncident] and [runWithOverflowCollection] the only witnesses the
/// whole epic has, and an instrument that under-reports cannot be caught by the
/// tests that use it: the gate goes green either because a card is clean or
/// because the probe stopped seeing it, and those two outcomes are
/// indistinguishable from the outside.
///
/// So the properties under test here are not "the probe reports overflows" —
/// every gate test already covers that by failing when a card breaks. They are
/// the three ways the probe can go **quiet**:
///
///   1. it swallows a `FlutterError` that was not an overflow, so a real error
///      raised during a pump never fails anything;
///   2. it reports a number that a `pixels > tolerance` filter discards, which
///      turns an overflow into silence rather than into a lower reading;
///   3. it leaves someone else's `FlutterError.onError` installed, so later
///      tests report into a dead handler.
///
/// ## The fourth property, added by #1338
///
/// The parser now also carries the incident's `file:line`, and it is not
/// decoration: it is the ratchet key that survives a layout being rearranged
/// where a coordinate key does not, and it is the column that joins golden CI's
/// advisory findings to this gate's verdicts. A fourth way to go quiet follows —
/// **the location silently stops resolving**, and every incident becomes
/// unjoinable while every existing assertion here stays green. Hence the
/// `source location` group below, and hence the real-overflow test that asserts
/// the file *and the line the `Row` was written on*: a hand-written dump alone
/// would keep passing after an SDK change to the block Flutter emits.
///
/// The reverse risk is the reason the location is allowed to be absent. A
/// diagnostic that throws or fails when it cannot resolve a path would turn the
/// instrument into a source of failures of its own — so an unresolvable dump
/// yields a null `file`, and the incident stays usable.
///
/// ## Mutation ledger
///
/// Each fix is pinned by a test that was shown to fail with the fix reverted —
/// a silent-pass test guarding against silent passes would be self-defeating.
///
///   | mutation                                  | what failed                       |
///   |-------------------------------------------|-----------------------------------|
///   | predicate back to `contains('overflowed')` | rejects unrelated errors (1),     |
///   |                                            | forwards non-overflows (1)        |
///   | unparseable fallback back to `pixels: 0`   | unparseable survives tolerance (1)|
///   | `allMatches` + max back to `firstMatch`    | worst side of several (1)         |
///   | `finally` restore removed                  | restores handler when throwing (1)|
///   | location search not anchored on the widget | ignores a creator chain that      |
///   | block (#1338)                               | precedes the widget block (1)     |
///   | run-directory strip disabled (#1338)        | 7 source-location cases plus the  |
///   |                                             | real-overflow file:line (8)       |
///   | percent-decode guard removed (#1338)        | literal percent sign (1)          |
///
/// The real-message test is not in the ledger: it has no mutation in this repo
/// because the code it guards is Flutter's, not ours. It fails when an SDK
/// upgrade changes the wording out from under [isOverflowError].
void main() {
  /// A Flutter overflow report as the SDK writes it today
  /// (`debug_overflow_indicator.dart:261`: `A $runtimeType overflowed by
  /// $overflowText.`). Used where a test needs a specific pixel value or side
  /// combination that is awkward to provoke with a real widget; the shape itself
  /// is verified against a real overflow below.
  String reportOf(String overflowText) =>
      'A RenderFlex overflowed by $overflowText.';

  group('isOverflowError', () {
    test('accepts the SDK\'s overflow report', () {
      expect(isOverflowError(reportOf('41 pixels on the right')), isTrue);
      expect(
        isOverflowError(
            reportOf('0.500 pixels on the bottom and 41 pixels on the right')),
        isTrue,
      );
    });

    test('rejects unrelated errors that merely use the word', () {
      // The reason the predicate is two markers instead of one substring. An
      // error caught here is an error that never fails its test, so the cost of
      // being too generous is a silent pass, while the cost of being too strict
      // is a spurious failure that names itself.
      for (final unrelated in [
        'Bad state: receive buffer overflowed',
        'The stack overflowed while resolving the theme',
        'RangeError: index overflowed the list length',
      ]) {
        expect(
          isOverflowError(unrelated),
          isFalse,
          reason: '"$unrelated" is not a layout overflow — swallowing it would '
              'stop it failing the test it happened in',
        );
      }
    });
  });

  group('kOverflowTolerancePx', () {
    test('is still 2.0 and still reachable through the probe path', () {
      // Two claims in one line, and the second is the one #1338 could have
      // broken. The number is shared (#1270) so five satellite suites cannot
      // drift apart from the gate; moving its declaration into
      // `test/layout_gate/incident.dart` without the re-export would have made
      // every one of those `> kOverflowTolerancePx` filters a compile error, and
      // moving it *with* a different value would have changed every verdict in
      // the family at once.
      expect(kOverflowTolerancePx, 2.0);
      expect(
        OverflowIncident.unparseablePixels,
        greaterThan(kOverflowTolerancePx),
        reason: 'the unparseable marker exists to survive this filter',
      );
    });
  });

  group('OverflowIncident.parse', () {
    test('reads the pixel count and side', () {
      final incident =
          OverflowIncident.parse(reportOf('41 pixels on the right'));
      expect(incident.pixels, 41);
      expect(incident.side, 'right');
    });

    test('reports the worst side when one report names several', () {
      // Flutter emits sides in the fixed order left, top, bottom, right, so the
      // *first* clause of a two-sided report is the one nearer the top of that
      // list — not the largest. Reading only the first turned a 41px right
      // overflow into a sub-tolerance bottom reading, and the gate's
      // `pixels > 2.0` filter then dropped it entirely.
      final incident = OverflowIncident.parse(
        reportOf('0.500 pixels on the bottom and 41 pixels on the right'),
      );
      expect(incident.pixels, 41);
      expect(incident.side, 'right');
      expect(
        [incident].where((i) => i.pixels > 2.0),
        isNotEmpty,
        reason: 'the gate filters on a 2px tolerance, so a two-sided report '
            'whose worst side is 41px must survive it',
      );

      // `_formatPixels` writes one decimal in (1, 10] and three significant
      // digits at or below 1.0, so the sub-tolerance clause reaches the parser in
      // more than one shape. Both must lose to the 41px clause.
      final oneDecimal = OverflowIncident.parse(
        reportOf('0.5 pixels on the bottom and 41 pixels on the right'),
      );
      expect(oneDecimal.pixels, 41);
      expect(oneDecimal.side, 'right');
    });

    test('parses sub-pixel counts written in exponent form', () {
      // `_formatPixels` uses `toStringAsPrecision(3)` below 1px, which switches
      // to exponent notation for very small values. `1.00e-7` read as `1.00`
      // overstates by seven orders of magnitude — harmless against a 2px
      // tolerance, but it makes the reports lie.
      expect(
        OverflowIncident.parse(reportOf('1.00e-7 pixels on the right')).pixels,
        closeTo(1e-7, 1e-12),
      );
    });

    test('an unparseable report survives every tolerance filter', () {
      // The failure this prevents: an SDK change to the number format leaves the
      // regex matching nothing. With a `0` fallback the incident is recorded and
      // then discarded by every `pixels > tolerance` filter in the gate, so the
      // gate reads clean at the exact moment it stopped being able to measure.
      final incident = OverflowIncident.parse(
        reportOf('a whole bunch of pixels on the right'),
      );
      expect(incident.side, 'unknown');
      for (final tolerance in [0.0, 2.0, 1e9]) {
        expect(
          [incident].where((i) => i.pixels > tolerance),
          isNotEmpty,
          reason: 'an unreadable overflow report must not be filtered out by a '
              '${tolerance}px tolerance — silence here is indistinguishable '
              'from a clean layout',
        );
      }
    });

    test('keeps the first line as the message and the details as the log', () {
      final incident = OverflowIncident.parse(
        '${reportOf('41 pixels on the right')}\nThe edge of the RenderFlex...',
        fullLog: 'full details',
      );
      expect(incident.message, reportOf('41 pixels on the right'));
      expect(incident.fullLog, 'full details');
    });
  });

  group('OverflowIncident source location', () {
    /// The shape `FlutterErrorDetails.toString()` writes for an overflow, cut
    /// down to the two parts the parser reads. Hand-written so a specific path
    /// shape can be exercised — the shape itself is checked against a real
    /// Flutter overflow in the last group of this file, which is what stops these
    /// tests from only agreeing with themselves.
    String dumpFor(String creationLocation) => '''
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞══════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 41 pixels on the right.

The relevant error-causing widget was:
  Row
  $creationLocation

The overflowing RenderFlex has an orientation of Axis.horizontal.
''';

    OverflowIncident incidentAt(
      String creationLocation, {
      required String runDirectory,
    }) =>
        OverflowIncident.parse(
          'A RenderFlex overflowed by 41 pixels on the right.',
          fullLog: dumpFor(creationLocation),
          runDirectory: runDirectory,
        );

    test('reports the widget, the file:line and the join key', () {
      // The whole reason the field exists: `site` is what the ratchet keys on
      // and what joins this gate's verdicts to golden CI's advisory findings. A
      // coordinate-keyed allowlist invalidates wholesale the moment a layout is
      // rearranged; a source-location key survives it.
      final incident = incidentAt(
        'Row:file:///Users/dev/work/PrivacyGUI/lib/page/admin/x.dart:120:14',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.widget, 'Row');
      expect(incident.file, 'lib/page/admin/x.dart');
      expect(incident.line, 120);
      expect(incident.site, 'lib/page/admin/x.dart:120');
      expect(incident.pixels, 41, reason: 'the measurement is untouched by it');
    });

    test('strips a run directory that is not named after the repo', () {
      // golden-ci clones the app into "app" under its own workspace, so no path
      // segment is ever "/PrivacyGUI/". Matching on the directory name would
      // leak the whole CI workspace path into the join key and make the two
      // sides unjoinable.
      final incident = incidentAt(
        'Column:file:///home/runner/work/PrivacyGUI-golden-ci/'
        'PrivacyGUI-golden-ci/app/lib/page/admin/x.dart:7:3',
        runDirectory:
            '/home/runner/work/PrivacyGUI-golden-ci/PrivacyGUI-golden-ci/app',
      );

      expect(incident.file, 'lib/page/admin/x.dart');
      expect(incident.widget, 'Column');
    });

    test('collapses a pub-cache git dependency to package-relative form', () {
      // A widget built inside a git dependency reports a pub-cache path carrying
      // the resolved commit SHA, which differs per machine and per dependency
      // bump — so the raw path is the one thing a join key must not be.
      final incident = incidentAt(
        'Row:file:///Users/dev/.pub-cache/git/privacyGUI-UI-kit-'
        '628f62fd51c9dd39b127843d41fcb4c9c07c937f/lib/src/molecules/buttons/'
        'app_button.dart:447:13',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file,
          'privacyGUI-UI-kit/lib/src/molecules/buttons/app_button.dart');
      expect(incident.line, 447);
      expect(incident.file, isNot(startsWith('/')),
          reason: 'no absolute path may reach the ratchet or the report');
    });

    test('collapses a hosted pub-cache dependency, registry segment and all',
        () {
      final incident = incidentAt(
        'Wrap:file:///Users/dev/.pub-cache/hosted/pub.dev/some_pkg-1.2.3/'
        'lib/src/thing.dart:88:5',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file, 'some_pkg/lib/src/thing.dart');
      expect(incident.line, 88);
    });

    test('decodes a percent-encoded home directory before comparing', () {
      // Flutter records creation locations as URIs, so a space in the
      // developer's home directory arrives as `%20`. Compared raw against the
      // run directory it never matches, and the untouched absolute path — user
      // account name included — becomes the key.
      final incident = incidentAt(
        'Row:file:///Users/John%20Smith/dev/PrivacyGUI/lib/page/admin/x.dart'
        ':12:5',
        runDirectory: '/Users/John Smith/dev/PrivacyGUI',
      );

      expect(incident.file, 'lib/page/admin/x.dart');
    });

    test('leaves a path carrying a literal percent sign alone', () {
      // A bare '%' is not valid percent-encoding, and decoding throws on it.
      // This runs inside `FlutterError.onError`, so a throw would turn a
      // diagnostic into a test failure — the path must fall through untouched.
      final incident = incidentAt(
        'Row:file:///Users/dev/100%/x.dart:12:5',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file, '/Users/dev/100%/x.dart');
      expect(incident.line, 12);
    });

    test('returns a path that matches nothing unchanged', () {
      // Better a long path than none: an unrecognised location is still a lead,
      // and dropping it would leave the incident unjoinable for no gain.
      final incident = incidentAt(
        'Row:file:///opt/elsewhere/x.dart:9:1',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file, '/opt/elsewhere/x.dart');
    });

    test('anchors the search inside the error-causing-widget block', () {
      // The deep dump the golden runner reads (`toStringDeep()`, which #1339
      // will feed through this parser) also carries a `creator:` chain whose
      // entries match the same pattern, and the two blocks' relative order is a
      // Flutter implementation detail. An unanchored search reports whichever
      // came first, which is a plausible-looking wrong file.
      const dump = '''
Exception caught by rendering library
   A RenderFlex overflowed by 41 pixels on the right.

   The relevant error-causing widget was:
     Row
     Row:file:///repo/lib/page/dhcp/leases_card.dart:101:12

   The specific RenderFlex in question is: RenderFlex#9e273 OVERFLOWING:
     creator: Column:file:///repo/lib/page/other/wrong.dart:7:3
''';

      final incident = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: dump,
        runDirectory: '/repo',
      );

      expect(incident.site, 'lib/page/dhcp/leases_card.dart:101');
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

      final incident = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: dump,
        runDirectory: '/repo',
      );

      expect(incident.site, 'lib/page/dhcp/leases_card.dart:101');
      expect(incident.widget, 'Row');
    });

    test('a dump with no resolvable location still yields a usable incident',
        () {
      // Creation tracking can be off, the culprit can live inside
      // packages/flutter, and Flutter can reword the block. None of those is a
      // reason to fail a test or to lose the measurement: ~120 of the golden
      // pipeline's coordinates resolved no location at all and the amount was
      // still the whole finding.
      final incident = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: 'A RenderFlex overflowed by 41 pixels on the right.\n'
            'No creation location anywhere in here.',
        runDirectory: '/repo',
      );

      expect(incident.file, isNull);
      expect(incident.line, isNull);
      expect(incident.widget, isNull);
      expect(incident.site, isNull,
          reason:
              'an unjoinable incident says so, rather than inventing a key');
      expect(incident.pixels, 41);
      expect(incident.side, 'right');
      expect(incident.toString(), isNotEmpty);
    });

    test('reads the location even when the pixel count is unreadable', () {
      // The two extractions are independent on purpose. This is the case that
      // most needs a location: the parser has stopped understanding Flutter's
      // number format, and `file:line` is the only thing left pointing at what
      // to look at.
      final incident = incidentAt(
        'Row:file:///repo/lib/page/admin/x.dart:120:14',
        runDirectory: '/repo',
      );
      final unreadable = OverflowIncident.parse(
        'A RenderFlex overflowed by a whole bunch of pixels on the right.',
        fullLog: incident.fullLog,
        runDirectory: '/repo',
      );

      expect(unreadable.pixels, double.infinity);
      expect(unreadable.side, 'unknown');
      expect(unreadable.site, 'lib/page/admin/x.dart:120');
    });

    test('defaults the run directory to the process working directory', () {
      // The 22 existing call sites pass no run directory and must keep
      // compiling, so the default has to be right rather than merely present:
      // under `flutter test` the process cwd is the app root, which is what the
      // reported paths are relative to.
      final incident = incidentAt(
        'Row:file://${Directory.current.path}/lib/page/admin/x.dart:120:14',
        runDirectory: Directory.current.path,
      );
      final defaulted = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: incident.fullLog,
      );

      expect(defaulted.file, 'lib/page/admin/x.dart');
      expect(defaulted.file, incident.file);
    });
  });

  group('OverflowIncident.toString', () {
    // Pinned because this string is the only output a person reads that #1338
    // changed, and nothing else in the suite would notice it changing: the
    // sweeps render it into their failure messages
    // (`dashboard_card_overflow_test.dart:478,721,866,876`) and the report
    // generator into its Markdown detail line and HTML badge
    // (`dashboard_overflow_report_generator.dart:125,380`), while #1337's
    // baselines serialize `px`, `side` and the source columns and never this.
    test('appends the site when the location resolved', () {
      const incident = OverflowIncident(
        pixels: 41.0,
        side: 'right',
        message: 'A RenderFlex overflowed by 41 pixels on the right.',
        file: 'lib/page/dhcp/leases_card.dart',
        line: 101,
        widget: 'Row',
      );

      expect(incident.toString(),
          '+41.0px right at lib/page/dhcp/leases_card.dart:101');
    });

    test('says amount and side alone when it did not', () {
      const incident = OverflowIncident(
        pixels: 41.0,
        side: 'right',
        message: 'A RenderFlex overflowed by 41 pixels on the right.',
      );

      expect(incident.toString(), '+41.0px right',
          reason: 'no trailing " at " with nothing after it');
    });

    test('treats a file without a line as no join key at all', () {
      // Unreachable through `parse`, which sets the two together — but the const
      // constructor is public, and `lib/x.dart:null` would read as a resolved
      // key while joining to nothing.
      const half = OverflowIncident(
        pixels: 41.0,
        side: 'right',
        message: 'A RenderFlex overflowed by 41 pixels on the right.',
        file: 'lib/page/dhcp/leases_card.dart',
      );

      expect(half.site, isNull);
      expect(half.toString(), '+41.0px right');
    });
  });

  group('runWithOverflowCollection', () {
    /// Runs [body] with [FlutterError.onError] pointed at a list, and returns
    /// what that list caught. Stands in for the test binding's own handler: what
    /// matters is whether the probe hands an error onward, not who receives it.
    Future<List<String>> forwardedBy(
      Future<void> Function(List<OverflowIncident> sink) body,
    ) async {
      final forwarded = <String>[];
      final saved = FlutterError.onError;
      FlutterError.onError =
          (details) => forwarded.add(details.exception.toString());
      try {
        await runWithOverflowCollection((sink) async {
          await body(sink);
          return null;
        });
      } finally {
        FlutterError.onError = saved;
      }
      return forwarded;
    }

    test('collects overflow reports instead of forwarding them', () async {
      List<OverflowIncident>? collected;
      final forwarded = await forwardedBy((sink) async {
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(reportOf('41 pixels on the right')),
        ));
        collected = List.of(sink);
      });
      expect(forwarded, isEmpty);
      expect(collected, hasLength(1));
      expect(collected!.single.pixels, 41);
    });

    test('forwards errors that are not overflows', () async {
      // Without this, any exception thrown during a pump — a provider blowing
      // up, a null in a builder — is absorbed by the probe and the card is
      // recorded as laying out cleanly.
      List<OverflowIncident>? collected;
      final forwarded = await forwardedBy((sink) async {
        FlutterError.reportError(FlutterErrorDetails(
          exception: StateError('receive buffer overflowed'),
        ));
        collected = List.of(sink);
      });
      expect(
        forwarded,
        hasLength(1),
        reason: 'a non-overflow error must reach the handler that fails the '
            'test; the probe is not entitled to consume it',
      );
      expect(collected, isEmpty);
    });

    test('restores the previous handler when body throws', () async {
      final saved = FlutterError.onError;
      void sentinel(FlutterErrorDetails details) {}
      FlutterError.onError = sentinel;
      try {
        await expectLater(
          runWithOverflowCollection<void>(
              (sink) async => throw StateError('x')),
          throwsStateError,
        );
        expect(
          FlutterError.onError,
          same(sentinel),
          reason:
              'a probe that leaks its handler on the error path leaves every '
              'later test reporting into the probe of a finished one',
        );
      } finally {
        FlutterError.onError = saved;
      }
    });
  });

  group('against a real overflow', () {
    // The three tests above use a hand-written copy of the SDK's message, so on
    // their own they would keep passing after an SDK upgrade renamed the very
    // thing they parse. These pump a Row that genuinely does not fit and read
    // whatever Flutter actually says, which is what couples the parser to the
    // SDK rather than to this file's own string.
    //
    // No `loadAppFonts()`: the overflow here is a fixed-width box against a
    // fixed-width parent, so it is arithmetic, not text measurement.
    Future<String> rawReportFrom(WidgetTester tester, Widget child) async {
      final captured = <String>[];
      final saved = FlutterError.onError;
      FlutterError.onError =
          (details) => captured.add(details.exceptionAsString());
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 100, child: child),
            ),
          ),
        );
      } finally {
        FlutterError.onError = saved;
      }
      expect(captured, hasLength(1),
          reason: 'expected exactly one report from this pump, got $captured');
      return captured.single;
    }

    testWidgets('the SDK message still satisfies the predicate and parser',
        (tester) async {
      final raw = await rawReportFrom(
        tester,
        Row(children: const [SizedBox(width: 400, height: 10)]),
      );

      expect(
        isOverflowError(raw),
        isTrue,
        reason: 'Flutter now reports overflow as "$raw", which '
            '`isOverflowError` no longer recognises — every gate test is '
            'silently passing. Update the predicate and the parser together.',
      );
      final incident = OverflowIncident.parse(raw);
      expect(incident.side, 'right');
      expect(incident.pixels, closeTo(300, 1),
          reason: 'a 400px child in a 100px Row overflows by 300px, so a '
              'reading far from that means the parser picked up the wrong '
              'number from "$raw"');
    });

    testWidgets('collectOverflow measures the same overflow end to end',
        (tester) async {
      final overflows = await collectOverflow(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: Row(children: const [SizedBox(width: 400, height: 10)]),
            ),
          ),
        ),
        surfaceSize: const Size(800, 600),
      );
      expect(overflows, hasLength(1));
      expect(overflows.single.pixels, closeTo(300, 1));
      expect(overflows.single.side, 'right');
    });

    /// The 1-based line in this file on which the marked `Row` below is built.
    ///
    /// Found by reading this file rather than written as a literal, because a
    /// literal turns the assertion into a lie the first time anyone inserts a
    /// line above it — and the lie is invisible, since `line` would still be *a*
    /// plausible number.
    int lineOfMarkedRow() {
      // Split so this line is not itself a candidate match.
      const marker = '// LOAD-BEARING' '-ROW';
      final source =
          File('test/util/overflow_probe_test.dart').readAsLinesSync();
      final markerIndex = source.indexWhere((l) => l.contains(marker));
      expect(markerIndex, isNonNegative,
          reason: 'the marked Row went missing from this file');
      // `dart format` is entitled to move a trailing comment onto its own line
      // underneath the call it annotates, so walk up to the nearest `Row(`
      // instead of assuming the two share a line.
      for (var i = markerIndex; i >= 0; i--) {
        if (source[i].contains('Row(')) return i + 1;
      }
      fail('no `Row(` at or above the marker in this file');
    }

    testWidgets('resolves file:line from a real Flutter overflow',
        (tester) async {
      // The load-bearing test of #1338. The hand-written dumps above pin the
      // path shapes; this one pins that Flutter still *emits* a resolvable
      // location, that `details.toString()` — the string the collector passes as
      // `fullLog` — still carries it, and that the run directory really is
      // stripped on a real absolute path rather than only on a fabricated one.
      // Measured on Flutter 3.44: `exceptionAsString()` carries the one-line
      // message alone, `toString()` carries the error-causing-widget block, and
      // `toDiagnosticsNode().toStringDeep()` adds only the creator chain.
      final expectedLine = lineOfMarkedRow();

      final overflows = await collectOverflow(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: Row(
                // LOAD-BEARING-ROW
                children: const [SizedBox(width: 400, height: 10)],
              ),
            ),
          ),
        ),
        surfaceSize: const Size(800, 600),
      );

      expect(overflows, hasLength(1));
      final incident = overflows.single;

      expect(
        incident.file,
        'test/util/overflow_probe_test.dart',
        reason: 'the location must arrive normalised and repo-relative — an '
            'absolute path is different bytes on every machine, so it cannot be '
            'a ratchet key or a join column. Got "${incident.file}".',
      );
      expect(
        incident.line,
        expectedLine,
        reason: 'the location must name the widget Flutter blamed, not some '
            'ancestor from the creator chain',
      );
      expect(incident.widget, 'Row');
      expect(incident.site, 'test/util/overflow_probe_test.dart:$expectedLine');
      expect(incident.pixels, closeTo(300, 1));
      expect(incident.side, 'right');
    });
  });
}
