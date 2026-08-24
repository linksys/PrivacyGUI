import 'dart:convert';
import 'dart:io';

/// Turns a sweep run into a byte-stable dataset, and compares two of them
/// (#1337).
///
/// ## Why this exists
///
/// Epic #1335 ports four overflow sweeps onto one framework, and every port is
/// signed off by the same claim: *the failure set is identical, cell by cell*.
/// The main card sweep measures 1,917 coordinates, so nobody can check that by reading
/// output — and #1321 already showed what an unwatched signal change costs, where
/// an expired fixture turned a red gate green and nothing said so.
///
/// So each sweep prints one `#LAYOUT-CELL#` record per measured coordinate (see
/// `test/util/overflow_baseline.dart`), `flutter test --reporter json` carries
/// those out as `print` events, and this script flattens them into sorted TSV. Two
/// runs of unchanged code produce identical bytes, so the comparison is a plain
/// diff.
///
/// The stream must be captured by redirecting stdout, **not** with
/// `--file-reporter json:<file>` — see the NUL check in [extractBaseline], which
/// refuses a holed stream and explains why one happens.
///
/// ## The dataset
///
/// One row per measurement, six tab-separated columns:
///
///     cell                                  verdict   px     side   site           widget
///     card.width|card=lan_info|width=min    clean     -      -      -              -
///     card.width|card=lan_info|width=max    overflow  41.0   right  lib/a.dart:120 Row
///     card.width|card=wifi|width=min        noise     1.5    bottom -              -
///     card.width|card=wifi|width=max        error     -      -      -              -
///
/// * A **clean cell is a row**, not an absence — that is the whole of AC 5. A
///   coordinate the port stopped measuring is therefore a *missing* row, which
///   reads as lost coverage rather than as a fixed layout.
/// * **A cell that never finished is `error`, not `clean`.** A pump that threw
///   collected no incidents, so the same confusion returns one level in — present
///   in the dataset, so not lost coverage, and empty, so indistinguishable from a
///   layout that fits. See [verdictError].
/// * **`noise` rows are kept.** The sweeps drop sub-tolerance incidents before
///   asserting, so this is the only place they are visible; without them a port
///   that loosened the filter would look like a port that fixed a card.
/// * **Nothing volatile is recorded** — no timestamps, no run ids, no durations,
///   no test names, no failure prose. Test names in particular are excluded
///   because #1335 has already frozen a regrouping that changes them by design.
///
/// ## Commands
///
///     dart run test_scripts/overflow_baseline.dart extract \
///         --reporter build/overflow_baseline/card.json --sweep card --out <file>
///     dart run test_scripts/overflow_baseline.dart diff \
///         --baseline test/fixtures/overflow_baselines/card.tsv --reporter <json>
///
/// `tool/overflow_baseline.sh` wraps both with the five-sweep registry; prefer it.

/// Marks a baseline record on a sweep's stdout.
///
/// Restated rather than imported: the emitter side runs under `flutter_test` and
/// this script runs under bare `dart run`, which cannot resolve the Flutter SDK.
/// `test/test_scripts/overflow_baseline_test.dart` asserts the two constants are
/// equal, so a drift fails there instead of as an empty dataset that would read
/// as "no overflows anywhere".
const String overflowBaselineMarker = '#LAYOUT-CELL#';

/// Format of the committed baseline files.
///
/// Bumped when the columns change meaning. [BaselineFile.parse] refuses anything
/// else, because a file read by the wrong parser diffs on layout rather than on
/// layout — and every baseline has to be re-captured deliberately when the shape
/// of a measurement changes.
const String overflowBaselineVersion = '1';

/// Verdict of a row that was measured and found clean.
const String verdictClean = 'clean';

/// Verdict of an incident under the sweeps' tolerance — recorded, not asserted on.
const String verdictNoise = 'noise';

/// Verdict of an incident the gate fails on.
const String verdictOverflow = 'overflow';

