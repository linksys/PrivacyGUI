import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records how far every golden moved from its baseline, including the cells that
/// **passed**.
///
/// ## The blindness this measures (#1475)
///
/// `diffThreshold: 0.025` (`flutter_test_config.dart`) is a fraction of the
/// canvas, so the pixel allowance grows with area while a defect confined to a
/// chip, a badge, a dot or a link style is laid out at a fixed size. #1472's
/// dropped liveness, on `usp_topology_view`'s 1000 px-tall canvases, moved 4.209 %
/// of `phone480` — 20,203 px against a 12,000 px allowance, so it failed — but
/// 1.376 % of `screen1080` and 0.858 % of `desktop1280`: 14,861 and 10,982 px
/// against allowances of 27,000 and 32,000. The footprint *shrank* by half as the
/// canvas widened and the allowance nearly tripled, so the two wider widths are
/// blind to it by construction, and the wider they get the blinder they are.
///
/// The height matters as much as the width and is per suite, because
/// `GoldenTestConfig` pins it. At width 480 alone the baselines hold heights from
/// 140 to 4200, so two cells swept at "the same width" can differ 30× in area — and
/// so in what one percent of them means. Everything here is therefore recorded and
/// grouped by canvas rather than by width alone. The census is in
/// `doc/screenshot_test/golden_diff_noise_floor.md`, stated once because it expires
/// whenever a suite is added.
///
/// ## Why this file exists rather than a threshold change
///
/// The same threshold is what absorbs CI platform noise — font rasterisation,
/// CanvasKit version, GPU vs software. Scaling the wide widths down to
/// `phone480`'s effective sensitivity without knowing that floor risks turning
/// the whole suite red, so #1475's AC1 is to *measure* the floor per width across
/// a golden-ci run with no app change, and only then pick numbers.
///
/// That measurement could not be taken. `AlchemistFileComparator.compare`
/// computes `diffPercent`, compares it to the threshold, and on a pass **returns
/// `true` and drops the number** (`alchemist/lib/src/alchemist_file_comparator.dart`).
/// A run where every cell diffs by 2.4 % is byte-for-byte as quiet as a run where
/// every cell is identical. So the instrument comes first: this comparator keeps
/// the number it was already computing.
///
/// **No threshold is changed here, and none is picked.** This is AC1's
/// instrument, not its answer — see `doc/screenshot_test/golden_diff_noise_floor.md`
/// for the procedure that turns a golden-ci run into the numbers.
///
/// ## Cost
///
/// None worth measuring. [GoldenDiffRecordingComparator] *replaces* alchemist's
/// comparator for the duration of one golden rather than wrapping it, so the
/// image decode and the pixel walk happen exactly once per cell, as before. What
/// is new is one record in memory per moved cell and one append per suite.
///
/// The equal cells are not recorded individually — they are the overwhelming
/// majority and a list of zeroes is not evidence — but they are *counted*, per
/// canvas, because "3 cells of 3,120 moved at all" and "3 of 3" are different
/// findings and only the denominator separates them.

/// The surface a cell was rendered at: `GoldenTestConfig.height ?? 800` by the
/// device's width.
///
/// The grouping key for everything this file counts. A value type rather than a
/// `'${width}x$height'` string so the width and the height survive to the report
/// without anybody having to parse them back out.
class GoldenCanvas {
  const GoldenCanvas(this.width, this.height);

  /// The device width the cell was swept at, in logical pixels.
  final int width;

  /// The surface height: whatever `GoldenTestConfig.height` pinned, else 800.
  final int height;

  @override
  bool operator ==(Object other) =>
      other is GoldenCanvas && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}

/// One golden whose render differed from its baseline by a non-zero amount.
///
/// [diffPercent] is alchemist's own figure: the fraction of differing pixels over
/// the whole canvas, which is the quantity `diffThreshold` is compared against, so
/// the two are directly comparable without a conversion nobody would remember.
///
/// [width] and [height] come from the surface the runner set, not from the decoded
/// image, so a record is attributable to a viewport even when the two disagree —
/// which is itself a finding rather than something to paper over.
class GoldenDiffRecord {
  const GoldenDiffRecord({
    required this.golden,
    required this.width,
    required this.height,
    required this.diffPercent,
    required this.passed,
  });

