@Tags(['dashboard-card'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import 'dashboard_card_probe.dart';

/// Width-selection tests for the overflow gate's probe (#1225).
///
/// The gate's coverage argument is one sentence: *the narrowest realization of a
/// span is that span's worst case, so pumping one width per span is exhaustive.*
/// These tests pin down the "narrowest" half of it.
///
/// **Every case passes `minScreen:` explicitly.** Both probe functions default it
/// to [minScreenFilter], which reads the `MIN_SCREEN` dart-define/env var — so an
/// operator with `MIN_SCREEN` exported for a targeted sweep would otherwise see
/// these fail for reasons that have nothing to do with the code.
void main() {
  /// Independent oracle: the narrowest card width for [span] anywhere in the
  /// range, including the **open** left edges of the four regimes that begin
  /// just above a breakpoint. Deliberately derived a different way from the
  /// implementation — from the breakpoint list rather than by walking integers —
  /// so it can catch an enumeration whose domain is wrong, not merely one whose
  /// step is coarse.
  ({double width, double at}) continuumInfimum(int span, {double? floor}) {
    const epsilon = 1e-9;
    const breakpoints = [600.0, 905.0, 1240.0, 1440.0, 1680.0];
    final from = floor ?? kMinSupportedScreenWidth;
    final candidates = <({double width, double at})>[
      (width: cardWidthAt(from, span), at: from),
      for (final b in breakpoints)
        if (b + epsilon >= from)
          (width: cardWidthAt(b + epsilon, span), at: b + epsilon),
      // Regime interiors are increasing in screen width, so their own left
      // edges above already dominate them; sampling a few interior points only
      // guards the assumption itself.
      for (final s in [from, 700.0, 1000.0, 1300.0, 1500.0, 2000.0, 2560.0])
        if (s >= from) (width: cardWidthAt(s, span), at: s),
    ];
    return candidates.reduce((a, b) => a.width <= b.width ? a : b);
  }

  group('kMinSupportedScreenWidth', () {
    test('is a product floor that excludes geometrically narrower cards', () {
      // Geometry alone permits a 152px 3-column card at a 240px screen — density
      // design §1.6/§2.3. The floor is what keeps the gate off widths no
      // shipping device has; lowering it adds overflow coordinates.
      expect(cardWidthAt(kMinSupportedScreenWidth - 80.0, 3),
          lessThan(cardWidthAt(kMinSupportedScreenWidth, 3)));
    });

    test('upper bound is past every breakpoint, so no wider screen is narrower',
        () {
      // Above the last margin breakpoint the (columns, margin) regime never
      // changes again, so card width only grows and enumeration can stop. This
      // checks the whole tail rather than two sample points.
      const lastBreakpoint = 1680.0;
      expect(kMaxScannedScreenWidth, greaterThan(lastBreakpoint));
      var previous = cardWidthAt(lastBreakpoint + 1.0, 6);
      for (var w = lastBreakpoint + 2.0;
          w <= kMaxScannedScreenWidth;
          w += 1.0) {
        final current = cardWidthAt(w, 6);
        expect(current, greaterThanOrEqualTo(previous),
            reason: 'card width dropped at ${w}px — a new regime starts above '
                'the last known breakpoint, so kMaxScannedScreenWidth is no '
                'longer a safe stopping point');
        previous = current;
      }
    });
  });

  group('narrowestRealizationOf', () {
    test('matches an independently derived infimum, within the stated slack',
        () {
      // The guarantee the gate rests on. The enumeration walks integers, so it
      // can sit up to kEnumerationSlackPx above the true infimum at an open
      // regime edge — but never below it, and never further above.
      for (var span = 1; span <= 12; span++) {
        final narrowest = narrowestRealizationOf(span, minScreen: 0)!;
        final oracle = continuumInfimum(span);
        expect(narrowest.cardWidth, greaterThanOrEqualTo(oracle.width - 0.001),
            reason: 'span $span claims a width below the true infimum');
        expect(
          narrowest.cardWidth - oracle.width,
          lessThanOrEqualTo(kEnumerationSlackPx + 0.001),
          reason: 'span $span sits ${narrowest.cardWidth - oracle.width}px '
              'above the infimum (${oracle.width} @ ${oracle.at}px), more than '
              'the documented kEnumerationSlackPx',
        );
      }
    });

    test('no integer screen width realizes a span more narrowly', () {
      for (var span = 1; span <= 12; span++) {
        final narrowest = narrowestRealizationOf(span, minScreen: 0)!;
        for (var screen = kMinSupportedScreenWidth;
            screen <= kMaxScannedScreenWidth;
            screen += 1.0) {
          expect(
            cardWidthAt(screen, span),
            greaterThanOrEqualTo(narrowest.cardWidth - 0.001),
            reason: 'span $span is narrower at ${screen}px '
                '(${cardWidthAt(screen, span)}) than the width the gate pumps '
                '(${narrowest.cardWidth} @ ${narrowest.screenWidth}px)',
          );
        }
      }
    });

    test('the reported screen width actually produces the reported card width',
        () {
      for (var span = 1; span <= 12; span++) {
        final narrowest = narrowestRealizationOf(span, minScreen: 0)!;
        expect(cardWidthAt(narrowest.screenWidth, span),
            closeTo(narrowest.cardWidth, 0.001),
            reason: 'span $span');
      }
    });

    test('never picks a screen outside the enumerated range', () {
      for (var span = 1; span <= 12; span++) {
        final screen = narrowestRealizationOf(span, minScreen: 0)!.screenWidth;
        expect(screen, greaterThanOrEqualTo(kMinSupportedScreenWidth));
        expect(screen, lessThanOrEqualTo(kMaxScannedScreenWidth));
      }
    });

    // The #1225 no-op claim (density design §1.6): enumerating the range finds
    // exactly what the retired 19-width sample found, for all 12 spans. These
    // literals are the committed baseline's geometry — they are here to detect a
    // shift in what the gate pumps, not to re-derive it. If one changes, the
    // allowlist in known_overflows.json is expected to move with it, and that
    // shift must be explained rather than re-baselined silently.
    const baseline = <int, ({double screen, double width})>{
      1: (screen: 601.0, width: 53.125),
      2: (screen: 601.0, width: 122.25),
      3: (screen: 601.0, width: 191.375),
      4: (screen: 601.0, width: 260.5),
      5: (screen: 320.0, width: 288.0),
      6: (screen: 320.0, width: 288.0),
      7: (screen: 320.0, width: 288.0),
      8: (screen: 320.0, width: 288.0),
      9: (screen: 320.0, width: 288.0),
      10: (screen: 320.0, width: 288.0),
      11: (screen: 320.0, width: 288.0),
      12: (screen: 320.0, width: 288.0),
    };

    for (final entry in baseline.entries) {
      test('span ${entry.key} still pumps ${entry.value.width}px', () {
        final narrowest = narrowestRealizationOf(entry.key, minScreen: 0)!;
        expect(narrowest.cardWidth, closeTo(entry.value.width, 0.001));
        expect(narrowest.screenWidth, entry.value.screen);
      });
    }

    test('spans of 5+ clamp to the 4-column mobile grid at the floor', () {
      // Why mobile is not automatically the worst case: a wide span clamps to
      // the whole 4-column grid (288px at 320px), while a 3-column card is
      // narrower on a 601px tablet (191.4px) than on that phone (212px).
      expect(narrowestRealizationOf(12, minScreen: 0)!.cardWidth,
          closeTo(narrowestRealizationOf(5, minScreen: 0)!.cardWidth, 0.001));
      expect(cardWidthAt(320.0, 3), greaterThan(cardWidthAt(601.0, 3)));
    });

    test('honours a raised floor, including bands the old sample skipped', () {
      // The retired sample held no width in 602..904, so with MIN_SCREEN=602 it
      // fell through to 1241px and reported 198.25px for a span of 3 — 6.5px
      // wide of the truth. Enumeration finds the real narrowest.
      final raised = narrowestRealizationOf(3, minScreen: 602.0)!;
      expect(raised.screenWidth, 602.0);
      expect(raised.cardWidth, closeTo(191.75, 0.001));
      expect(raised.cardWidth, lessThan(198.25));
      expect(
          raised.cardWidth,
          greaterThanOrEqualTo(
              continuumInfimum(3, floor: 602.0).width - 0.001));
    });

    test('a fractional floor still finds the integer regime edge above it', () {
      // Enumerating from a fractional floor in 1px steps would only ever land on
      // fractional widths and skip 601px — the tightest tablet slot — so the
      // search evaluates the floor separately from the integers above it.
      final fractional = narrowestRealizationOf(3, minScreen: 320.5)!;
      expect(fractional.screenWidth, 601.0);
      expect(fractional.cardWidth, closeTo(191.375, 0.001));
    });

    test('returns null when the floor is past the enumerated range', () {
      // The out-of-range floor must not silently yield a width from a screen the
      // enumeration never visited.
      expect(narrowestRealizationOf(3, minScreen: kMaxScannedScreenWidth + 1.0),
          isNull);
    });

    test('a floor inside the range near its top still yields a realization',
        () {
      final high =
          narrowestRealizationOf(3, minScreen: kMaxScannedScreenWidth)!;
      expect(high.screenWidth, kMaxScannedScreenWidth);
      expect(high.cardWidth,
          closeTo(cardWidthAt(kMaxScannedScreenWidth, 3), 0.001));
    });

    test('a floor below the product floor is clamped up to it', () {
      // MIN_SCREEN=0 is the runner's default and means "no filter", not "scan
      // down to zero" — the 320px commitment still applies.
      final unfiltered = narrowestRealizationOf(3, minScreen: 0);
      expect(unfiltered!.screenWidth,
          greaterThanOrEqualTo(kMinSupportedScreenWidth));
      expect(unfiltered.cardWidth,
          closeTo(narrowestRealizationOf(3, minScreen: 0)!.cardWidth, 0.001));
    });
  });

  group('widthCasesFor', () {
    test('covers every distinct width among min/preferred/max spans', () {
      for (final spec in UspWidgetSpecs.all) {
        final c = spec.getConstraints(DisplayMode.normal);
        final cases = widthCasesFor(spec, minScreen: 0);
        final expectedWidths = {
          for (final span in [c.minColumns, c.preferredColumns, c.maxColumns])
            narrowestRealizationOf(span, minScreen: 0)!
                .cardWidth
                .toStringAsFixed(0)
        };
        expect(cases.map((w) => w.widthKey).toSet(), expectedWidths,
            reason: spec.id);
      }
    });

    test('de-duplicates spans that realize the same width, keeping min first',
        () {
      // Every card whose spans collapse to one width must cost one test case,
      // not three — that reduction is why the gate is affordable at 26 locales.
      for (final spec in UspWidgetSpecs.all) {
        final cases = widthCasesFor(spec, minScreen: 0);
        expect(cases.map((w) => w.widthKey).toSet().length, cases.length,
            reason: '${spec.id} pumps the same width twice');
        expect(cases.first.label, 'min', reason: spec.id);
      }
    });

    test('each case carries the span and screen that produced its width', () {
      for (final spec in UspWidgetSpecs.all) {
        for (final wc in widthCasesFor(spec, minScreen: 0)) {
          expect(cardWidthAt(wc.screenWidth, wc.columnSpan),
              closeTo(wc.cardWidth, 0.001),
              reason: '${spec.id} @${wc.label}');
          expect(
              wc.screenWidth, greaterThanOrEqualTo(kMinSupportedScreenWidth));
        }
      }
    });

    test('a floor past the enumerated range yields no cases', () {
      for (final spec in UspWidgetSpecs.all) {
        expect(widthCasesFor(spec, minScreen: kMaxScannedScreenWidth + 1.0),
            isEmpty,
            reason: spec.id);
      }
    });
  });
}
