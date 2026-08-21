@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