  /// The golden's file name without extension, as `_goldenFileName` built it:
  /// `{view}-{state}-{device}-{locale}[-dark]`.
  final String golden;

  /// The [canvas] width the cell was rendered at.
  final int width;

  /// The [canvas] height the cell was rendered at.
  final int height;

  /// Fraction of the canvas that differs, in `[0, 1]`.
  final double diffPercent;

  /// Whether the cell was allowed through — `diffPercent <= diffThreshold`.
  ///
  /// Recorded rather than derived at read time so a report can be read on its own
  /// terms after the threshold has moved, which is the whole point of moving it.
  final bool passed;

  /// The surface this cell was rendered at, and the key it is counted under.
  GoldenCanvas get canvas => GoldenCanvas(width, height);

  Map<String, dynamic> toJson() => {
        'type': 'diff',
        'golden': golden,
        'width': width,
        'height': height,
        'diffPercent': diffPercent,
        'passed': passed,
      };
}

/// The per-run sink. Static because the comparator is installed by the framework
/// and read by a `tearDownAll`, the same shape `golden_runner.dart` already uses
/// for overflow records.
class GoldenDiffLog {
  GoldenDiffLog._();

  /// Cells that moved at all, in the order they were compared.
  static final List<GoldenDiffRecord> records = [];

  /// Every compared cell, keyed by the canvas it was rendered at — the
  /// denominator [records] is a numerator of.
  ///
  /// Keyed by canvas rather than by width because `diffPercent` is normalised by
  /// area: at width 480 this suite's cells are 480x1000 and `usp_statistics_view`'s
  /// are 480x4200, so the same 20,000 differing pixels are 4.2 % of one and 1.0 %
  /// of the other. Pooling them would average two different units.
  static final Map<GoldenCanvas, int> comparedByCanvas = {};

  /// Cells that were rendered and compared with no recorder installed, so their
  /// `diffPercent` was lost the way every cell's used to be.
  ///
  /// Counted rather than ignored: the recorder attaches to alchemist's comparator,
  /// and alchemist only installs that one while `diffThreshold > 0`. Setting the
  /// threshold to 0 would therefore switch this instrument off silently, which is
  /// the failure mode #1475 is about. A non-zero number here means the report's
  /// silence is not evidence.
  static int unmeasured = 0;

  /// Cells whose baseline could not be read, so there was nothing to diff against.
  ///
  /// A different cause from [unmeasured] with the same consequence, and reported
  /// separately because the remedies differ: this one is a new or renamed state, or
  /// a `goldens/` that was never populated. It is counted because the alternative
  /// is a canvas whose denominator is quietly one short — which the summary would
  /// then divide by.
  static int uncomparable = 0;

  /// The threshold the run judged by, as observed on the installed comparator.
  ///
  /// Nullable because a run that never compared anything — a generation run, where
  /// `matchesGoldenFile` calls `update` — has no threshold to report.
  static double? threshold;

  static void add(GoldenDiffRecord record) {
    comparedByCanvas.update(record.canvas, (n) => n + 1, ifAbsent: () => 1);
    if (record.diffPercent > 0) records.add(record);
  }

  static void clear() {
    records.clear();
    comparedByCanvas.clear();
    unmeasured = 0;
    uncomparable = 0;
    threshold = null;
  }
}

/// [AlchemistFileComparator]'s behaviour, with the number it discards kept.
///
/// Subclassed rather than wrapped so there is exactly one comparison per cell:
/// wrapping would mean decoding both PNGs twice, once to read `diffPercent` and
/// once for the inner comparator's own verdict.
///
/// The verdict is deliberately alchemist's, restated line for line — equal passes,
/// within-threshold passes, anything else writes the failure output and fails. A
/// diagnostic must not be able to change which runs go red; if this drifts from
/// the parent, `golden_diff_record_test.dart` is where it shows up.
class GoldenDiffRecordingComparator extends AlchemistFileComparator {
  GoldenDiffRecordingComparator(
    super.testUri,
    super.diffThreshold, {
    required this.golden,
    required this.width,
    required this.height,
  });

