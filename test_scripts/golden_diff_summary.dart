import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Summarises `goldens/golden_diff_percent.jsonl` — the per-cell diff record the
/// golden runner appends to (`test/golden_test/golden_framework/golden_diff_record.dart`).
///
/// This is the read side of #1475's AC1: *measure the observed noise floor per
/// width across a golden-ci run with no app change, and only then pick numbers.*
/// The instrument records; this prints what it recorded so the numbers can be
/// picked from evidence rather than from arithmetic about pixel areas.
///
/// ## Grouped by canvas, not by width
///
/// `diffPercent` is differing pixels over the *whole canvas*, and the canvas is a
/// width by whatever height that suite pinned. At width 480 alone the baselines hold
/// heights from 140 to 4200, so two canvases at "the same width" differ 30x in area
/// and the same 20,000 differing pixels are 4.2 % of one and 1.0 % of the other. A
/// row per width would average those two units together and the "floor" it printed
/// would describe no population at all. (Census, and how to re-measure it:
/// `doc/screenshot_test/golden_diff_noise_floor.md` — stated once because it expires
/// whenever a suite is added.)
///
/// The per-width answer AC1 asks for is still printed — as the *worst* tolerated
/// movement across the canvases at that width, which is the number a per-width
/// threshold has to clear — with the canvas table below it as the evidence.
///
/// It deliberately does **not** suggest a threshold. The suite's single
/// `diffThreshold: 0.025` absorbs two different things — real regressions and CI
/// platform noise (font rasterisation, CanvasKit build, GPU vs software) — and only
/// a run with no app change separates them. A recommendation printed from a local
/// run, where the noise floor is usually zero, would be the wrong number with a
/// confident label on it.
///
/// Usage:
///
/// ```sh
/// dart run test_scripts/golden_diff_summary.dart [path/to/golden_diff_percent.jsonl]
/// ```
///
/// A missing file is not an error: a generation run calls `update` rather than
/// `compare`, so it writes no report and there is nothing to summarise.

/// Where the golden runner appends the report.
const defaultReportPath = 'goldens/golden_diff_percent.jsonl';

/// One golden that moved, and by how much.
class GoldenDiffEntry {
  const GoldenDiffEntry(this.golden, this.diffPercent);

  /// The cell's golden name — `state-device-locale`, as the runner spells it.
  final String golden;

  /// Fraction of the canvas that differed, in `[0, 1]`.
  final double diffPercent;
}

/// What one canvas geometry did across the run.
class CanvasStats {
  CanvasStats({
    required this.width,
    required this.height,
    required this.declaredCompared,
    required List<GoldenDiffEntry> passing,
    required this.failures,
  }) : passing = List.of(passing)
          ..sort((a, b) => a.diffPercent.compareTo(b.diffPercent));

  final int width;
  final int height;

  /// Cells this canvas reported comparing, from the report's `cells` lines.
  ///
  /// [compared] rather than this is the denominator to use; see there.
  final int declaredCompared;

  /// The cells that moved and were *tolerated*, ascending. Shorter than
  /// [population] by the number of byte-identical cells, which the runner counts
  /// but does not list.
  final List<GoldenDiffEntry> passing;

  /// The cells that moved and were rejected. Kept out of the floor: see
  /// [population].
  final List<GoldenDiffEntry> failures;

  String get label => '${width}x$height';
  int get area => width * height;

  int get moved => passing.length;
  int get failed => failures.length;

  /// Every cell compared at this canvas, including the ones that did not move.
  ///
  /// Never smaller than the cells actually recorded, so the table can never claim
  /// more movers than cells. The two can disagree if a `cells` line was torn or
  /// lost, and [denominatorRepaired] says so rather than leaving the repair silent.
  int get compared => math.max(declaredCompared, moved + failed);

  bool get denominatorRepaired => compared > declaredCompared;

