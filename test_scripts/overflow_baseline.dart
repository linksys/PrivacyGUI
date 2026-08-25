import 'dart:convert';
import 'dart:io';

/// Turns a sweep run into a byte-stable dataset, compares two of them (#1337),
/// and renders one for a human to read (#1349).
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
///     dart run test_scripts/overflow_baseline.dart render \
///         --baseline test/fixtures/overflow_baselines/page.tsv --format html
///
/// `tool/overflow_baseline.sh` wraps all three with the five-sweep registry;
/// prefer it. Note what the third one does *not* do: `render` reads the committed
/// file and runs no tests, so it describes the commit in that file's header and
/// not the tree it is invoked from. See [BaselineReport].

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

/// Positions in a row of the six columns `cell verdict px side site widget`.
///
/// Only the two anything reads back are named. The row stays a `List<String>`
/// rather than becoming a type: `extract` builds one, `diff` compares whole
/// lines, and only `render` looks inside — so a row type would be a fifth
/// spelling of the same six fields for one caller's benefit.
const int _colVerdict = 1;
const int _colSite = 4;

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
    required this.headers,
    required this.cells,
    required this.source,
  });

  /// The `# key value` lines, unparsed. Kept whole because [BaselineReport]
  /// quotes the provenance ones back to a reader and cross-checks the counts.
  final Map<String, String> headers;

  /// Baseline id from the header, or null if the file predates it.
  String? get sweep => headers['sweep'];

  /// Commit the file was captured at. Reported, never compared.
  String? get commit => headers['commit'];

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
      headers: headers,
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
    return fields.length > _colVerdict && fields[_colVerdict] == verdictError;
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

/// A committed baseline tallied for reading, rather than for diffing (#1349).
///
/// ## Why the file and not the run
///
/// Every other artefact this gate produces is written by the suite that pumped
/// the cells — which is why the card sweep's HTML report is card-shaped: its rows
/// carry a column span, a grid recommendation and a screenshot path, none of
/// which a page, a dialog or a top bar has. Rendering the committed TSV instead
/// costs no test run and works for all five sweeps unchanged, because the dataset
/// is already the sweep-agnostic per-cell table.
///
/// The price is that there is no picture, and the risk is provenance: this is the
/// one artefact here that describes a tree nobody just ran. So a report leads with
/// the commit out of its own header, repeats a `-dirty` stamp as prose, and names
/// the command that refreshes it.
///
/// **Everything below is recounted from the rows.** The `# cells` / `# incidents`
/// / `# overflows` / `# unmeasured` headers were written by [renderBaseline] at
/// capture time, so quoting them would let a hand-edited file print a summary its
/// own rows contradict. They are compared instead, and any disagreement is
/// reported — in the document, on stderr, and in the exit code.
class BaselineReport {
  BaselineReport._({
    required this.file,
    required this.sweep,
    required this.cells,
    required this.rows,
    required this.clean,
    required this.noise,
    required this.overflows,
    required this.unmeasured,
    required this.unrecognised,
    required this.groups,
    required this.axes,
    required this.sites,
    required this.findings,
    required this.failedCells,
    required this.headerDisagreements,
    required this.shots,
    required this.shotWarnings,
  });

  /// The dataset this describes.
  final BaselineFile file;

  /// Baseline id, or `(unnamed)` for a file that predates the header.
  final String sweep;

  /// Coordinates the dataset holds. A clean cell is one of them.
  final int cells;

  /// Rows, which exceeds [cells] wherever a coordinate recorded more than one
  /// incident, or died after recording some.
  final int rows;

  final int clean;
  final int noise;
  final int overflows;

  /// Coordinates whose pump did not finish, so they measured nothing.
  final int unmeasured;

  /// Rows whose verdict this reader does not know — 0 for any file the extractor
  /// wrote. Counted rather than skipped so a foreign verdict cannot go missing
  /// from every table at once.
  final int unrecognised;

  /// Per sweep group, e.g. `page.dhcp`. Sorted by name.
  final List<ReportTally> groups;

  /// Per axis of the cell ids, e.g. `locale`. Sorted by name.
  final List<ReportAxis> axes;

  /// Per `file:line` an incident was reported at, most rows first. Empty when
  /// nothing overflowed.
  final List<ReportTally> sites;

  /// Every row that is not clean, as its six fields, sorted.
  final List<List<String>> findings;

  /// The coordinates this dataset calls failures: an overflow past the tolerance,
  /// or a pump that did not finish.
  ///
  /// Not every non-clean cell — a `noise` row is a sub-tolerance incident, which the
  /// sweep passed — so this is the same bar `measureOverflowCell` applies when
  /// `shoot … failed` decides what to photograph. Two programs, one definition of
  /// failure, or the gallery and the rows would disagree at the margin.
  final Set<String> failedCells;

  /// Ways the header's own counts contradict the rows. Empty is the normal case.
  final List<String> headerDisagreements;

  /// Cell id → image href, for the coordinates this dataset actually holds.
  /// Sorted by cell id, and empty whenever `render` was given no `--shots`.
  final Map<String, String> shots;