  /// Builds a recorder over the comparator alchemist installed for this cell,
  /// keeping its base directory and its threshold.
  ///
  /// `_alchemist.dart` as the file name for the same reason
  /// [AlchemistFileComparator.fromExisting] uses it: [LocalFileComparator] derives
  /// its `basedir` from the *directory* of the URI it is given, so any file name in
  /// the right directory reproduces it.
  factory GoldenDiffRecordingComparator.over(
    AlchemistFileComparator existing, {
    required String golden,
    required int width,
    required int height,
  }) =>
      GoldenDiffRecordingComparator(
        existing.basedir.resolve('_alchemist.dart'),
        existing.diffThreshold,
        golden: golden,
        width: width,
        height: height,
      );

  /// The name recorded for whatever cell this comparator was installed for. One
  /// comparator serves one cell: the runner installs it inside `pumpWidget` and
  /// alchemist restores the original in a `finally`.
  final String golden;

  /// The surface width the cell was pumped at, taken from the runner rather than
  /// from the decoded image — see [GoldenDiffRecord.width].
  final int width;

  /// The surface height the cell was pumped at.
  final int height;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri goldenKey) async {
    final List<int> goldenBytes;
    try {
      goldenBytes = await getGoldenBytes(goldenKey);
    } catch (_) {
      // No baseline to compare against — a new state, a renamed one, or a run
      // against an unpopulated `goldens/`. There is no `diffPercent` to keep, and
      // recording nothing would silently shrink the canvas's denominator: this is
      // exactly how the probe run that verified this file showed 6 cells at
      // 480x800 and 7 at 1280x800 for the same suite, with nothing to say why.
      // Counted, then rethrown — the verdict stays the parent's, and a missing
      // baseline must still fail the cell.
      GoldenDiffLog.uncomparable++;
      rethrow;
    }
    final result = await compareImageBytes(
      imageBytes,
      Uint8List.fromList(goldenBytes),
    );

    // Read before disposing: `dispose()` releases the diff images, and
    // `diffPercent` is what this class exists to keep. The `passed` disjunction
    // is the parent's two `return true`s spelled as one expression — including
    // the `diffThreshold > 0` guard, which is redundant today (`passed: false`
    // implies `diffPercent > 0` in `compareLists`) and kept anyway so this reads
    // as a restatement rather than as a claim about the SDK.
    final diffPercent = result.passed ? 0.0 : result.diffPercent;
    final passed =
        result.passed || (diffThreshold > 0 && diffPercent <= diffThreshold);
    GoldenDiffLog.add(GoldenDiffRecord(
      golden: golden,
      width: width,
      height: height,
      diffPercent: diffPercent,
      passed: passed,
    ));

    if (passed) {
      // `LocalFileComparator` disposes here and `AlchemistFileComparator` does
      // not; the SDK's behaviour is the correct one and costs nothing to keep.
      result.dispose();
      return true;
    }

    await generateFailureOutput(result, goldenKey, basedir);
    result.dispose();
    return false;
  }
}

/// Installs a recorder for the golden about to be pumped, if there is a comparator
/// to record through.
///
/// Called from the runner's `pumpWidget`, which is the one moment where the
/// comparator alchemist installed for this cell is reachable: it swaps at the top
/// of `goldenTestRunner.run` and restores the original in that method's `finally`,
/// so the recorder lives for exactly one cell and needs no teardown of its own.
void installGoldenDiffRecorder({
  required String golden,
  required int width,
  required int height,
}) {
  final existing = goldenFileComparator;
  if (existing is! AlchemistFileComparator) {
    // No threshold means no alchemist comparator, which means no diffPercent to
    // keep. Counted so the report can say so — see [GoldenDiffLog.unmeasured].
    GoldenDiffLog.unmeasured++;
    return;
  }
  GoldenDiffLog.threshold = existing.diffThreshold;
  goldenFileComparator = GoldenDiffRecordingComparator.over(
    existing,
    golden: golden,
    width: width,
    height: height,
  );
}