/// Verdict of a cell whose pump did not finish, so nothing was measured there.
///
/// The other three say what a coordinate looked like. This one says the run never
/// got to look, which without a name of its own would arrive as [verdictClean]: a
/// tree that failed to build reports no overflow. That is the same lie as a missing
/// row, one level in — the cell is present, so the diff would not call it lost.
const String verdictError = 'error';

const String _absent = '-';
const int _columns = 6;

/// A sweep run, flattened and sorted.
class ExtractedBaseline {
  ExtractedBaseline({
    required this.sweep,
    required this.rows,
    required this.groups,
    required this.suites,
    required this.cells,
    required this.incidents,
    required this.overflows,
    required this.errors,
  });

  /// Baseline id this was extracted for, e.g. `card`.
  final String sweep;

  /// Every measurement as a TSV row, sorted.
  final List<String> rows;

  /// Record sweeps seen, e.g. `card.width`, `card.profile`. Sorted.
  final List<String> groups;

  /// Test files the run executed, sorted — recorded in the header so a reader
  /// knows what produced the file.
  final List<String> suites;

  /// Distinct coordinates measured.
  final int cells;

  /// Incidents recorded, including sub-tolerance ones.
  final int incidents;

  /// Incidents above tolerance, i.e. the failures the sweep reports.
  final int overflows;

  /// Cells whose pump did not finish, so they measured nothing. Should be 0 —
  /// surfaced in the summary because a capture is worth rejecting over.
  final int errors;

  /// One line a human can compare at a glance.
  String get summary => '$cells cells, $incidents incidents, '
      '$overflows overflows, $errors unmeasured';
}