  /// Why the images and the rows do not fully reconcile: an unreadable manifest,
  /// or a photograph of a coordinate these rows do not carry. Reported rather than
  /// dropped for the same reason [headerDisagreements] is — the two halves come
  /// from two runs and nothing forces them to be the same run — but **not** part of
  /// the exit code, because a gallery is decoration and a stale `build/` folder is
  /// not a corrupt dataset.
  final List<String> shotWarnings;

  /// The same one-line shape [ExtractedBaseline.summary] prints.
  String get summary =>
      '$cells cells, ${noise + overflows} incidents, $overflows overflows, '
      '$unmeasured unmeasured';

  static BaselineReport of(
    BaselineFile file, {
    ScreenshotIndex shots = ScreenshotIndex.none,
  }) {
    final groups = <String, _Tally>{};
    final axes = <String, _Tally>{};
    final axisValues = <String, Map<String, _Tally>>{};
    final sites = <String, _Tally>{};
    final findings = <List<String>>[];
    final failedCells = <String>{};
    final total = _Tally();

    for (final entry in file.cells.entries) {
      final cell = entry.key;
      final group = cell.split('|').first;
      final cellAxes = _axesOf(cell);
      for (final row in entry.value) {
        final fields = row.split('\t');
        final verdict = fields[_colVerdict];
        total.add(cell, verdict);
        groups.putIfAbsent(group, _Tally.new).add(cell, verdict);
        for (final axis in cellAxes.entries) {
          axes.putIfAbsent(axis.key, _Tally.new).add(cell, verdict);
          axisValues
              .putIfAbsent(axis.key, () => <String, _Tally>{})
              .putIfAbsent(axis.value, _Tally.new)
              .add(cell, verdict);
        }
        if (verdict == verdictNoise || verdict == verdictOverflow) {
          sites.putIfAbsent(fields[_colSite], _Tally.new).add(cell, verdict);
        }
        if (verdict == verdictOverflow || verdict == verdictError) {
          failedCells.add(cell);
        }
        if (verdict != verdictClean) findings.add(fields);
      }
    }

    // Sorted by the whole row, matching the dataset's own ordering rule: the
    // report must not inherit an order from the file it read, or two reports of
    // the same measurements could differ.
    findings.sort((a, b) => a.join('\t').compareTo(b.join('\t')));

    // Linked only where the rows carry the coordinate. An image whose cell id is
    // absent here was taken against a different enumeration — a shoot from before
    // a re-capture, most often — and linking it would put a picture next to a
    // coordinate this document says nothing about.
    final linked = <String, String>{};
    final orphans = <String>[];
    for (final shot in shots.images.entries) {
      if (file.cells.containsKey(shot.key)) {
        linked[shot.key] = shot.value;
      } else {
        orphans.add(shot.key);
      }
    }

    final siteTallies =
        sites.entries.map((e) => e.value.freeze(_siteLabel(e.key))).toList()
          ..sort((a, b) {
            final byRows = b.incidents.compareTo(a.incidents);
            return byRows != 0 ? byRows : a.name.compareTo(b.name);
          });

    return BaselineReport._(
      file: file,
      sweep: file.sweep ?? '(unnamed)',
      cells: file.cells.length,
      rows: file.rowCount,
      clean: total.clean,
      noise: total.noise,
      overflows: total.overflow,
      unmeasured: total.unmeasured,
      unrecognised: total.unrecognised,
      groups: (groups.keys.toList()..sort())
          .map((name) => groups[name]!.freeze(name))
          .toList(),
      axes: (axes.keys.toList()..sort())
          .map((name) => ReportAxis(
                name,
                axes[name]!.cells.length,
                _sortedValues(axisValues[name]!.keys)
                    .map((value) => axisValues[name]![value]!.freeze(value))
                    .toList(),
              ))
          .toList(),
      sites: siteTallies,
      findings: findings,
      failedCells: failedCells,
      headerDisagreements: _headerDisagreements(file, total),
      shots: linked,
      shotWarnings: [
        ...shots.warnings,
        if (orphans.isNotEmpty) _orphanWarning(shots.source, orphans),
      ],
    );
  }

  /// Every orphan named, up to a stated limit.
  ///
  /// Listed rather than counted because the reader's next question is which — and
  /// the limit says how many it is not showing, since a truncation nobody is told
  /// about reads as the whole list.
  static String _orphanWarning(String source, List<String> orphans) {
    const shown = 10;
    final head = orphans.take(shown).join(', ');
    final rest = orphans.length - shown;
    return '$source: ${orphans.length} '
        '${orphans.length == 1 ? 'image names a coordinate' : 'images name coordinates'} '
        'this dataset does not hold, so they were not linked: $head'
        '${rest > 0 ? ' (+$rest more)' : ''}';
  }

  /// `page.dhcp|screen_px=320|locale=ar` → `{screen_px: 320, locale: ar}`.
  ///
  /// A segment without `=` is skipped rather than invented a name for; the axis
  /// totals are stated as "N of M coordinates" precisely so an axis that does not
  /// reach every cell — for whatever reason — reads as the gap it is.
  static Map<String, String> _axesOf(String cell) {
    final axes = <String, String>{};
    for (final segment in cell.split('|').skip(1)) {
      final eq = segment.indexOf('=');
      if (eq <= 0) continue;
      axes[segment.substring(0, eq)] = segment.substring(eq + 1);
    }
    return axes;
  }