/// The report's file name, alongside `overflow_warnings.json`.
///
/// JSON Lines, and that is the whole design: every suite *appends* its own lines
/// and nothing ever reads the file back in order to rewrite it.
///
/// `_writeOverflowReport` next door does read-modify-write, and documents both the
/// race and its own reason for accepting it: only 7 suites write at all, so the
/// window is narrow, and four measured runs lost nothing. Neither half of that
/// reasoning transfers here. **Every** suite writes — each one compares cells
/// — and the payload is a run's movers rather than a handful of overflows, so a
/// whole-file rewrite would also be quadratic in the number of records. Worse, the
/// thing at risk is the deliverable: a lost write drops a canvas's *denominator*,
/// and the summary would then print a confident percentile over an unknown
/// fraction of the sweep with nothing to indicate it.
///
/// Appending one small line per record removes the class rather than narrowing the
/// window: there is no snapshot to lose, `O_APPEND` puts each line at the current
/// end of file, and a torn line is one skipped record that the reader counts and
/// reports.
const goldenDiffReportName = 'golden_diff_percent.jsonl';

/// This suite's measurements, one JSON object per line of the report.
///
/// Separated from the file write so the shape can be asserted without a
/// filesystem. Lines are self-describing (`type`) and order-independent — the
/// reader may see them interleaved with any other suite's.
List<Map<String, dynamic>> goldenDiffReportLines() => [
      if (GoldenDiffLog.threshold != null)
        {'type': 'threshold', 'value': GoldenDiffLog.threshold},
      for (final entry in GoldenDiffLog.comparedByCanvas.entries)
        {
          'type': 'cells',
          'width': entry.key.width,
          'height': entry.key.height,
          'count': entry.value,
        },
      for (final record in GoldenDiffLog.records) record.toJson(),
      if (GoldenDiffLog.unmeasured > 0)
        {'type': 'unmeasured', 'count': GoldenDiffLog.unmeasured},
      if (GoldenDiffLog.uncomparable > 0)
        {'type': 'uncomparable', 'count': GoldenDiffLog.uncomparable},
    ];

/// Appends what this suite measured to the run's report.
///
/// Empty runs write nothing, so a missing file means "nothing was compared", which
/// is what a generation run does.
///
/// Nothing here may throw. An exception out of the runner's `tearDownAll` is
/// reported as a suite failure, which would make this diagnostic a second,
/// undocumented gate — the exact property `run_golden_verify.sh` states when it
/// refuses to let the summary change the exit code. A full disk or a `goldens/`
/// removed underneath us costs the measurement, not the run.
void writeGoldenDiffReport({String directory = 'goldens'}) {
  if (GoldenDiffLog.comparedByCanvas.isEmpty &&
      GoldenDiffLog.unmeasured == 0 &&
      GoldenDiffLog.uncomparable == 0) {
    return;
  }

  try {
    final dir = Directory(directory);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final handle = File('$directory/$goldenDiffReportName')
        .openSync(mode: FileMode.append);
    try {
      // One `writeStringSync` per line, not one for the whole batch: a small
      // append lands as a single write at the end of the file, so concurrent
      // suites interleave whole lines instead of splitting one.
      for (final line in goldenDiffReportLines()) {
        handle.writeStringSync('${jsonEncode(line)}\n');
      }
    } finally {
      handle.closeSync();
    }
  } catch (error) {
    stderr.writeln('[#1475] could not append $goldenDiffReportName: $error');
  } finally {
    // Cleared even when the write failed: keeping the records would report this
    // suite's cells again under the next suite's write in the same isolate.
    GoldenDiffLog.clear();
  }
}