/// Reads every baseline record of [sweep] out of a `--reporter json` stream.
///
/// Throws [FormatException] on anything that would make the dataset untrustworthy
/// rather than returning a smaller one. That strictness is the point: a truncated
/// or mis-targeted baseline does not fail loudly later — it silently passes every
/// diff run against it, which is exactly the failure #1337 exists to prevent.
ExtractedBaseline extractBaseline(
  String reporterOutput, {
  required String sweep,
}) {
  final testNames = <int, String>{};
  final suites = <String>{};
  final records = <String, _Record>{};
  final foreign = <String>{};
  final groups = <String>{};
  final loadFailures = <String>[];
  var finished = false;

  // A NUL means the stream was written at two positions at once and the gap was
  // filled with zeroes — `flutter test --file-reporter json:<file>` does exactly
  // that at 16KB boundaries, and it cost this ticket 22 cells before anyone
  // noticed: the events inside the hole simply were not there, and the dataset
  // read as a smaller, perfectly clean run. Hence `--reporter json` piped to a
  // file (one writer), and hence this check, because a silently short dataset is
  // the one failure mode a baseline must never have.
  if (reporterOutput.contains('\u0000')) {
    throw FormatException(
        'the reporter output has a NUL byte, so events were lost to interleaved '
        'writes. Capture with `--reporter json > file`, not '
        '`--file-reporter json:file`.');
  }

  for (final line in const LineSplitter().convert(reporterOutput)) {
    final trimmed = line.trim();
    // The runner writes one JSON object per line; the flutter tool's own banners
    // ("The following plugins do not support…") share the stream and are not ours
    // to interpret.
    if (!trimmed.startsWith('{')) continue;
    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      // Not skipped. A line that starts like an event and does not parse means
      // the stream was cut or interleaved, and everything after the cut is
      // missing — which reads as cells that laid out cleanly.
      throw FormatException(
          'unreadable reporter event (${e.message}), so the run is truncated: '
          '${trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed}');
    }
    if (decoded is! Map<String, Object?>) continue;

    switch (decoded['type']) {
      case 'suite':
        final path = (decoded['suite'] as Map?)?['path'];
        if (path is String) suites.add(_relativeToCwd(path));
      case 'testStart':
        final test = decoded['test'];
        if (test is Map && test['id'] is int && test['name'] is String) {
          testNames[test['id'] as int] = test['name'] as String;
        }
      case 'error':
        // A suite that failed to compile contributes no cells at all, and the
        // runner reports that as an error against its synthetic "loading …"
        // test. A plain test failure is the opposite: the cell it belongs to was
        // measured and emitted, so the record stands and the verdict in it is
        // the dataset's business, not this switch's.
        final name = testNames[decoded['testID']] ?? '';
        if (name.startsWith('loading ') || name.startsWith('compiling ')) {
          loadFailures.add(name);
        }
      case 'print':
        final message = decoded['message'];
        if (message is! String) continue;
        for (final printed in const LineSplitter().convert(message)) {
          final record = printed.trim();
          if (!record.startsWith(overflowBaselineMarker)) continue;
          final payload = _decodeRecord(
              record.substring(overflowBaselineMarker.length).trim());
          final cell = payload.cell;
          final group = cell.split('|').first;
          if (_baselineIdOf(group) != sweep) {
            foreign.add(group);
            continue;
          }
          if (records.containsKey(cell)) {
            throw FormatException(
                'the run measured "$cell" twice: a cell id has to identify one '
                'coordinate, or the dataset silently loses whichever record '
                'lost the race');
          }
          groups.add(group);
          records[cell] = payload;
        }
      case 'done':
        finished = true;
    }
  }

  if (foreign.isNotEmpty) {
    final named = (foreign.toList()..sort()).take(3).join(', ');
    throw FormatException(
        'the run emitted records of ${foreign.length} other sweep(s) ($named) '
        'while extracting "$sweep" — a baseline built from one suite\'s share of '
        'another sweep would pass every later diff. Check --sweep against the '
        'suite that was run.');
  }
  if (loadFailures.isNotEmpty) {
    throw FormatException(
        '${loadFailures.length} suite(s) failed to load, so their cells are '
        'missing from this run: ${loadFailures.join(', ')}');
  }
  if (!finished) {
    throw FormatException(
        'the run did not finish (no "done" event), so the dataset is cut off '
        'somewhere and the cells past the cut would read as clean');
  }
  if (records.isEmpty) {
    throw FormatException(
        'the run emitted no baseline records for "$sweep" — capture is opt-in, so '
        'check OVERFLOW_BASELINE=1 reached the test process. An empty baseline '
        'would pass every diff taken against it.');
  }

  final rows = <String>[];
  var incidents = 0;
  var overflows = 0;
  var errors = 0;
  for (final entry in records.entries) {
    final record = entry.value;
    // A cell that died gets a row of its own, in addition to whatever it managed
    // to collect first. It cannot simply be a verdict on the incident rows: the
    // usual case is a tree that failed to build, which has none — and a cell with
    // no rows at all is one the diff would report as never measured, sending the
    // reader after a coverage change instead of a broken pump.
    if (record.threw) {
      errors++;
      rows.add(_row(entry.key, verdict: verdictError));
    }
    if (record.incidents.isEmpty) {
      if (!record.threw) rows.add(_row(entry.key, verdict: verdictClean));
      continue;
    }
    for (final incident in record.incidents) {
      if (incident is! Map<String, Object?>) {
        throw FormatException(
            'cell "${entry.key}" recorded an incident that is not an object: '
            '$incident');
      }
      final significant = incident['significant'];
      if (significant is! bool) {
        throw FormatException(
            'cell "${entry.key}" recorded an incident with no "significant" '
            'verdict. The verdict is computed beside kOverflowTolerancePx on the '
            'emitter side; without it every incident here would be mislabelled.');
      }
      incidents++;
      if (significant) overflows++;
      final file = _field(incident['file']);
      final lineNo = _field(incident['line']);
      rows.add(_row(
        entry.key,
        verdict: significant ? verdictOverflow : verdictNoise,
        px: _field(incident['px']),
        side: _field(incident['side']),
        site: file == _absent
            ? _absent
            : (lineNo == _absent ? file : '$file:$lineNo'),
        widget: _field(incident['widget']),
      ));
    }
  }
  // Sorted by the whole line, so the dataset does not inherit the run's test
  // order — which `flutter test` never promised and which the port changes on
  // purpose.
  rows.sort();

  return ExtractedBaseline(
    sweep: sweep,
    rows: rows,
    groups: groups.toList()..sort(),
    suites: suites.toList()..sort(),
    cells: records.length,
    incidents: incidents,
    overflows: overflows,
    errors: errors,
  );
}