  /// The cells the floor is measured over: the ones that passed.
  ///
  /// A failing cell in a no-change run is a stale baseline or a real regression,
  /// and either way it is a thing to explain rather than a sample of the
  /// environment's noise. Including it would raise `max` above the threshold and
  /// invite exactly the wrong conclusion — that the floor is higher than the
  /// allowance.
  int get population => math.max(0, compared - failed);

  /// The largest tolerated movement, as a fraction of the canvas.
  double get max => passing.isEmpty ? 0 : passing.last.diffPercent;

  /// [max] in pixels — the unit the noise floor is actually produced in, and the
  /// only one that is comparable across canvases.
  int get maxPixels => (max * area).round();

  /// The golden [max] came from, or null if nothing moved.
  GoldenDiffEntry? get worst => passing.isEmpty ? null : passing.last;

  late final List<double> diffs = [
    for (final entry in passing) entry.diffPercent
  ];

  /// The [fraction]-quantile over **all** [population] cells, zeros included.
  ///
  /// Zeros included because the question this answers is "what allowance would
  /// keep a no-change run green", and a run is all of its cells. Quantiles over
  /// the movers alone answer a different question and read ~100x larger.
  ///
  /// Nearest-rank, no interpolation: the value at position `ceil(fraction x N)`
  /// in the ascending population. So the result is always an observed diff rather
  /// than an average of two of them, and p100 is [max].
  double percentile(double fraction) =>
      percentileOf(diffs, population, fraction);
}

/// [CanvasStats.percentile]'s arithmetic, as a function so it can be tested on the
/// edges: one cell, two cells, and a population whose zeros swallow the quantile.
///
/// [ascending] holds only the non-zero diffs; the other `population - length`
/// cells are zeros ranked below them. A quantile that lands in that zero block is
/// 0, which is the common and correct answer for a healthy run.
double percentileOf(List<double> ascending, int population, double fraction) {
  if (population <= 0) return 0;
  // Rank in [1, population], so fraction 0 picks the smallest cell and 1 the
  // largest. `ceil` rather than `round`: p95 must not fall below the 95th
  // percentile just because the population is small.
  final rank = (fraction * population).ceil().clamp(1, population);
  final zeros = population - ascending.length;
  if (rank <= zeros) return 0;
  return ascending[rank - zeros - 1];
}

/// The worst movement one width tolerated, across every canvas at that width.
///
/// The per-width figure AC1 asks for. A threshold is compared against
/// `diffPercent`, so a per-width threshold has to clear the largest `diffPercent`
/// any canvas at that width produced — the tallest canvas is usually not the one
/// that produces it, which is why the canvas is named.
class WidthWorst {
  const WidthWorst({
    required this.width,
    required this.compared,
    required this.canvas,
  });

  /// The swept width, in logical pixels.
  final int width;

  /// Every cell compared at this width, across all of its canvases — the sample
  /// size behind [max], which is printed because one mover out of four cells and
  /// one out of four hundred justify different margins.
  final int compared;

  /// The canvas at this width that produced [max].
  final CanvasStats canvas;

  /// The largest movement this width tolerated, as a fraction of [canvas].
  double get max => canvas.max;

  /// The golden [max] came from.
  GoldenDiffEntry? get worst => canvas.worst;
}

/// The whole run, by canvas.
class GoldenDiffSummary {
  const GoldenDiffSummary({
    required this.byCanvas,
    required this.unmeasured,
    required this.uncomparable,
    required this.skippedLines,
    this.threshold,
  });

  /// Ascending by width then height, so the table reads narrow to wide — the
  /// direction the blindness grows in.
  final List<CanvasStats> byCanvas;

  /// Cells compared with no recorder installed. Non-zero means this report's
  /// silence is not evidence; see `GoldenDiffLog.unmeasured`.
  final int unmeasured;

  /// Cells whose baseline could not be read, so nothing was diffed. Every one is
  /// a cell missing from some canvas's denominator; see `GoldenDiffLog.uncomparable`.
  final int uncomparable;

