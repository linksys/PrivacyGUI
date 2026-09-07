import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden_test/golden_framework/golden_diff_record.dart';

/// Guards the golden diff recorder (#1475): the instrument that keeps the
/// `diffPercent` alchemist computes and throws away.
///
/// ## What has to be true for this to be worth having
///
/// Two properties, and the second is the one that makes it safe to install in the
/// golden runner:
///
/// 1. **It records the cells that pass.** A cell that moved 1.4 % under a 2.5 %
///    threshold is the exact case #1475 needs to see and the exact case alchemist
///    reports as silence, so `records the within-threshold pass` is the ticket.
/// 2. **It changes no verdict.** Every case below is run through the recorder
///    *and* through a plain [AlchemistFileComparator] with the same stubs, and the
///    two must return the same `bool` and write failure output the same number of
///    times. Asserted as parity rather than against hardcoded expectations,
///    because the property is "identical to the parent" — a copy of the parent's
///    logic restated as literals here would drift with it and still pass.
///
/// Lives under `test/test_scripts/` rather than beside the code it tests, for the
/// reason `overflow_record_test.dart` next door gives: everything under
/// `test/golden_test/` is excluded from `run_tests.sh`, and a guard CI never runs
/// is not a guard. It needs no baseline PNGs, no fonts and no `AlchemistConfig` —
/// the pixel walk is stubbed, which is what makes the parity comparison possible
/// at all.
///
/// ## Mutation ledger
///
/// Measured, not assumed — each mutation was applied to `golden_diff_record.dart`
/// and the failing test names recorded.
///
/// - **Recording only the cells that fail** (`if (!passed) GoldenDiffLog.add(…)`,
///   the shape that looks sufficient and reproduces alchemist's blindness) fails 3:
///   `records nothing but a denominator`, whose whole subject is the denominator,
///   `records the within-threshold pass`, and `counts each canvas separately`.
///   `records the failure too` stays green under it, which is why that test alone
///   would not have caught the mutation the instrument exists to prevent.
/// - **Keying the denominator by width alone** (`GoldenCanvas(record.width, 800)`,
///   the shape this started as) fails 2: `counts each canvas separately, not each
///   width` and `writes a threshold, a denominator per canvas`. Two canvases at one
///   width differ up to 30x in area and `diffPercent` is normalised by area, so a
///   width-keyed denominator pools two different units.
/// - **`passed = true`** fails 5: `records the failure too`, and 4 of the parity
///   cases — the two inside-threshold ones still agree, because a comparator that
///   passes everything agrees with one that passes those.
/// - **Not clearing [GoldenDiffLog] after a write** fails 2: `a second write
///   appends`, the multi-group-per-file case the overflow report gets wrong in the
///   same place, and `an unwritable directory`, which is where a failed write must
///   still not leave its records behind.
/// - **Not counting a cell whose baseline is missing** (dropping the `try` around
///   `getGoldenBytes`, the shape this shipped as until a real run showed one suite
///   reporting 6 cells at `480x800` against 7 at `1280x800` with nothing to say why)
///   fails 1: `a cell with no baseline is counted, not silently dropped`. So does
///   **swallowing that failure into a pass** (`return true` in place of the
///   `rethrow`) — the same test, because a missing baseline must still fail the cell.
/// - **Letting the write throw** (`rethrow` in place of the `stderr` report) fails
///   exactly `an unwritable directory costs the measurement, not the run` — the
///   property that keeps this diagnostic from becoming a second gate.
/// - **Recording `result.diffPercent` without the `result.passed ? 0.0 :` guard**
///   changes nothing — `compareLists` already sets 0.0 on the passing path — so
///   that guard is defensive and is not claimed as covered.
void main() {
  /// A [ComparisonResult] that reports whether it was disposed.
  ///
  /// [AlchemistFileComparator] never disposes; [LocalFileComparator] always does,
  /// and the diff images are real `dart:ui` images. The recorder follows the SDK,
  /// so the parity above is deliberately *not* total — this is the one place the
  /// two differ, and it is asserted so nobody restores the leak while "matching
  /// the parent".
  ComparisonResult trackedResult({
    required bool passed,
    required double diffPercent,
  }) =>
      _TrackedResult(passed: passed, diffPercent: diffPercent);

  final testUri = Uri.file('${Directory.systemTemp.path}/goldens/_test.dart');

  setUp(GoldenDiffLog.clear);

  group('the recorder keeps what alchemist drops', () {
    test('records nothing but a denominator for an identical render', () async {
      final comparator = _RecordingStub(testUri, 0.025, width: 1280)
        ..stubResult = trackedResult(passed: true, diffPercent: 0.0);

      expect(
          await comparator.compare(Uint8List(0), Uri.parse('a.png')), isTrue);

      expect(GoldenDiffLog.records, isEmpty,
          reason: 'an unmoved cell is not evidence of anything, and there are '
              'thousands of them');
      expect(GoldenDiffLog.comparedByCanvas, {const GoldenCanvas(1280, 800): 1},
          reason: 'it is still counted — "3 cells moved" means nothing without '
              'the number of cells');
    });

    test('counts each canvas separately, not each width', () async {
      // Suites pin their own height, so one width covers several canvases —
      // `480x140` and `480x4200` are both in the baselines.
      // `diffPercent` is a fraction of the area, so a denominator keyed by width
      // would pool figures that do not share a unit.
      for (final height in [140, 4200, 140]) {
        await (_RecordingStub(testUri, 0.025, width: 480, height: height)
              ..stubResult = trackedResult(passed: true, diffPercent: 0.0))
            .compare(Uint8List(0), Uri.parse('a.png'));
      }

      expect(GoldenDiffLog.comparedByCanvas, {
        const GoldenCanvas(480, 140): 2,
        const GoldenCanvas(480, 4200): 1,
      });
      // Whatever this map is asserted about, the failure message prints its
      // keys, so the key has to name itself. `Instance of 'GoldenCanvas'` twice
      // over is the difference between a diagnosable failure and a rerun.
      expect(GoldenDiffLog.comparedByCanvas.keys.map((c) => '$c'),
          ['480x140', '480x4200']);
    });

    test('records the within-threshold pass — the point of the ticket',
        () async {
      // 1.376 % is #1472's measured footprint at `screen1080`: a real semantic
      // regression that passed. Before this class the number did not survive the
      // comparison that computed it.
      final comparator = _RecordingStub(testUri, 0.025, width: 1080)
        ..stubResult = trackedResult(passed: false, diffPercent: 0.01376);

      expect(await comparator.compare(Uint8List(0), Uri.parse('a.png')), isTrue,
          reason: 'still a pass — the recorder must not turn observation into '
              'enforcement');

      expect(GoldenDiffLog.records, hasLength(1));
      final record = GoldenDiffLog.records.single;
      expect(record.diffPercent, 0.01376);
      expect(record.passed, isTrue);
      expect(record.width, 1080);
      expect(record.golden, 'view-state-screen1080-en');
      expect(comparator.failureOutputs, isEmpty,
          reason: 'a passing cell writes no failure images');
    });

    test('records the failure too, with passed false', () async {
      final comparator = _RecordingStub(testUri, 0.025, width: 480)
        ..stubResult = trackedResult(passed: false, diffPercent: 0.04209);

      expect(
          await comparator.compare(Uint8List(0), Uri.parse('a.png')), isFalse);

      expect(GoldenDiffLog.records.single.diffPercent, 0.04209);
      expect(GoldenDiffLog.records.single.passed, isFalse);
      expect(comparator.failureOutputs, hasLength(1));
    });

    test('one compare is one pixel walk', () async {
      // The reason this subclasses rather than wraps. A wrapper would decode both
      // PNGs twice per cell across ~10,000 cells.
      final comparator = _RecordingStub(testUri, 0.025, width: 1280)
        ..stubResult = trackedResult(passed: false, diffPercent: 0.01);

      await comparator.compare(Uint8List(0), Uri.parse('a.png'));

      expect(comparator.compareImageBytesCalls, 1);
    });

    test('disposes the result on both paths, which the parent does not',
        () async {
      final passing = trackedResult(passed: true, diffPercent: 0.0);
      await (_RecordingStub(testUri, 0.025, width: 1280)..stubResult = passing)
          .compare(Uint8List(0), Uri.parse('a.png'));
      expect((passing as _TrackedResult).disposed, isTrue);

      final failing = trackedResult(passed: false, diffPercent: 0.9);
      await (_RecordingStub(testUri, 0.025, width: 1280)..stubResult = failing)
          .compare(Uint8List(0), Uri.parse('a.png'));
      expect((failing as _TrackedResult).disposed, isTrue,
          reason: 'the failing path holds the diff images, so this is the one '
              'that matters');
    });
  });

  group('verdict parity with AlchemistFileComparator', () {
    /// Every verdict-relevant case, as (name, passed, diffPercent).
    ///
    /// `passed: false` with `diffPercent: 1.0` is `compareLists`' size-mismatch
    /// result, which is how a golden taken at another width arrives here.
    const cases = <(String, bool, double)>[
      ('identical', true, 0.0),
      ('just inside the threshold', false, 0.025),
      ('just outside the threshold', false, 0.0251),
      ('far outside', false, 0.4),
      ('size mismatch', false, 1.0),
    ];

    for (final (name, passed, diffPercent) in cases) {
      test('$name: same answer, same failure output', () async {
        final recording = _RecordingStub(testUri, 0.025, width: 1280)
          ..stubResult =
              trackedResult(passed: passed, diffPercent: diffPercent);
        final parent = _ParentStub(testUri, 0.025)
          ..stubResult =
              trackedResult(passed: passed, diffPercent: diffPercent);

        final recordingVerdict =
            await recording.compare(Uint8List(0), Uri.parse('a.png'));
        final parentVerdict =
            await parent.compare(Uint8List(0), Uri.parse('a.png'));

        expect(recordingVerdict, parentVerdict,
            reason: 'a diagnostic that changes which runs go red is not a '
                'diagnostic');
        expect(recording.failureOutputs, parent.failureOutputs);
      });
    }

    test('a zero threshold fails a cell that any threshold would pass',
        () async {
      // The parent's `diffThreshold > 0` guard, held from the outside: with the
      // threshold at 0 there is no allowance, so the same 0.1 % that passes above
      // fails. This is also the configuration in which alchemist installs no
      // comparator at all — see the `unmeasured` test below.
      final recording = _RecordingStub(testUri, 0.0, width: 1280)
        ..stubResult = trackedResult(passed: false, diffPercent: 0.001);
      final parent = _ParentStub(testUri, 0.0)
        ..stubResult = trackedResult(passed: false, diffPercent: 0.001);

      expect(await recording.compare(Uint8List(0), Uri.parse('a.png')),
          await parent.compare(Uint8List(0), Uri.parse('a.png')));
      expect(GoldenDiffLog.records.single.passed, isFalse);
    });
  });

  group('installGoldenDiffRecorder', () {
    late GoldenFileComparator original;

    setUp(() => original = goldenFileComparator);
    tearDown(() => goldenFileComparator = original);

    test('wraps alchemist\'s comparator, keeping its basedir and threshold',
        () {
      final alchemist = AlchemistFileComparator(testUri, 0.025);
      goldenFileComparator = alchemist;

      installGoldenDiffRecorder(golden: 'g', width: 1080, height: 800);

      final installed = goldenFileComparator;
      expect(installed, isA<GoldenDiffRecordingComparator>());
      installed as GoldenDiffRecordingComparator;
      expect(installed.diffThreshold, 0.025,
          reason: 'the recorder judges by the run\'s own threshold, not one of '
              'its own');
      expect(installed.basedir, alchemist.basedir,
          reason: 'a different basedir would look for the baselines in the '
              'wrong place');
      expect(installed.golden, 'g');
      expect(installed.width, 1080);
      expect(GoldenDiffLog.threshold, 0.025,
          reason: 'the report has to say which threshold the numbers were '
              'judged against');
      expect(GoldenDiffLog.unmeasured, 0);
    });

    test('counts an unmeasurable cell instead of failing or lying', () {
      // `goldenTestRunner.run` only installs an `AlchemistFileComparator` while
      // `diffThreshold > 0`. Setting the threshold to 0 would therefore switch
      // this instrument off — and an instrument that reports "no cells moved"
      // when it measured nothing is the failure mode #1475 is about.
      final plain = LocalFileComparator(testUri);
      goldenFileComparator = plain;

      installGoldenDiffRecorder(golden: 'g', width: 480, height: 800);

      expect(goldenFileComparator, same(plain),
          reason: 'nothing to record through, so nothing is swapped — the run '
              'must behave exactly as it did before');
      expect(GoldenDiffLog.unmeasured, 1);
      expect(GoldenDiffLog.threshold, isNull);
    });

    test('a cell with no baseline is counted, not silently dropped', () async {
      // Measured on a real run before this was handled: the node-detail suite
      // reported 6 cells at 480x800 and 7 at 1280x800 because one state had been
      // renamed, and nothing in the report said why. Every such cell is one
      // missing from a denominator the summary divides by.
      final recording = _RecordingStub(testUri, 0.025, width: 480)
        ..missingBaseline = true;

      await expectLater(
        recording.compare(Uint8List(0), Uri.parse('a.png')),
        throwsA(isA<TestFailure>()),
        reason:
            'the verdict stays the parent\'s — a missing baseline must still '
            'fail the cell, and the parent throws here too',
      );
      expect(GoldenDiffLog.uncomparable, 1);
      expect(GoldenDiffLog.comparedByCanvas, isEmpty,
          reason: 'nothing was compared, so nothing may enter the denominator');
      expect(GoldenDiffLog.records, isEmpty);

      // Parity: the parent fails the same way, so this catch changes only what is
      // counted.
      await expectLater(
        (_ParentStub(testUri, 0.025)..missingBaseline = true)
            .compare(Uint8List(0), Uri.parse('a.png')),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('writeGoldenDiffReport', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('golden_diff'));
    tearDown(() => dir.deleteSync(recursive: true));

    File reportFile() => File('${dir.path}/$goldenDiffReportName');

    /// The report as decoded lines, which is the only shape it has: one JSON
    /// object per line, appended by whichever suite got there first.
    List<Map<String, dynamic>> readLines() => [
          for (final line in reportFile().readAsLinesSync())
            jsonDecode(line) as Map<String, dynamic>,
        ];

    void record({
      required int width,
      required double diffPercent,
      int height = 800,
      String golden = 'g',
    }) =>
        GoldenDiffLog.add(GoldenDiffRecord(
          golden: golden,
          width: width,
          height: height,
          diffPercent: diffPercent,
          passed: true,
        ));

    test('writes nothing when nothing was compared', () {
      writeGoldenDiffReport(directory: dir.path);

      expect(reportFile().existsSync(), isFalse,
          reason: 'a generation run calls `update`, never `compare` — an empty '
              'report there would read as "measured, all quiet"');
    });

    test('writes a threshold, a denominator per canvas, and the movers', () {
      GoldenDiffLog.threshold = 0.025;
      record(width: 480, height: 1000, diffPercent: 0.0, golden: 'quiet');
      record(width: 480, height: 4200, diffPercent: 0.0, golden: 'quiet-tall');
      record(width: 1080, height: 1000, diffPercent: 0.0, golden: 'quiet');
      record(width: 1080, height: 1000, diffPercent: 0.01376, golden: 'moved');

      writeGoldenDiffReport(directory: dir.path);

      expect(readLines(), [
        {'type': 'threshold', 'value': 0.025},
        {'type': 'cells', 'width': 480, 'height': 1000, 'count': 1},
        {'type': 'cells', 'width': 480, 'height': 4200, 'count': 1},
        {'type': 'cells', 'width': 1080, 'height': 1000, 'count': 2},
        {
          'type': 'diff',
          'golden': 'moved',
          'width': 1080,
          'height': 1000,
          'diffPercent': 0.01376,
          'passed': true,
        },
      ]);
    });

    test('a second write appends rather than rewriting the file', () {
      // Every one of the 31 golden suites writes, `flutter test` runs them
      // concurrently, and one file can hold several `runViewGoldenTests` groups.
      // Nothing here may read the file back: a read-modify-write would let one
      // suite drop another's denominator, which is the deliverable.
      GoldenDiffLog.threshold = 0.025;
      record(width: 480, diffPercent: 0.03, golden: 'first');
      writeGoldenDiffReport(directory: dir.path);

      expect(GoldenDiffLog.records, isEmpty,
          reason: 'the log is cleared by the write, or the second group in a '
              'file reports the first group\'s cells again');

      record(width: 480, diffPercent: 0.04, golden: 'second');
      record(width: 1280, diffPercent: 0.0, golden: 'quiet');
      writeGoldenDiffReport(directory: dir.path);

      final lines = readLines();
      expect(
          lines.where((l) => l['type'] == 'cells'),
          [
            {'type': 'cells', 'width': 480, 'height': 800, 'count': 1},
            {'type': 'cells', 'width': 480, 'height': 800, 'count': 1},
            {'type': 'cells', 'width': 1280, 'height': 800, 'count': 1},
          ],
          reason: 'both writes\' denominators are present, to be summed by the '
              'reader');
      expect(
        lines.where((l) => l['type'] == 'diff').map((l) => l['golden']),
        ['first', 'second'],
      );
    });

    test('unmeasured cells reach the report on their own line', () {
      GoldenDiffLog.unmeasured = 3;

      writeGoldenDiffReport(directory: dir.path);

      expect(
          readLines(),
          [
            {'type': 'unmeasured', 'count': 3},
          ],
          reason:
              'no comparator was seen, so there is no threshold to claim and '
              'no cell to count');
    });

    test('baseline-less cells reach the report as their own cause', () {
      // Reported separately from `unmeasured` because the remedy differs: this
      // one is fixed by refreshing baselines, that one by a threshold above zero.
      GoldenDiffLog.uncomparable = 2;

      writeGoldenDiffReport(directory: dir.path);

      expect(readLines(), [
        {'type': 'uncomparable', 'count': 2},
      ]);
    });

    test('a garbage line already in the file is left for the reader', () {
      // Nothing here parses the file, so a torn append cannot take a golden run
      // down and cannot cost more than the one line it damaged —
      // `golden_diff_summary.dart` counts it and says the report is incomplete.
      reportFile().writeAsStringSync('{not json\n');
      record(width: 480, diffPercent: 0.03);

      writeGoldenDiffReport(directory: dir.path);

      final raw = reportFile().readAsLinesSync();
      expect(raw.first, '{not json');
      expect(raw, hasLength(3));
      expect(jsonDecode(raw[1])['type'], 'cells');
    });

    test('an unwritable directory costs the measurement, not the run', () {
      // An exception out of the runner's `tearDownAll` is a suite failure, which
      // would make this diagnostic a second gate on the golden run.
      record(width: 480, diffPercent: 0.03);
      // A plain file where the report directory should be: `createSync` cannot
      // make a directory over it, which is the same shape as a read-only volume
      // or a `goldens/` removed by a parallel `clear_goldens.sh`.
      File('${dir.path}/blocker').writeAsStringSync('');

      expect(
        () => writeGoldenDiffReport(directory: '${dir.path}/blocker'),
        returnsNormally,
      );
      expect(GoldenDiffLog.records, isEmpty,
          reason: 'and the log is still cleared, or the next suite in this '
              'isolate reports these cells as its own');
    });
  });
}

/// A [ComparisonResult] that remembers being disposed.
class _TrackedResult extends ComparisonResult {
  _TrackedResult({required super.passed, required super.diffPercent});

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// Stubs out everything that needs real PNGs on disk, so the two comparators
/// under test can be driven through identical inputs.
///
/// `on AlchemistFileComparator` is what lets one set of stubs serve both the
/// recorder and its parent, which is the whole basis of the parity group.
mixin _StubbedImages on AlchemistFileComparator {
  /// The pixel walk's answer. Set per test; this default is never asserted on.
  ComparisonResult stubResult =
      ComparisonResult(passed: true, diffPercent: 0.0);

  int compareImageBytesCalls = 0;

  /// The goldens `generateFailureOutput` was called for, in order.
  final List<Uri> failureOutputs = [];

  /// When set, the baseline read fails the way `LocalFileComparator` fails it for
  /// a golden that does not exist yet.
  bool missingBaseline = false;

  @override
  Future<List<int>> getGoldenBytes(Uri golden) async {
    if (missingBaseline) {
      throw TestFailure('Could not be compared against non-existent file: '
          '"$golden"');
    }
    return const <int>[0];
  }

  @override
  Future<ComparisonResult> compareImageBytes(
    Uint8List imageBytes,
    Uint8List goldenBytes,
  ) async {
    compareImageBytesCalls++;
    return stubResult;
  }

  @override
  Future<String> generateFailureOutput(
    ComparisonResult result,
    Uri golden,
    Uri basedir, {
    String key = '',
  }) async {
    failureOutputs.add(golden);
    return 'stubbed failure output';
  }
}

class _RecordingStub extends GoldenDiffRecordingComparator with _StubbedImages {
  _RecordingStub(
    super.testUri,
    super.diffThreshold, {
    required int width,
    int height = 800,
  }) : super(
          golden: 'view-state-screen$width-en',
          width: width,
          height: height,
        );
}

class _ParentStub extends AlchemistFileComparator with _StubbedImages {
  _ParentStub(super.testUri, super.diffThreshold);
}