/// One cell as the emitter reported it.
class _Record {
  const _Record(this.cell, this.incidents, {required this.threw});

  final String cell;
  final List<Object?> incidents;

  /// The pump did not finish, so this coordinate measured nothing.
  final bool threw;
}

/// Splits one record into its cell id, its incidents, and whether it finished.
_Record _decodeRecord(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (e) {
    throw FormatException(
        'unreadable baseline record: $payload (${e.message})');
  }
  if (decoded is! Map<String, Object?>) {
    throw FormatException('baseline record is not an object: $payload');
  }
  final cell = decoded['cell'];
  final incidents = decoded['incidents'];
  final threw = decoded['threw'];
  if (cell is! String || cell.isEmpty) {
    throw FormatException('baseline record names no cell: $payload');
  }
  if (incidents is! List) {
    throw FormatException('baseline record for "$cell" lists no incidents');
  }
  if (threw is! bool) {
    // Not defaulted to false. A pump that died collects no incidents, so a record
    // with no "threw" flag is indistinguishable from a coordinate that laid out
    // cleanly — and reading it as clean is the one mistake this dataset exists to
    // make impossible.
    throw FormatException(
        'baseline record for "$cell" has no "threw" flag, so a pump that never '
        'finished would be recorded as measured and clean');
  }
  return _Record(cell, incidents, threw: threw);
}

/// Drops the run directory from a path the reporter gave absolutely.
///
/// The `suite` events carry absolute paths, and the header they end up in gets
/// committed — an unnormalized one would write somebody's home directory into the
/// repo and change on every machine. The same normalization the golden framework
/// applies to overflow sites, for the same reason.
String _relativeToCwd(String path) {
  final root = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(root) ? path.substring(root.length) : path;
}

/// `card.width` → `card`: which committed file a record belongs in.
String _baselineIdOf(String group) {
  final dot = group.indexOf('.');
  return dot < 0 ? group : group.substring(0, dot);
}

/// Renders one column, keeping the row separators out of it.
///
/// The emitter sanitizes cell ids, but widget names and Flutter's own paths reach
/// here untouched. A tab inside one would split a row in two, and a diff cannot
/// tell that apart from a coverage change.
String _field(Object? value) {
  if (value == null) return _absent;
  final text = '$value'.replaceAll(RegExp(r'[\t\r\n]'), '_');
  return text.isEmpty ? _absent : text;
}

String _row(
  String cell, {
  required String verdict,
  String px = _absent,
  String side = _absent,
  String site = _absent,
  String widget = _absent,
}) =>
    [cell, verdict, px, side, site, widget].join('\t');

/// Renders the file that gets committed.
///
/// The header is comment lines only, and [diffBaselines] compares data lines
/// alone: [commit] and [suite] are there so a reader can tell what produced the
/// file, and they must never make two runs of the same code disagree.
String renderBaseline(
  ExtractedBaseline baseline, {
  required String suite,
  required String commit,
}) {
  final out = StringBuffer()
    ..writeln('# overflow-baseline $overflowBaselineVersion')
    ..writeln('# sweep ${baseline.sweep}')
    ..writeln('# groups ${baseline.groups.join(' ')}')
    ..writeln('# suite $suite')
    ..writeln('# commit $commit')
    ..writeln('# cells ${baseline.cells}')
    ..writeln('# incidents ${baseline.incidents}')
    ..writeln('# overflows ${baseline.overflows}')
    ..writeln('# unmeasured ${baseline.errors}')
    ..writeln('# columns cell\tverdict\tpx\tside\tsite\twidget');
  for (final row in baseline.rows) {
    out.writeln(row);
  }
  return out.toString();
}

