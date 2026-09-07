import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../test_scripts/golden_diff_summary.dart';

/// Guards the read side of #1475's measurement: the per-canvas table printed from
/// `goldens/golden_diff_percent.jsonl`.
///
/// Four things are worth testing here and the rest is formatting.
///
/// **The grouping.** `diffPercent` is normalised by canvas *area*, and suites pin
/// their own height — the baselines hold `480x140` next to `480x4200`, a 30x spread
/// at one width. Pooling those into a "480" row averages two different units and the
/// floor it prints describes no population, so the grouping is by canvas and the
/// per-width answer is a *max* over canvases rather than a quantile across them.
///
/// **The quantile.** It is computed over *all* compared cells, zeros included, and
/// the zeros are not in the record list — the runner counts them instead. So the
/// arithmetic has to place a rank inside an implicit block of zeros, and it is
/// nearest-rank rather than interpolated. Both choices are silent when wrong: a
/// p95 that quietly reports the 95th percentile *of the movers* reads ~100x too
/// large and still looks like a plausible number, which is how a threshold gets
/// picked wrongly with evidence attached. (The roster-median finding in #1379 was
/// this same class of bug: an even-n median averaging two middles where the
/// reviewer expected an observation.)
///
/// **The failures.** A cell that exceeded the threshold is a stale baseline or a
/// real regression. Pooled into the floor it becomes the `max` that the documented
/// procedure tells the reader to raise the threshold above, so it is held out and
/// reported as something to explain.
///
/// **Incompleteness is visible.** The report is append-only from concurrent suites,
/// so the failure mode is a torn line, not a lost snapshot. A line that cannot be
/// read, or a canvas whose records outnumber the cells it declared, has to reach the
/// output — a confident percentile over an unknown fraction of the sweep is the one
/// thing worse than no measurement.
void main() {
  String line(Map<String, dynamic> entry) => jsonEncode(entry);

  String cells(int width, int height, int count) => line({
        'type': 'cells',
        'width': width,
        'height': height,
        'count': count,
      });

  String diff(
    int width,
    int height,
    double diffPercent, {
    String golden = 'g',
    bool passed = true,
  }) =>
      line({
        'type': 'diff',
        'golden': golden,
        'width': width,
        'height': height,
        'diffPercent': diffPercent,
        'passed': passed,
      });

  const threshold = '{"type":"threshold","value":0.025}';

  group('percentileOf', () {
    test('an all-zero population has a zero floor at every quantile', () {
      // The expected local result, and the one that must not be mistaken for a
      // measured CI floor.
      for (final fraction in [0.0, 0.5, 0.95, 0.99, 1.0]) {
        expect(percentileOf(const [], 3120, fraction), 0);
      }
    });

    test('quantiles inside the zero block are zero, above it are observed', () {
      // 100 cells, 4 of which moved. The zero block is ranks 1-96, so p95 lands
      // in it and p99 does not.
      final diffs = [0.001, 0.002, 0.003, 0.9];

      expect(percentileOf(diffs, 100, 0.95), 0,
          reason: '95 of 100 cells were identical, so the 95th percentile is '
              'identical — this is the number a threshold should be read from, '
              'not the movers\' own p95');
      expect(percentileOf(diffs, 100, 0.97), 0.001);
      expect(percentileOf(diffs, 100, 0.99), 0.003);
      expect(percentileOf(diffs, 100, 1.0), 0.9);
    });

    test('never interpolates — every result is an observed diff', () {
      // Two movers and nothing else: the midpoint of an even population would be
      // 0.015 under interpolation, which is a diff no cell had.
      final diffs = [0.01, 0.02];

      expect(percentileOf(diffs, 2, 0.5), 0.01);
      expect(percentileOf(diffs, 2, 0.5), isNot(0.015));
      expect(percentileOf(diffs, 2, 1.0), 0.02);
    });

    test('p95 rounds up, so it is never below the 95th percentile', () {
      // Ten cells, all of them movers: rank ceil(0.95 x 10) = ceil(9.5) = 10, so
      // p95 is the largest. `round()` happens to agree at this population — Dart
      // evaluates 0.95 * 10 as exactly 9.5 and rounds half away from zero — but
      // it does not in general, and `ceil` is what makes the guarantee in the
      // test's name hold rather than coincide.
      final ten = List.generate(10, (i) => (i + 1) / 1000);

      expect(percentileOf(ten, 10, 0.95), 0.01,
          reason: 'rank ceil(9.5) = 10 of 10');
      expect(percentileOf(ten, 10, 0.85), 0.009);
      expect(percentileOf(ten, 10, 0.81), 0.009,
          reason: 'ceil(8.1) = 9, where round() would have given the 8th');
    });

    test('a single cell is its own every quantile', () {
      expect(percentileOf([0.03], 1, 0.0), 0.03);
      expect(percentileOf([0.03], 1, 0.99), 0.03);
    });

    test('an empty population is zero rather than a crash', () {
      // A canvas present in the totals with a count of 0 is reachable from a
      // partially written report.
      expect(percentileOf(const [], 0, 0.95), 0);
    });
  });

  group('summariseLines', () {
    test('groups by canvas, not by width', () {
      // The finding this grouping exists for: at width 480 these two canvases
      // differ 4.2x in area, so one differing block is a different percentage of
      // each. A "480" row would report the mean of two units.
      final summary = summariseLines([
        threshold,
        cells(480, 1000, 40),
        cells(480, 4200, 4),
        diff(480, 1000, 0.04, golden: 'short'),
        diff(480, 4200, 0.0095, golden: 'tall'),
      ]);

      expect(summary.byCanvas.map((c) => c.label), ['480x1000', '480x4200']);
      expect(summary.byCanvas.map((c) => c.moved), [1, 1]);
      expect(summary.byCanvas.first.maxPixels, 19200);
      expect(summary.byCanvas.last.maxPixels, 19152,
          reason:
              'the same footprint in pixels, and the reason the pixel column '
              'is in the table at all');
      expect(summary.threshold, 0.025);
    });

    test('sorts narrow to wide, then short to tall', () {
      final summary = summariseLines([
        cells(1280, 800, 1),
        cells(480, 4200, 1),
        cells(480, 140, 1),
        cells(1080, 1000, 1),
      ]);

      expect(summary.byCanvas.map((c) => c.label),
          ['480x140', '480x4200', '1080x1000', '1280x800'],
          reason: 'narrow to wide is the direction the blindness grows in');
    });

    test('a canvas with a denominator and no movers still appears', () {
      // Otherwise a canvas that is entirely quiet vanishes from the table, and a
      // canvas that was never swept looks the same as one that was.
      final summary = summariseLines([cells(1280, 800, 234)]);

      expect(summary.byCanvas.single.compared, 234);
      expect(summary.byCanvas.single.moved, 0);
      expect(summary.byCanvas.single.max, 0);
      expect(summary.byCanvas.single.maxPixels, 0);
      expect(summary.byCanvas.single.denominatorRepaired, isFalse);
    });

    test('lines accumulate, whichever suite wrote them', () {
      // The file is one append-only log shared by concurrent suites and repeated
      // per locale, so the same canvas arrives in several `cells` lines.
      final summary = summariseLines([
        cells(480, 800, 40),
        cells(480, 800, 40),
        diff(480, 800, 0.01, golden: 'en'),
        diff(480, 800, 0.02, golden: 'el'),
      ]);

      expect(summary.byCanvas.single.compared, 80);
      expect(summary.byCanvas.single.diffs, [0.01, 0.02],
          reason: 'ascending, whatever order the run recorded them in');
    });

    test('a record with no matching cells line is counted and flagged', () {
      // A torn `cells` line leaves records without a denominator. Dropping them
      // would under-report a real diff; counting them without saying so would
      // print a percentile over a denominator that is a lower bound.
      final summary = summariseLines([diff(601, 900, 0.5)]);

      expect(summary.byCanvas.single.compared, 1);
      expect(summary.byCanvas.single.moved, 1);
      expect(summary.byCanvas.single.denominatorRepaired, isTrue);
      expect(summary.repaired, hasLength(1));
    });

    test('failures are held out of the floor', () {
      final summary = summariseLines([
        threshold,
        cells(480, 1000, 40),
        diff(480, 1000, 0.04209, golden: 'regressed', passed: false),
        diff(480, 1000, 0.0004, golden: 'noise'),
      ]);

      final canvas = summary.byCanvas.single;
      expect(canvas.failed, 1);
      expect(canvas.moved, 1, reason: 'moved counts what was tolerated');
      expect(canvas.max, 0.0004,
          reason: 'the floor is the largest movement the run allowed through, '
              'not the largest it saw');
      expect(canvas.population, 39,
          reason: 'the failing cell is not a sample of the environment');
      expect(summary.failures.single.golden, 'regressed');
    });

    test('zero-diff records do not inflate the mover count', () {
      // The runner does not write them, but a hand-merged or older report can.
      final summary = summariseLines([
        cells(480, 800, 2),
        diff(480, 800, 0.0),
        diff(480, 800, 0.01),
      ]);

      expect(summary.byCanvas.single.moved, 1);
      expect(summary.byCanvas.single.max, 0.01);
    });

    test('unreadable and unknown lines are counted, not dropped', () {
      final summary = summariseLines([
        cells(480, 800, 1),
        '{"type":"cells","width":480,he', // a torn append
        '{"type":"something_else"}',
        '', // trailing newline
        '   ',
      ]);

      expect(summary.skippedLines, 2,
          reason:
              'blank lines are not evidence of anything; the other two are');
      expect(summary.compared, 1);
    });

    test('carries unmeasured and a null threshold through', () {
      final summary = summariseLines([
        '{"type":"unmeasured","count":3}',
        '{"type":"unmeasured","count":2}',
      ]);

      expect(summary.unmeasured, 5);
      expect(summary.threshold, isNull);
      expect(summary.byCanvas, isEmpty);
    });

    test('counts baseline-less cells separately from unmeasured ones', () {
      // Two causes, one consequence — no `diffPercent` — and different remedies,
      // so the summary has to be able to say which one happened.
      final summary = summariseLines([
        cells(480, 800, 6),
        '{"type":"uncomparable","count":1}',
        '{"type":"unmeasured","count":2}',
      ]);

      expect(summary.uncomparable, 1);
      expect(summary.unmeasured, 2);
      expect(summary.compared, 6,
          reason: 'the cell that had no baseline was never compared, so it is '
              'absent from the denominator — which is what the warning says');
    });

    test('an empty report summarises to nothing rather than throwing', () {
      final summary = summariseLines(const []);

      expect(summary.byCanvas, isEmpty);
      expect(summary.compared, 0);
      expect(summary.skippedLines, 0);
    });
  });

  group('worstByWidth', () {
    test('reports the worst canvas per width, and names it', () {
      // The per-width figure AC1 asks for. The tallest canvas is not the one that
      // produces it — the same footprint is a smaller fraction of a taller canvas
      // — so the row has to say which canvas the number came from.
      final summary = summariseLines([
        threshold,
        cells(480, 1000, 40),
        cells(480, 4200, 40),
        diff(480, 1000, 0.02, golden: 'short-one'),
        diff(480, 4200, 0.005, golden: 'tall-one'),
        cells(1280, 1000, 40),
        diff(1280, 1000, 0.00858, golden: 'wide-one'),
      ]);

      expect(summary.worstByWidth.map((w) => w.width), [480, 1280]);
      final narrow = summary.worstByWidth.first;
      expect(narrow.canvas.label, '480x1000');
      expect(narrow.max, 0.02);
      expect(narrow.worst?.golden, 'short-one');
      expect(narrow.compared, 80,
          reason: 'every cell at that width, across its canvases');
    });

    test('a width that tolerated nothing is omitted', () {
      final summary = summariseLines([
        cells(480, 800, 40),
        cells(1280, 800, 40),
        diff(1280, 800, 0.01),
      ]);

      expect(summary.worstByWidth.map((w) => w.width), [1280]);
    });

    test('a width whose only movement failed is omitted', () {
      // Nothing was tolerated, so there is no floor to clear — and the failure
      // warning is where that cell belongs.
      final summary = summariseLines([
        cells(480, 800, 40),
        diff(480, 800, 0.4, passed: false),
      ]);

      expect(summary.worstByWidth, isEmpty);
      expect(summary.failed, 1);
    });
  });

  group('formatSummary', () {
    test('reports the max as a fraction of the allowance', () {
      // The one derived number in the table, and the one the ticket is about:
      // 1.376% of a 2.5% allowance is 55% used — a real regression that passed
      // with room to spare.
      final text = formatSummary(summariseLines([
        threshold,
        cells(1080, 1000, 100),
        diff(1080, 1000, 0.01376, golden: 'topology-screen1080-en'),
      ]));

      expect(text, contains('1080x1000'));
      expect(text, contains('1.376%'));
      expect(text, contains('55.0%'));
      expect(text, contains('14861'), reason: 'the same movement in pixels');
      expect(text, contains('1 of 100 compared cells differed'));
      expect(text, contains('topology-screen1080-en'),
          reason: 'the per-width line names the golden to investigate');
      expect(text, contains('worst of 100 cells'),
          reason: 'and its sample size, because one mover out of four cells '
              'and one out of four hundred justify different margins');
    });

    test('a floor of a few pixels does not print as zero', () {
      // What `toStringAsFixed(3)` did to this case: one pixel of 480x4200 is
      // 0.0000496%, and a table reading "every cell moved, max 0.000%" tells the
      // reader the floor is zero.
      final text = formatSummary(summariseLines([
        threshold,
        cells(480, 4200, 1),
        diff(480, 4200, 1 / (480 * 4200)),
      ]));

      expect(text, isNot(contains('0.000%')));
      expect(text, contains('0.0000496%'));
      expect(text, matches(RegExp(r'0\.0000496%\s+1\s')),
          reason: 'and the pixel column says it is one pixel, which is the '
              'reading that needs no arithmetic');
    });

    test('says so when nothing moved, and says which run would say otherwise',
        () {
      final text = formatSummary(summariseLines([
        threshold,
        cells(480, 800, 234),
      ]));

      expect(text, contains('byte-identical'));
      expect(text, contains('golden-ci'),
          reason: 'a zero floor measured locally is not the CI floor AC1 asks '
              'for, and the output has to say that where it is read');
    });

    test('a run with failures is not reported as a floor', () {
      final text = formatSummary(summariseLines([
        threshold,
        cells(480, 1000, 10),
        diff(480, 1000, 0.4, golden: 'stale-baseline', passed: false),
      ]));

      expect(text, contains('excluded from the'));
      expect(text, contains('noise floor cannot be'));
      expect(text, contains('stale-baseline'));
      expect(text, isNot(contains('byte-identical')),
          reason: 'nothing moved that was tolerated, but the run is not quiet');
      expect(
          text,
          contains(
              '0 of 10 compared cells differed within tolerance, and 1 more '
              'exceeded it'),
          reason: 'the count sentence covers the failures too — `moved` counts '
              'only the tolerated ones, so stating it alone would undercount '
              'and contradict the warning below it');
    });

    test('warns loudly when cells went unmeasured', () {
      final text = formatSummary(summariseLines([
        threshold,
        cells(480, 800, 10),
        '{"type":"unmeasured","count":3}',
      ]));

      expect(text, contains('WARNING'));
      expect(text, contains('3 cell(s)'));
    });

    test('a baseline-less cell is warned about, and blocks the quiet verdict',
        () {
      // The run this was found on: every compared cell was identical *and* one
      // state had no baseline. "Every compared cell was byte-identical" is true
      // and would still have read as a clean floor.
      final text = formatSummary(summariseLines([
        threshold,
        cells(480, 800, 6),
        '{"type":"uncomparable","count":1}',
      ]));

      expect(text, contains('1 cell(s) had no baseline'));
      expect(text, contains('denominator'));
      expect(text, isNot(contains('byte-identical')));
    });

    test('warns when the report itself is incomplete', () {
      final text = formatSummary(summariseLines([
        cells(480, 800, 1),
        '{"type":"diff","golden":"torn"',
        diff(601, 900, 0.5),
      ]));

      expect(text, contains('1 line(s) of the report could'));
      expect(text, contains('601x900'),
          reason: 'the canvas whose denominator had to be repaired is named');
      expect(text, contains('lower bound'));
    });

    test('a report with no threshold prints no allowance', () {
      final text = formatSummary(summariseLines([cells(480, 800, 1)]));

      expect(text, contains('n/a'));
      expect(text, isNot(contains('threshold ')));
    });
  });
}