  /// Lines that could not be read as a measurement — a torn append, or a report
  /// from an older shape. Counted so an incomplete report cannot read as a quiet
  /// one.
  final int skippedLines;

  /// The threshold the run judged by, or null if nothing was compared.
  final double? threshold;

  int get compared => byCanvas.fold(0, (total, c) => total + c.compared);
  int get moved => byCanvas.fold(0, (total, c) => total + c.moved);
  int get failed => byCanvas.fold(0, (total, c) => total + c.failed);

  List<CanvasStats> get repaired =>
      byCanvas.where((c) => c.denominatorRepaired).toList();

  List<GoldenDiffEntry> get failures =>
      [for (final canvas in byCanvas) ...canvas.failures];

  /// [byCanvas] rolled up to one row per width, keeping the canvas that produced
  /// the largest tolerated diff. Widths that tolerated nothing are omitted:
  /// "the worst movement was none" is already the table's story.
  List<WidthWorst> get worstByWidth {
    final worst = <int, CanvasStats>{};
    for (final canvas in byCanvas) {
      if (canvas.max <= 0) continue;
      final incumbent = worst[canvas.width];
      if (incumbent == null || canvas.max > incumbent.max) {
        worst[canvas.width] = canvas;
      }
    }
    final widths = worst.keys.toList()..sort();
    return [
      for (final width in widths)
        WidthWorst(
          width: width,
          compared: byCanvas
              .where((c) => c.width == width)
              .fold(0, (total, c) => total + c.compared),
          canvas: worst[width]!,
        ),
    ];
  }
}

/// Reads the runner's JSON Lines into per-canvas statistics.
///
/// Every line is independent and order does not matter, because concurrent suites
/// append to one file. A line that is not readable as a measurement is counted in
/// [GoldenDiffSummary.skippedLines] rather than dropped silently or thrown from:
/// the file is append-only, so the only way to lose data is a torn write, and a
/// summary that hid one would be a measurement claiming to be complete.
GoldenDiffSummary summariseLines(Iterable<String> lines) {
  final declared = <(int, int), int>{};
  final passing = <(int, int), List<GoldenDiffEntry>>{};
  final failures = <(int, int), List<GoldenDiffEntry>>{};
  var unmeasured = 0;
  var uncomparable = 0;
  var skipped = 0;
  double? threshold;

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    try {
      final entry = jsonDecode(line) as Map<String, dynamic>;
      switch (entry['type']) {
        case 'threshold':
          threshold = (entry['value'] as num).toDouble();
        case 'cells':
          final canvas = (
            (entry['width'] as num).toInt(),
            (entry['height'] as num).toInt()
          );
          declared.update(
            canvas,
            (n) => n + (entry['count'] as num).toInt(),
            ifAbsent: () => (entry['count'] as num).toInt(),
          );
        case 'diff':
          final canvas = (
            (entry['width'] as num).toInt(),
            (entry['height'] as num).toInt()
          );
          final diff = (entry['diffPercent'] as num).toDouble();
          // A zero-diff record is not a mover. The runner does not write one, but
          // a hand-merged or older report can.
          if (diff <= 0) continue;
          final record =
              GoldenDiffEntry(entry['golden'] as String, diff.toDouble());
          final into = (entry['passed'] as bool? ?? true) ? passing : failures;
          into.putIfAbsent(canvas, () => []).add(record);
        case 'unmeasured':
          unmeasured += (entry['count'] as num).toInt();
        case 'uncomparable':
          uncomparable += (entry['count'] as num).toInt();
        default:
          skipped++;
      }
    } catch (_) {
      skipped++;
    }
  }

  final canvases = <(int, int)>{
    ...declared.keys,
    ...passing.keys,
    ...failures.keys,
  }.toList()
    ..sort(
        (a, b) => a.$1 == b.$1 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));

  return GoldenDiffSummary(
    byCanvas: [
      for (final canvas in canvases)
        CanvasStats(
          width: canvas.$1,
          height: canvas.$2,
          declaredCompared: declared[canvas] ?? 0,
          passing: passing[canvas] ?? const [],
          failures: failures[canvas] ?? const [],
        ),
    ],
    unmeasured: unmeasured,
    uncomparable: uncomparable,
    skippedLines: skipped,
    threshold: threshold,
  );
}