/// A committed baseline, or a fresh capture rendered the same way.
class BaselineFile {
  BaselineFile._({
    required this.sweep,
    required this.commit,
    required this.cells,
    required this.source,
  });

  /// Baseline id from the header, or null if the file predates it.
  final String? sweep;

  /// Commit the file was captured at. Reported, never compared.
  final String? commit;

  /// Coordinate → its rows, in file order.
  final Map<String, List<String>> cells;

  /// Where this came from, for error messages.
  final String source;

  int get rowCount => cells.values.fold(0, (sum, rows) => sum + rows.length);

  /// Raised from the two places a missing version header can be noticed — the
  /// first data row, and the end of an all-header file. One builder so the two
  /// cannot drift into saying different things about the same file.
  static FormatException _notABaseline(String source) => FormatException(
      '$source has no "# overflow-baseline" header, so it is not a baseline this '
      'can read');

  static BaselineFile parse(String text, {String source = '<memory>'}) {
    final lines = const LineSplitter().convert(text);
    final headers = <String, String>{};
    final cells = <String, List<String>>{};
    var sawVersion = false;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('#')) {
        final parts = line.substring(1).trim().split(RegExp(r'\s+'));
        if (parts.first == 'overflow-baseline') {
          sawVersion = true;
          final version = parts.length > 1 ? parts[1] : '';
          if (version != overflowBaselineVersion) {
            throw FormatException(
                '$source is overflow-baseline format "$version"; this build '
                'reads format "$overflowBaselineVersion". Re-capture the '
                'baseline rather than diffing across formats.');
          }
          continue;
        }
        if (parts.length > 1) {
          headers[parts.first] =
              line.substring(1).trim().substring(parts.first.length).trim();
        }
        continue;
      }
      // Checked before the columns are, so an arbitrary TSV is reported as "not a
      // baseline" rather than as a baseline with the wrong column count.
      if (!sawVersion) throw _notABaseline(source);
      final fields = line.split('\t');
      if (fields.length != _columns) {
        throw FormatException(
            '$source has a row with ${fields.length} columns, expected '
            '$_columns: $line');
      }
      cells.putIfAbsent(fields.first, () => <String>[]).add(line);
    }

    // Reached by a file that is all header lines, or empty: the loop above never
    // saw a row to check.
    if (!sawVersion) throw _notABaseline(source);
    return BaselineFile._(
      sweep: headers['sweep'],
      commit: headers['commit'],
      cells: cells,
      source: source,
    );
  }

  /// Wraps a fresh capture as a comparable file.
  ///
  /// Goes through [renderBaseline] and [parse] deliberately: what gets compared
  /// is then the same bytes that would be committed, so a rendering bug cannot
  /// hide behind a diff that read the in-memory object instead.
  static BaselineFile fromExtracted(ExtractedBaseline extracted,
          {String source = '<fresh run>'}) =>
      parse(
        renderBaseline(extracted, suite: _absent, commit: _absent),
        source: source,
      );
}

/// One coordinate whose measurements differ.
class CellChange {
  const CellChange(this.cell, this.baselineRows, this.actualRows);

  final String cell;
  final List<String> baselineRows;
  final List<String> actualRows;
}

/// What changed between two datasets.
class BaselineDiff {
  BaselineDiff({
    required this.sweep,
    required this.comparedCells,
    required this.lostCells,
    required this.newCells,
    required this.changedCells,
  });

  final String sweep;

  /// Coordinates present in the committed baseline.
  final int comparedCells;