  /// Numerically when every value is a number, so `1241` does not sort between
  /// `1` and `320` on an axis a reader reads as a range.
  static List<String> _sortedValues(Iterable<String> values) {
    final list = values.toList();
    if (list.every((v) => num.tryParse(v) != null)) {
      list.sort((a, b) => num.parse(a).compareTo(num.parse(b)));
    } else {
      list.sort();
    }
    return list;
  }

  static List<String> _headerDisagreements(BaselineFile file, _Tally total) {
    final out = <String>[];
    void check(String header, int measured, String unit) {
      final stated = file.headers[header];
      // Absent is not a disagreement: a file written before a header existed is
      // simply not cross-checkable on it, and the rows are what gets reported
      // either way.
      if (stated == null) return;
      if (int.tryParse(stated) == measured) return;
      out.add('${file.source}: "# $header $stated" but the rows hold '
          '$measured $unit');
    }

    check('cells', file.cells.length, 'coordinates');
    check('incidents', total.noise + total.overflow, 'incident rows');
    check('overflows', total.overflow, 'above tolerance');
    check('unmeasured', total.unmeasured, 'unmeasured coordinates');
    return out;
  }
}

/// The manifest format this script can read, and the file it reads it from.
///
/// Written by `test/layout_gate/screenshot.dart`, whose own constants are the
/// authority — these are the reader's half of a version negotiation, deliberately
/// a second copy. The two programs ship in one commit today and nothing makes them
/// ship in one commit forever: this one runs under a bare `dart run` and so cannot
/// import `test/`, which is also why the *file name* is carried in a manifest at
/// all rather than derived from the cell id twice.
const String overflowScreenshotManifestFormat = 'overflow-screenshots 1';
const String overflowScreenshotManifestName = 'index.tsv';

/// The images a shoot took, as hrefs a report can link.
///
/// Parsed rather than trusted: an unreadable manifest yields no images and says
/// why, because an image linked under the wrong cell id would show a reader a
/// picture of a coordinate they are not reading about — worse than no gallery.
class ScreenshotIndex {
  const ScreenshotIndex._({
    required this.images,
    required this.warnings,
    required this.source,
  });

  /// No manifest: what four of the five sweeps are rendered with.
  static const ScreenshotIndex none =
      ScreenshotIndex._(images: {}, warnings: [], source: '');

  /// Reads a manifest, resolving each name against [href].
  ///
  /// [href] is the images' directory **as the report must spell it** — see
  /// [screenshotHref]. Resolving here rather than at render time keeps one rule in
  /// one place: the gallery links whatever this map holds.
  factory ScreenshotIndex.parse(
    String text, {
    required String source,
    required String href,
  }) {
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return ScreenshotIndex._(
        images: const {},
        warnings: ['$source: holds no rows'],
        source: source,
      );
    }
    const expected = '# $overflowScreenshotManifestFormat';
    if (lines.first.trim() != expected) {
      return ScreenshotIndex._(
        images: const {},
        warnings: [
          '$source: expected "$expected" on the first line but it reads '
              '"${lines.first.trim()}", so nothing in it was read'
        ],
        source: source,
      );
    }

    final entries = <String, String>{};
    var malformed = 0;
    for (final line in lines.skip(1)) {
      final fields = line.split('\t');
      if (fields.length != 2 || fields.any((f) => f.trim().isEmpty)) {
        malformed++;
        continue;
      }
      entries[fields[0].trim()] =
          href.isEmpty ? fields[1].trim() : '$href/${fields[1].trim()}';
    }

    // Sorted by cell id, not left in the manifest's own order: it is appended to
    // as the sweep enumerates, so its order is the run's, and two shoots of the
    // same cells would otherwise render two galleries that differ on every line.
    final sorted = entries.keys.toList()..sort();
    return ScreenshotIndex._(
      images: {for (final cell in sorted) cell: entries[cell]!},
      warnings: [
        if (malformed > 0)
          '$source: skipped $malformed row${malformed == 1 ? '' : 's'} that is '
              'not a cell id and a file name — a manifest is appended to a row at '
              'a time, so a killed shoot can leave a half-written line',
      ],
      source: source,
    );
  }

  /// Cell id → href, sorted by cell id.
  final Map<String, String> images;

  /// Why this index is smaller than the file it was read from. Empty is normal.
  final List<String> warnings;

  /// The manifest's path, for the warnings a report adds of its own.
  final String source;
}