// Table column widths, shared by the header and the rows.
const _wCanvas = 12;
const _wCells = 8;
const _wMoved = 8;
const _wMax = 12;
const _wMaxPx = 10;
const _wP95 = 12;
const _wP99 = 12;
const _wAllowance = 11;

/// Renders [summary] as the table printed after a golden run.
///
/// A string rather than prints so the shape is assertable — the columns are the
/// deliverable, and a table nobody can test drifts into a table nobody reads.
String formatSummary(GoldenDiffSummary summary) {
  final lines = <String>[];
  final threshold = summary.threshold;

  lines.add('Golden diff percentages by canvas'
      '${threshold == null ? '' : ' (threshold ${_pct(threshold)})'}');
  lines.add('');
  // Column widths are shared with the rows below so the table lines up; a header
  // written by hand drifts the first time a column changes.
  lines.add([
    'canvas'.padLeft(_wCanvas),
    'cells'.padLeft(_wCells),
    'moved'.padLeft(_wMoved),
    'max diff'.padLeft(_wMax),
    'max px'.padLeft(_wMaxPx),
    'p95'.padLeft(_wP95),
    'p99'.padLeft(_wP99),
    'of allow'.padLeft(_wAllowance),
  ].join());
  lines.add('-' *
      (_wCanvas +
          _wCells +
          _wMoved +
          _wMax +
          _wMaxPx +
          _wP95 +
          _wP99 +
          _wAllowance));

  for (final canvas in summary.byCanvas) {
    lines.add([
      canvas.label.padLeft(_wCanvas),
      '${canvas.compared}'.padLeft(_wCells),
      '${canvas.moved}'.padLeft(_wMoved),
      _pct(canvas.max).padLeft(_wMax),
      '${canvas.maxPixels}'.padLeft(_wMaxPx),
      _pct(canvas.percentile(0.95)).padLeft(_wP95),
      _pct(canvas.percentile(0.99)).padLeft(_wP99),
      _allowance(canvas.max, threshold).padLeft(_wAllowance),
    ].join());
  }

  lines.add('');
  // `moved` counts only what was tolerated, so on a run with failures this
  // sentence has to name them too — otherwise it undercounts the cells that
  // differed and contradicts the WARNING printed below it.
  lines.add(summary.failed == 0
      ? '  ${summary.moved} of ${summary.compared} compared cells differed from '
          'their baseline.'
      : '  ${summary.moved} of ${summary.compared} compared cells differed '
          'within tolerance, and ${summary.failed} more exceeded it.');

  final worstByWidth = summary.worstByWidth;
  if (worstByWidth.isNotEmpty) {
    lines.add('');
    lines.add('  Worst tolerated movement per width — the figure a per-width '
        'threshold has to clear:');
    for (final width in worstByWidth) {
      // The cell count is the sample size behind the figure: one mover out of
      // four cells and one out of four hundred justify very different margins.
      lines.add('    ${width.width}: ${_pct(width.max)} on '
          '${width.canvas.label} = ${_allowance(width.max, threshold).trim()} '
          'of allowance, worst of ${width.compared} cells — '
          '${width.worst?.golden}');
    }
  }

  if (summary.failed > 0) {
    lines.add('');
    lines.add('  WARNING: ${summary.failed} cell(s) exceeded the threshold and '
        'are excluded from the');
    lines.add('  columns above, which measure only what the run tolerated. A '
        'noise floor cannot be');
    lines.add('  read from a run with failures — explain these first:');
    for (final failure in summary.failures.take(10)) {
      lines.add('    ${_pct(failure.diffPercent)}  ${failure.golden}');
    }
    if (summary.failed > 10) {
      lines.add('    ... and ${summary.failed - 10} more');
    }
  }

  if (summary.unmeasured > 0) {
    lines.add('');
    lines.add('  WARNING: ${summary.unmeasured} cell(s) were compared with no '
        'recorder installed,');
    lines.add('  so their diff was not measured. This report is incomplete — '
        'see GoldenDiffLog.unmeasured.');
  }

  if (summary.uncomparable > 0) {
    lines.add('');
    lines.add('  WARNING: ${summary.uncomparable} cell(s) had no baseline to '
        'compare against, so each is');
    lines.add('  a cell missing from its canvas\'s denominator above. A new or '
        'renamed golden state,');
    lines.add('  or an unpopulated goldens/ — refresh the baselines before '
        'reading this as a floor.');
  }

  if (summary.skippedLines > 0) {
    lines.add('');
    lines.add('  WARNING: ${summary.skippedLines} line(s) of the report could '
        'not be read as a');
    lines.add('  measurement, so this report is incomplete. A torn append is '
        'the likely cause.');
  }

  if (summary.repaired.isNotEmpty) {
    lines.add('');
    lines.add('  WARNING: ${summary.repaired.length} canvas(es) recorded more '
        'cells than they reported');
    lines.add(
        '  comparing (${summary.repaired.map((c) => c.label).join(', ')}), '
        'so their denominator is a');
    lines.add('  lower bound and their percentiles read high.');
  }

  // Only for a run that is quiet *and* complete: cells with no baseline were not
  // compared, so "every compared cell was byte-identical" would be true and still
  // read as a clean floor.
  if (summary.compared > 0 &&
      summary.moved == 0 &&
      summary.failed == 0 &&
      summary.uncomparable == 0) {
    lines.add('');
    lines.add('  Every compared cell was byte-identical. That is a noise floor '
        'of zero for');
    lines
        .add('  this environment — which is the expected local result, and not '
            'the CI figure');
    lines.add('  #1475 needs. Run this against a golden-ci run with no app '
        'change.');
  }

  return lines.join('\n');
}