  /// Measured before, not measured now. The dangerous one: a port that drops a
  /// coordinate produces a run with fewer failures, which reads like progress.
  final List<String> lostCells;

  /// Measured now, absent from the baseline.
  final List<String> newCells;

  /// Measured both times, differently.
  final List<CellChange> changedCells;

  bool get isClean =>
      lostCells.isEmpty && newCells.isEmpty && changedCells.isEmpty;

  /// A report ordered by how easily each kind of difference could be mistaken
  /// for success — lost coverage first, then changed readings, then additions.
  String report() {
    final out = StringBuffer('overflow baseline diff: $sweep\n');
    if (isClean) {
      out.writeln('  $comparedCells cells compared, identical');
      return out.toString();
    }
    out.writeln('  $comparedCells cells compared');
    if (lostCells.isNotEmpty) {
      out.writeln('  ${_count(lostCells.length)} no longer measured '
          '(coverage lost — this would otherwise read as a pass):');
      for (final cell in lostCells) {
        out.writeln('    - $cell');
      }
    }
    if (changedCells.isNotEmpty) {
      out.writeln('  ${_count(changedCells.length)} changed:');
      for (final change in changedCells) {
        for (final row in change.baselineRows) {
          out.writeln('    - $row');
        }
        for (final row in change.actualRows) {
          out.writeln('    + $row');
        }
      }
      // Called out inside the changed block rather than moved up to the lost one:
      // the coordinate is still enumerated, so it is not lost coverage in the sense
      // above — but its pump died, so nothing was measured there either, and that
      // is easy to skim past in a list of before/after rows.
      final unmeasured =
          changedCells.where((c) => c.actualRows.any(_isUnmeasured)).length;
      if (unmeasured > 0) {
        out.writeln(
            '    ↑ ${_count(unmeasured)} now "$verdictError": the pump did '
            'not finish, so that coordinate was not measured this run either');
      }
    }
    if (newCells.isNotEmpty) {
      out.writeln('  ${_count(newCells.length)} new:');
      for (final cell in newCells) {
        out.writeln('    + $cell');
      }
    }
    return out.toString();
  }

  static String _count(int n) => n == 1 ? '1 cell' : '$n cells';

  static bool _isUnmeasured(String row) {
    final fields = row.split('\t');
    return fields.length > 1 && fields[1] == verdictError;
  }
}

/// Compares two datasets of the same sweep.
BaselineDiff diffBaselines({
  required BaselineFile baseline,
  required BaselineFile actual,
}) {
  if (baseline.sweep != actual.sweep) {
    throw FormatException(
        'refusing to compare sweep "${baseline.sweep ?? '(none)'}" '
        '(${baseline.source}) against "${actual.sweep ?? '(none)'}" '
        '(${actual.source}) — every cell would read as lost and every cell as '
        'new, which looks like a catastrophic port rather than the wrong file it '
        'is');
  }

  final lost = <String>[];
  final changed = <CellChange>[];
  for (final entry in baseline.cells.entries) {
    final fresh = actual.cells[entry.key];
    if (fresh == null) {
      lost.add(entry.key);
      continue;
    }
    if (!_sameRows(entry.value, fresh)) {
      changed.add(CellChange(entry.key, entry.value, fresh));
    }
  }
  final added = actual.cells.keys
      .where((cell) => !baseline.cells.containsKey(cell))
      .toList();

  return BaselineDiff(
    sweep: baseline.sweep ?? '(none)',
    comparedCells: baseline.cells.length,
    lostCells: lost..sort(),
    newCells: added..sort(),
    changedCells: changed,
  );
}