/// How a report written to [fromFile] must spell the directory [toDir].
///
/// The manifest sits beside its images in `build/…/shots/<sweep>/` and the report
/// is written to `build/…/report/<sweep>.shoot.md`, so an href copied from either path
/// alone resolves to nothing — and clicking is the one thing a reader does with a
/// gallery. Both paths must be relative to the same place, or `toDir` is returned
/// unchanged: two spellings of "where" cannot be reconciled by guessing.
String screenshotHref({required String fromFile, required String toDir}) {
  final slash = fromFile.lastIndexOf('/');
  final fromDir = slash < 0 ? '' : fromFile.substring(0, slash);
  if (fromDir.startsWith('/') != toDir.startsWith('/')) return toDir;

  final from = _pathSegments(fromDir);
  final to = _pathSegments(toDir);
  var shared = 0;
  while (shared < from.length &&
      shared < to.length &&
      from[shared] == to[shared]) {
    shared++;
  }
  final parts = [
    ...List.filled(from.length - shared, '..'),
    ...to.skip(shared),
  ];
  return parts.isEmpty ? '.' : parts.join('/');
}

List<String> _pathSegments(String path) =>
    path.split('/').where((s) => s.isNotEmpty && s != '.').toList();

/// How an incident with no resolved source location is shown.
///
/// Named rather than left as the dataset's `-`, because the reader's next move
/// after seeing a site is to key an allowlist entry with it, and this is the one
/// site that can never be keyed at all (#1341).
String _siteLabel(String site) => site == _absent ? '(unresolved)' : site;

/// Verdict counts over some slice of a dataset — a group, an axis value, a site.
class ReportTally {
  const ReportTally({
    required this.name,
    required this.cells,
    required this.clean,
    required this.noise,
    required this.overflow,
    required this.unmeasured,
    required this.unrecognised,
  });

  final String name;

  /// Coordinates in this slice, not rows.
  final int cells;

  /// Rows verdicted `clean` — measured, and under nothing worth recording.
  final int clean;

  /// Rows verdicted `noise`: an incident below the sweep's tolerance, recorded
  /// and not asserted on.
  final int noise;

  /// Rows verdicted `overflow`, which is what the gate fails on.
  final int overflow;

  /// Rows verdicted `error`: the pump did not finish, so nothing was measured.
  final int unmeasured;

  /// Rows whose verdict this reader does not know. Carried per slice, not only
  /// in the total, so a row that lands in none of the four columns above still
  /// explains why they do not sum to [cells].
  final int unrecognised;

  int get incidents => noise + overflow;
}

/// One axis of a sweep's cell ids, and every value it was measured at.
class ReportAxis {
  const ReportAxis(this.name, this.cells, this.values);

  final String name;

  /// Coordinates carrying this axis. Below the sweep's total when some group
  /// does not vary on it — three of the card sweep's six groups enumerate no
  /// locale, which is a coverage fact worth reading off a report.
  final int cells;

  final List<ReportTally> values;
}

class _Tally {
  final Set<String> cells = <String>{};
  int clean = 0;
  int noise = 0;
  int overflow = 0;
  int unmeasured = 0;
  int unrecognised = 0;

  void add(String cell, String verdict) {
    cells.add(cell);
    switch (verdict) {
      case verdictClean:
        clean++;
      case verdictNoise:
        noise++;
      case verdictOverflow:
        overflow++;
      case verdictError:
        unmeasured++;
      default:
        unrecognised++;
    }
  }

  ReportTally freeze(String name) => ReportTally(
        name: name,
        cells: cells.length,
        clean: clean,
        noise: noise,
        overflow: overflow,
        unmeasured: unmeasured,
        unrecognised: unrecognised,
      );
}

/// Renders a [BaselineReport] as Markdown.
String renderReportMarkdown(BaselineReport report) {
  final out = StringBuffer();
  for (final block in _reportBlocks(report)) {
    out.writeln(block.markdown());
  }
  return out.toString();
}

/// Renders a [BaselineReport] as one self-contained HTML file.
///
/// Self-contained deliberately: it is opened out of `build/` with no server and
/// no network, the same way the card sweep's report is.
String renderReportHtml(BaselineReport report) {
  final out = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln('<meta name="viewport" '
        'content="width=device-width, initial-scale=1">')
    ..writeln('<title>'
        '${_escapeHtml('Overflow baseline — ${report.sweep}')}</title>')
    ..writeln('<style>')
    ..writeln(_reportCss)
    ..writeln('</style>')
    ..writeln('</head>')
    ..writeln('<body>');
  for (final block in _reportBlocks(report)) {
    out.writeln(block.html());
  }
  return (out
        ..writeln('</body>')
        ..writeln('</html>'))
      .toString();
}

const String _reportCss = '''
body { margin: 2rem auto; padding: 0 1rem; max-width: 64rem; color: #24292f;
       font: 14px/1.6 -apple-system, "Segoe UI", Roboto, sans-serif; }
h1 { font-size: 1.5rem; } h2 { font-size: 1.2rem; margin-top: 2rem; }
h3 { font-size: 1rem; margin-top: 1.5rem; }
table { border-collapse: collapse; margin: 0.5rem 0 1.5rem; }
th, td { border: 1px solid #d0d7de; padding: 0.25rem 0.6rem; text-align: left;
         white-space: nowrap; }
th { background: #f6f8fa; }
code { background: #f6f8fa; border-radius: 3px; padding: 0 0.2rem; }
ul { padding-left: 1.2rem; }
.gallery { display: grid; gap: 1rem; margin: 1rem 0;
           grid-template-columns: repeat(auto-fill, minmax(15rem, 1fr)); }
.gallery figure { margin: 0; }
.gallery img { width: 100%; height: auto; border: 1px solid #d0d7de;
               background: #fff; }
.gallery figcaption { font-size: 0.8rem; word-break: break-all;
                      margin-top: 0.25rem; }''';