/// A diff as a share of what the threshold allows: 100 % is a cell that only just
/// passed.
String _allowance(double diff, double? threshold) =>
    threshold == null || threshold == 0
        ? 'n/a'
        : '${(diff / threshold * 100).toStringAsFixed(1)}%';

/// A fraction as a percentage, with enough significant digits to stay a number.
///
/// Not `toStringAsFixed`: one differing pixel of a 480x800 canvas is 0.00026 %,
/// which three decimal places print as `0.000%`. A floor made of a handful of
/// pixels per cell is exactly what this instrument exists to show, and a table
/// that renders it as zero while reporting every cell as moved is worse than no
/// table.
String _pct(double fraction) {
  final percent = fraction * 100;
  if (percent == 0) return '0%';
  final digits = percent.toStringAsPrecision(4);
  // `toStringAsPrecision` pads to four significant digits, so 0.04 arrives as
  // "0.04000" and reads as a precision nobody measured. Exponent forms are left
  // alone — there is no trailing zero to drop there.
  if (!digits.contains('e') && digits.contains('.')) {
    return '${digits.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}%';
  }
  return '$digits%';
}

void main(List<String> args) {
  final path = args.isEmpty ? defaultReportPath : args.first;
  final file = File(path);

  if (!file.existsSync()) {
    // Not a failure: a baseline-generation run compares nothing.
    stdout.writeln('No golden diff report at $path — nothing was compared.');
    return;
  }

  final List<String> lines;
  try {
    lines = file.readAsLinesSync();
  } catch (error) {
    stderr.writeln('Could not read $path: $error');
    exitCode = 1;
    return;
  }

  stdout.writeln(formatSummary(summariseLines(lines)));
}