bool _sameRows(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

const String _usage = '''
usage:
  # capture with: flutter test <suite> --reporter json > run.json
  dart run test_scripts/overflow_baseline.dart extract \\
      --reporter <run.json> --sweep <id> [--out <file>] \\
      [--commit <sha>] [--suite <path>]

  dart run test_scripts/overflow_baseline.dart diff \\
      --baseline <file> (--actual <file> | --reporter <run.json>)

exit codes: 0 = clean, 1 = the datasets differ, 2 = bad input

Prefer tool/overflow_baseline.sh, which knows the five sweeps and their files.
''';

/// Entry point, separated from [main] so tests can assert on exit codes and
/// output without spawning a process.
Future<int> runOverflowBaseline(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;

  if (args.isEmpty) {
    stderrSink.write(_usage);
    return 2;
  }

  // Answered before [_parseOptions], which would reject `-h` as an unexpected
  // argument and then print this very text as an *error* — on stderr, with exit
  // 2 — to someone who asked for it. Recognised in any position, matching
  // `tool/overflow_baseline.sh`, which takes `-h`/`--help` both as the command
  // and after it.
  if (_isHelpRequest(args)) {
    stdoutSink.write(_usage);
    return 0;
  }

  try {
    final options = _parseOptions(args.skip(1).toList());
    switch (args.first) {
      case 'extract':
        return _extractCommand(options, stdoutSink);
      case 'diff':
        return _diffCommand(options, stdoutSink);
      default:
        stderrSink.writeln('unknown command "${args.first}"');
        stderrSink.write(_usage);
        return 2;
    }
  } on FormatException catch (e) {
    stderrSink.writeln(e.message);
    return 2;
  } on FileSystemException catch (e) {
    stderrSink.writeln('${e.message}: ${e.path}');
    return 2;
  }
}

int _extractCommand(Map<String, String> options, StringSink out) {
  final reporter = _readFile(_require(options, '--reporter'));
  final sweep = _require(options, '--sweep');
  final extracted = extractBaseline(reporter, sweep: sweep);
  final text = renderBaseline(
    extracted,
    suite: options['--suite'] ??
        (extracted.suites.isEmpty ? _absent : extracted.suites.join(' ')),
    commit: options['--commit'] ?? _headCommit(),
  );

  final target = options['--out'];
  if (target == null) {
    out.write(text);
  } else {
    File(target)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
    out.writeln('${extracted.summary} -> $target');
  }
  return 0;
}

int _diffCommand(Map<String, String> options, StringSink out) {
  final baselinePath = _require(options, '--baseline');
  final baseline =
      BaselineFile.parse(_readFile(baselinePath), source: baselinePath);

  final BaselineFile actual;
  final actualPath = options['--actual'];
  final reporterPath = options['--reporter'];
  if (actualPath != null) {
    actual = BaselineFile.parse(_readFile(actualPath), source: actualPath);
  } else if (reporterPath != null) {
    // The sweep's own reporter file is what a port run has to hand, so `check`
    // is one command rather than extract-then-compare.
    //
    // Which sweep to pull out of that run comes from the baseline's own header
    // and nowhere else. A `--sweep` override was offered here as a fallback and
    // could never work: it is consulted only when the baseline names no sweep,
    // and [diffBaselines] then refuses the comparison on exactly that mismatch.
    // A header-less baseline is a re-capture, so say so.
    final sweep = baseline.sweep;
    if (sweep == null) {
      throw FormatException(
          '$baselinePath carries no "# sweep" header, so nothing says which of '
          'the run\'s sweeps it is a measurement of. Re-capture it with '
          "tool/overflow_baseline.sh capture <sweep>.");
    }
    actual = BaselineFile.fromExtracted(
      extractBaseline(_readFile(reporterPath), sweep: sweep),
      source: reporterPath,
    );
  } else {
    throw FormatException('diff needs --actual or --reporter\n$_usage');
  }

  final diff = diffBaselines(baseline: baseline, actual: actual);
  out.write(diff.report());
  return diff.isClean ? 0 : 1;
}

/// Whether [args] is asking for the usage text rather than for work.
///
/// `help` only as the command, because it is a plausible option *value* (a sweep
/// or a file could be called that); `-h`/`--help` anywhere, because no option
/// takes either as a value.
bool _isHelpRequest(List<String> args) =>
    args.first == 'help' || args.any((a) => a == '-h' || a == '--help');

Map<String, String> _parseOptions(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) {
      throw FormatException('unexpected argument "$arg"\n$_usage');
    }
    final eq = arg.indexOf('=');
    if (eq > 0) {
      options[arg.substring(0, eq)] = arg.substring(eq + 1);
      continue;
    }
    if (i + 1 >= args.length) {
      throw FormatException('"$arg" needs a value\n$_usage');
    }
    options[arg] = args[++i];
  }
  return options;
}