/// The document, built once and rendered twice.
///
/// Two hand-written renderers would be two places to state the same counts and
/// the same prose, and the failure that invites is a number that is right in one
/// format and wrong in the other. So the blocks are the report and the formats
/// are only spellings of them; prose is written as Markdown and translated for
/// HTML, while table cells are treated as data and escaped, never translated.
List<_Block> _reportBlocks(BaselineReport report) {
  final blocks = <_Block>[
    _Heading(1, 'Overflow baseline report — ${report.sweep}'),
  ];

  final commit = report.file.commit;
  // The sweep name is a header, so a file missing it cannot be told how to
  // re-capture itself: `capture (unnamed)` is not a command anyone can run, and
  // printing it would be worse than saying so.
  final recapture = report.file.sweep == null
      ? 'and this file names no sweep, so re-capturing it means finding which '
          'sweep wrote it first'
      : 'so re-capture it '
          '(`./tool/overflow_baseline.sh capture ${report.sweep}`)';
  blocks.add(_Para(
    'Rendered from `${report.file.source}`, which is a measurement of '
    '${commit == null ? '**an unnamed tree** (the file carries no `commit` '
        'header)' : 'commit `$commit`'} — '
    '**not of the working tree**. Nothing here was re-measured to produce it, '
    "$recapture before reading it as a statement about today's code.",
  ));
  if (commit != null && commit.endsWith('-dirty')) {
    blocks.add(_Para(
      'The commit is stamped `-dirty`: the measured paths carried uncommitted '
      'work when these rows were taken, so checking that sha out and '
      're-capturing **will not reproduce** them.',
    ));
  }
  if (report.headerDisagreements.isNotEmpty) {
    blocks
      ..add(_Para(
        '**This baseline disagrees with its rows.** The counts its header states '
        'were written at capture time, and everything below is recounted from '
        'the rows themselves — so the file has been edited by hand, or written '
        'by another version of this script. Read it as unverified until that is '
        'explained:',
      ))
      ..add(_Bullets(report.headerDisagreements));
  }

  blocks
    ..add(_Heading(2, 'What this file is'))
    ..add(_Bullets([
      'Sweep: `${report.sweep}`',
      if (report.file.headers['suite'] case final suite? when suite != _absent)
        'Suite: `$suite`',
      if (report.file.headers['groups'] case final groups?)
        'Groups: ${groups.split(' ').map((g) => '`$g`').join(', ')}',
      'Captured at: `${commit ?? '(unknown)'}`',
      'Dataset format: overflow-baseline $overflowBaselineVersion',
    ]))
    ..add(_Heading(2, 'Summary'))
    ..add(_Table(const [
      'measurement',
      'count'
    ], [
      ['Coordinates measured', '${report.cells}'],
      ['Clean', '${report.clean}'],
      [
        'Overflow (above tolerance, what the gate fails on)',
        '${report.overflows}'
      ],
      ['Noise (under tolerance, recorded not asserted)', '${report.noise}'],
      ['Unmeasured (the pump never finished)', '${report.unmeasured}'],
      if (report.unrecognised > 0)
        ['Unrecognised verdict', '${report.unrecognised}'],
      ['Rows', '${report.rows}'],
    ]))
    ..add(_Para(
      '**A clean cell is a row here, not an absence.** So the '
      '${report.cells} above is a coverage claim and not only a pass: every one '
      'of those coordinates was enumerated and pumped'
      // Not "and measured" when a pump died there: that is the one claim an
      // `error` row disproves, and the paragraph below is about exactly it.
      '${report.unmeasured == 0 ? ' and measured' : ''}. A coordinate '
      'that stops being enumerated leaves this dataset entirely, which is what '
      '`check` reports as lost coverage rather than as a layout that got fixed.',
    ));
  if (report.unmeasured > 0) {
    blocks.add(_Para(
      '`$verdictError` rows: ${report.unmeasured} of the coordinates above never '
      'finished their pump, so they **measured nothing**. They are present, so '
      'no diff calls them lost, and they are empty, so nothing distinguishes '
      'them from a layout that fits — which is why they are counted apart from '
      '`clean` here as well as in the dataset.',
    ));
  }
  if (report.unrecognised > 0) {
    blocks.add(_Para(
      '${report.unrecognised} '
      '${report.unrecognised == 1 ? 'row carries' : 'rows carry'} a verdict this '
      'script does not know, so above they are in no column but `Rows`, and the '
      'coverage tables below carry an `unrecognised` column they would otherwise '
      'be missing from while still counting under `coordinates`. The four '
      'verdicts it knows are `$verdictClean`, `$verdictNoise`, '
      '`$verdictOverflow` and `$verdictError`.',
    ));
  }

  // A verdict nothing here knows would otherwise count under `coordinates` and
  // in none of the verdict columns, leaving every row of these tables silently
  // short. Only present when the dataset holds one, so the normal report is the
  // four columns the dataset defines.
  final columns = report.unrecognised > 0
      ? const [
          'coordinates',
          'clean',
          'noise',
          'overflow',
          'unmeasured',
          'unrecognised'
        ]
      : const ['coordinates', 'clean', 'noise', 'overflow', 'unmeasured'];
  List<String> tallyRow(ReportTally tally) =>
      _tallyRow(tally, unrecognised: report.unrecognised > 0);

  blocks
    ..add(_Heading(2, 'Coverage by group'))
    ..add(_Table(
      ['group', ...columns],
      report.groups.map(tallyRow).toList(),
    ))
    ..add(_Heading(2, 'Coverage by axis'))
    ..add(_Para(
      'Each axis is counted over the coordinates that carry it, and the '
      'denominator is the whole sweep. A total below ${report.cells} therefore '
      'means some group does not vary on that axis at all — three of the card '
      "sweep's six groups enumerate no locale, for instance — which is a "
      'coverage fact and not a smaller sweep.',
    ));
  for (final axis in report.axes) {
    blocks
      ..add(_Heading(
        3,
        '`${axis.name}` — ${axis.values.length} '
        '${axis.values.length == 1 ? 'value' : 'values'} over ${axis.cells} of '
        '${report.cells} coordinates',
      ))
      ..add(_Table(
        ['value', ...columns],
        axis.values.map(tallyRow).toList(),
      ));
  }

  blocks.add(_Heading(2, 'Findings'));
  if (report.findings.isEmpty) {
    blocks.add(_Para(
      "None: all ${report.cells} coordinates measured clean at the sweep's "
      'tolerance.',
    ));
    return blocks..addAll(_galleryBlocks(report));
  }
  blocks
    ..add(_Para(
      '${report.findings.length} of ${report.rows} rows are not clean. The '
      '`site` column is the `file:line` key '
      '`test/fixtures/known_overflows.json` is keyed by (#1341), so copy an '
      'exemption key from it rather than reconstructing one — a key that matches '
      'no site reads as "not allowlisted" everywhere.',
    ))
    ..add(_Table(
      const ['cell', 'verdict', 'px', 'side', 'site', 'widget'],
      // The row verbatim except for one column, which is the point: a finding is
      // quoted as the dataset holds it, so the `cell` and `site` a reader copies
      // into `known_overflows.json` are the strings the sweep wrote.
      report.findings
          .map((row) => [
                ...row.take(_colSite),
                // An `error` row's empty site is left as the dataset's `-`. It is
                // not an incident whose location failed to resolve — there was no
                // incident — so calling it `(unresolved)` would send a reader
                // looking for a widget the allowlist note above cannot help with.
                row[_colVerdict] == verdictError
                    ? row[_colSite]
                    : _siteLabel(row[_colSite]),
                ...row.skip(_colSite + 1),
              ])
          .toList(),
    ));
  if (report.sites.isNotEmpty) {
    blocks
      ..add(_Heading(3, 'By site'))
      ..add(_Para(
        'One source location overflows at many coordinates — that is why the '
        'allowlist is keyed by location and not by cell — so this is the count '
        'to read when deciding what to fix.',
      ))
      ..add(_Table(
        const ['site', 'incident rows', 'overflow', 'noise', 'coordinates'],
        report.sites
            .map((site) => [
                  site.name,
                  '${site.incidents}',
                  '${site.overflow}',
                  '${site.noise}',
                  '${site.cells}',
                ])
            .toList(),
      ));
    if (report.sites.any((s) => s.name == '(unresolved)')) {
      blocks.add(_Para(
        'An incident whose location did not resolve is shown as `(unresolved)`. '
        'It has no key, so it **cannot be allowlisted** at all — `"*"` on every '
        'entry still will not cover it, deliberately: an exemption nobody can '
        'name is one nobody can retire.',
      ));
    }
  }
  return blocks..addAll(_galleryBlocks(report));
}

/// The gallery, and whatever did not reconcile about it.
///
/// Absent entirely from a report with no images — four of the five sweeps are
/// rendered that way, and an empty gallery would read as "photographed, and there
/// was nothing to show".
///
/// It answers the one question the dataset cannot: a cell's verdict says a
/// `RenderFlex` did not overflow, and says nothing about whether the result is
/// legible. Four dashboard cards pass at 191px rendering unreadably (#1240 AC1) and
/// #1349's fix trades an overflow for a wrap that every cell is blind to — both
/// green, both visible only in a picture.
List<_Block> _galleryBlocks(BaselineReport report) {
  final blocks = <_Block>[];
  if (report.shots.isEmpty && report.shotWarnings.isEmpty) return blocks;

  blocks.add(_Heading(2, 'Screenshots'));
  if (report.shots.isNotEmpty) {
    blocks
      ..add(_Para(
        'Images for ${report.shots.length} of the ${report.cells} coordinates '
        'above, taken by `./tool/overflow_baseline.sh shoot ${report.sweep}` and '
        'linked by cell id. ${_gallerySubject(report)}',
      ))
      ..add(_Gallery(report.shots));
  }
  if (report.shotWarnings.isNotEmpty) {
    blocks
      ..add(_Para(
        '**The images and the rows do not fully reconcile.** A shoot and a '
        'capture are two runs, and the cell id is the only thing joining them, so '
        'this pair came from **a different run** of at least one side — most often '
        'a `shoot` taken before the coordinates were re-enumerated. Nothing below '
        'is linked:',
      ))
      ..add(_Bullets(report.shotWarnings));
  }
  return blocks;
}