String _require(Map<String, String> options, String name) {
  final value = options[name];
  if (value == null || value.isEmpty) {
    throw FormatException('$name is required\n$_usage');
  }
  return value;
}

String _readFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FormatException('cannot read $path: no such file');
  }
  return file.readAsStringSync();
}

/// The commit a capture was taken at, so a baseline says what it describes.
///
/// Suffixed `-dirty` when any of [kBaselineMeasuredPaths] carries uncommitted
/// work, because a
/// plain sha claims that checking it out and re-capturing reproduces these rows,
/// and a dirty tree cannot keep that promise. `tool/overflow_baseline.sh` computes
/// the same stamp and passes it as `--commit`; this is the fallback for a direct
/// `dart run … extract`, and it has to agree — a stamp that were honest only when
/// routed through the wrapper is the misleading half by default.
///
/// Best-effort: a capture from a tarball with no git metadata is still worth
/// having, it just cannot name its commit.
String _headCommit() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    if (result.exitCode == 0) {
      final sha = (result.stdout as String).trim();
      if (sha.isNotEmpty) return '$sha${_isDirty() ? '-dirty' : ''}';
    }
  } on ProcessException {
    // git is not on PATH.
  }
  return 'unknown';
}

/// The paths a baseline is a measurement of, for the `-dirty` stamp.
///
/// `lib` and `test` are the app and the sweeps. `pubspec.yaml` is here because
/// the widgets being measured are largely not in this repo: `ui_kit_library` and
/// `generative_ui` are git dependencies pinned by ref in that file, so bumping
/// the ref moves rows exactly as directly as editing `lib/` does, and a baseline
/// that called such a tree clean would promise a reproduction it cannot deliver.
///
/// Not `pubspec.lock`: it is gitignored in this repo, so `git status` cannot
/// report it whatever we pass, and listing it would only look like cover for a
/// resolved-version drift no stamp here can see.
///
/// Not `assets/fonts` either — but not because fonts are irrelevant here. They
/// decide every measurement in this dataset, which is why all five sweeps call
/// `loadAppFonts()`. It is that none of the fonts they load live in that
/// directory: the ui_kit faces are read out of the pub-cache checkout
/// `pubspec.yaml` pins, and the Noto fallbacks are committed under
/// `test/fonts/`. Both are already covered above. The input this stamp genuinely
/// cannot see is the Flutter SDK — its version is not in this tree, and it
/// supplies MaterialIcons and the layout engine underneath every row.
///
/// Mirrored in `tool/overflow_baseline.sh`, which computes the same stamp for
/// the wrapped path; `overflow_baseline_test.dart` holds the two to the same
/// list.
const List<String> kBaselineMeasuredPaths = ['lib', 'test', 'pubspec.yaml'];

/// Whether the trees a baseline is a measurement of carry uncommitted work.
///
/// Scoped to [kBaselineMeasuredPaths], so an edited README is not something a
/// baseline needs to disclaim.
bool _isDirty() {
  try {
    final result = Process.runSync(
        'git', ['status', '--porcelain', '--', ...kBaselineMeasuredPaths]);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim().isNotEmpty;
    }
  } on ProcessException {
    // git is not on PATH; the caller has already given up on naming a commit.
  }
  return false;
}

Future<void> main(List<String> args) async {
  exitCode = await runOverflowBaseline(args);
}