/// What the gallery is a gallery *of*, recounted from the rows.
///
/// The two shoots mean opposite things and the pictures cannot say which they are:
/// `shoot <sweep> locale=ar` photographs cells these rows call clean — the blind
/// spot the feature exists for, four cards passing at 191px rendering unreadably
/// (#1240 AC1) — while `shoot <sweep> failed` photographs exactly the rows marked
/// `overflow`. Claiming the first unconditionally would, on a red sweep, invite a
/// reader to take three pictures of an overflow as evidence that it fits.
///
/// Derived here rather than passed in from the runner, because a report that quoted
/// the pattern would be trusting an argument instead of the data — the same mistake
/// as quoting a header over its own rows.
String _gallerySubject(BaselineReport report) {
  final failed = report.shots.keys.where(report.failedCells.contains).length;
  if (failed == 0) {
    return 'A verdict above says no `RenderFlex` overflowed; it says nothing about '
        'whether the result can be read — which is what these are for.';
  }
  if (failed == report.shots.length) {
    return 'These are the coordinates this run failed, every one of them a failure '
        'above: an overflow past the tolerance, or a pump that did not finish.';
  }
  return '$failed of them failed above; the other ${report.shots.length - failed} '
      'passed, and a verdict that a cell passed says nothing about whether the '
      'result can be read.';
}

List<String> _tallyRow(ReportTally tally, {required bool unrecognised}) => [
      tally.name,
      '${tally.cells}',
      '${tally.clean}',
      '${tally.noise}',
      '${tally.overflow}',
      '${tally.unmeasured}',
      if (unrecognised) '${tally.unrecognised}',
    ];

/// One piece of a report, in the two spellings it has.
abstract class _Block {
  String markdown();
  String html();
}

class _Heading implements _Block {
  const _Heading(this.level, this.text);

  final int level;
  final String text;

  @override
  String markdown() => '${'#' * level} $text\n';

  @override
  String html() => '<h$level>${_inlineHtml(text)}</h$level>';
}

class _Para implements _Block {
  const _Para(this.text);

  final String text;

  @override
  String markdown() => '$text\n';

  @override
  String html() => '<p>${_inlineHtml(text)}</p>';
}

class _Bullets implements _Block {
  const _Bullets(this.items);

  final List<String> items;

  @override
  String markdown() => '${items.map((i) => '- $i').join('\n')}\n';

  @override
  String html() =>
      '<ul>\n${items.map((i) => '  <li>${_inlineHtml(i)}</li>').join('\n')}\n'
      '</ul>';
}

/// Header row plus data rows. Every cell is data, never prose.
class _Table implements _Block {
  const _Table(this.columns, this.rows);

  final List<String> columns;
  final List<List<String>> rows;

  @override
  String markdown() {
    final out = StringBuffer()
      ..writeln('| ${columns.map(_escapeMarkdownCell).join(' | ')} |')
      ..writeln('|${columns.map((_) => '---').join('|')}|');
    for (final row in rows) {
      out.writeln('| ${row.map(_escapeMarkdownCell).join(' | ')} |');
    }
    return out.toString();
  }

  @override
  String html() {
    final out = StringBuffer()
      ..writeln('<table>')
      ..writeln('<thead><tr>'
          '${columns.map((c) => '<th>${_escapeHtml(c)}</th>').join()}'
          '</tr></thead>')
      ..writeln('<tbody>');
    for (final row in rows) {
      out.writeln('<tr>'
          '${row.map((c) => '<td>${_escapeHtml(c)}</td>').join()}'
          '</tr>');
    }
    return (out
          ..writeln('</tbody>')
          ..write('</table>'))
        .toString();
  }
}

/// One image per cell id, captioned with the id.
///
/// A block of its own rather than a column on the findings table, for two reasons:
/// a table cell is escaped as data (so a link written into one arrives as literal
/// text, by design — see [_escapeMarkdownCell]), and the gallery covers *clean*
/// coordinates, which the findings table by definition does not list.
///
/// The two spellings differ on purpose. Markdown has no way to size an image, so it
/// inlines each at full size under its id — which is what a reader diffing two
/// widths in an editor preview wants. HTML lays them out as a lazy-loading grid, so
/// a shoot of hundreds opens at all, and each thumbnail links to its own file.
class _Gallery implements _Block {
  const _Gallery(this.images);

  /// Cell id → href, already sorted by cell id.
  final Map<String, String> images;

  @override
  String markdown() {
    final out = StringBuffer();
    for (final shot in images.entries) {
      out
        ..writeln('#### `${shot.key}`')
        ..writeln()
        // Image inside a link: the picture is the point, and the link is what
        // opens it at full size when the preview has scaled it down.
        ..writeln('[![${shot.key}](${shot.value})](${shot.value})')
        ..writeln();
    }
    return out.toString();
  }

  @override
  String html() {
    final out = StringBuffer()..writeln('<div class="gallery">');
    for (final shot in images.entries) {
      final href = _escapeHtml(shot.value);
      final cell = _escapeHtml(shot.key);
      out.writeln('<figure><a href="$href">'
          '<img src="$href" alt="$cell" loading="lazy"></a>'
          '<figcaption><code>$cell</code></figcaption></figure>');
    }
    return (out..write('</div>')).toString();
  }
}

/// Keeps a value inside its column.
///
/// Every cell id contains `|` — it is the axis separator — and a widget name
/// reaches the TSV with only tabs and newlines stripped. Unescaped, one row would
/// silently gain columns, and the key a reader copied out of it would be a
/// fragment.
String _escapeMarkdownCell(String value) => value.replaceAll('|', r'\|');

String _escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Translates the Markdown the prose is written in — `**bold**` and `` `code` ``
/// and nothing else — into HTML, after escaping the text.
String _inlineHtml(String text) => _escapeHtml(text)
    .replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*'), (m) => '<strong>${m[1]}</strong>')
    .replaceAllMapped(RegExp('`(.+?)`'), (m) => '<code>${m[1]}</code>');

const String _usage = '''
usage:
  # capture with: flutter test <suite> --reporter json > run.json
  dart run test_scripts/overflow_baseline.dart extract \\
      --reporter <run.json> --sweep <id> [--out <file>] \\
      [--commit <sha>] [--suite <path>]

  dart run test_scripts/overflow_baseline.dart diff \\
      --baseline <file> (--actual <file> | --reporter <run.json>)

  # read a committed baseline; runs no tests
  dart run test_scripts/overflow_baseline.dart render \\
      --baseline <file> [--format md|html] [--out <file>] \\
      [--shots <dir of a shoot's PNGs + $overflowScreenshotManifestName>]

exit codes: 0 = clean, 1 = the datasets differ (for render: the baseline
disagrees with its own header), 2 = bad input

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
      case 'render':
        return _renderCommand(options, stdoutSink, stderrSink);
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

  _writeOrPrint(text, summary: extracted.summary, options: options, out: out);
  return 0;
}

/// `--out <file>` or stdout, the one way both writing subcommands emit.
///
/// The two are deliberately symmetrical: a document on stdout is pipeable, and a
/// document written to a file leaves [summary] on stdout instead — so the counts
/// are reported either way and never interleaved with the thing being counted.
void _writeOrPrint(
  String text, {
  required String summary,
  required Map<String, String> options,
  required StringSink out,
}) {
  final target = options['--out'];
  if (target == null) {
    out.write(text);
    return;
  }
  File(target)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);
  out.writeln('$summary -> $target');
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

/// Turns a committed baseline into something a human reads.
///
/// Exits 1 when the file's own header contradicts its rows — the same code a
/// differing diff uses, and for the same reason: two readings of one dataset do
/// not agree, so nothing in the document should be quoted until someone has
/// looked. The document is still written, because it is what says what the
/// disagreement is.
int _renderCommand(
  Map<String, String> options,
  StringSink out,
  StringSink err,
) {
  final path = _require(options, '--baseline');
  final report = BaselineReport.of(
    BaselineFile.parse(_readFile(path), source: path),
    shots: _shotsFor(options, err),
  );

  final format = options['--format'] ?? 'md';
  final String text;
  switch (format) {
    case 'md':
      text = renderReportMarkdown(report);
    case 'html':
      text = renderReportHtml(report);
    default:
      throw FormatException(
          'unknown --format "$format": this writes md or html');
  }

  _writeOrPrint(text, summary: report.summary, options: options, out: out);
  for (final disagreement in report.headerDisagreements) {
    err.writeln(disagreement);
  }
  // Printed, and deliberately not part of the exit code: `--shots` points at
  // `build/`, which survives a re-capture, so a stale image folder must not make a
  // green dataset read as a failed check. The document says the same thing.
  for (final warning in report.shotWarnings) {
    err.writeln(warning);
  }
  return report.headerDisagreements.isEmpty ? 0 : 1;
}

/// The gallery `render` was asked for, or [ScreenshotIndex.none].
///
/// A missing manifest is a note on stderr rather than an error: `--shots` is
/// passed by `tool/overflow_baseline.sh` whenever the directory exists, and a
/// report without pictures is still the report.
ScreenshotIndex _shotsFor(Map<String, String> options, StringSink err) {
  final dir = options['--shots'];
  if (dir == null || dir.isEmpty) return ScreenshotIndex.none;

  final manifest = '$dir/$overflowScreenshotManifestName';
  if (!File(manifest).existsSync()) {
    err.writeln('no screenshot manifest at $manifest, '
        'so this report has no gallery');
    return ScreenshotIndex.none;
  }
  // Relative to the file being written, because that is what a browser resolves
  // against. Rendering to stdout has no location to be relative to, so the
  // directory is used as given.
  final out = options['--out'];
  return ScreenshotIndex.parse(
    File(manifest).readAsStringSync(),
    source: manifest,
    href: out == null ? dir : screenshotHref(fromFile: out, toDir: dir),
  );
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
