// Summarises lcov.info the way #1803 measures coverage, as Markdown (#1803 Q1).
//
// usage: dart test_scripts/coverage_summary.dart <lcov.info> [tests.json]
//
// It prints #1803's table: all of lib/, then logic and UI. The split is by
// path and file name, so it is approximate; #1803 describes it. Generated
// l10n is left out. Run it on the lcov.info of a run that loaded every lib
// file (run_coverage.sh), or files no test loads go uncounted. Given that
// run's tests.json, it warns when the import-all helper did not run.
import 'dart:convert';
import 'dart:io';

import 'coverage_import_all.dart' show helperPath, helperTestName;

enum Area { logic, ui, other }

final _uiDirectory = RegExp(r'/(views?|widgets?|components?)/');
final _uiName = RegExp(r'_view\.dart$');
final _logicDirectory =
    RegExp(r'^(core|route)/|/(providers|models?|utils?)/|^(utils?|providers)/');
final _logicName = RegExp(r'(provider|notifier|state|model|util)s?\.dart$');

/// Which row of the table a lib file, given relative to lib/, counts in.
/// UI is checked first.
Area classify(String path) {
  if (_uiDirectory.hasMatch('/$path') || _uiName.hasMatch(path)) {
    return Area.ui;
  }
  if (_logicDirectory.hasMatch(path) || _logicName.hasMatch(path)) {
    return Area.logic;
  }
  return Area.other;
}

/// Lines and files in one row.
class CoverageRow {
  int files = 0;
  int untested = 0;
  int lines = 0;
  int covered = 0;

  void add(int fileLines, int fileCovered) {
    files++;
    if (fileCovered == 0) untested++;
    lines += fileLines;
    covered += fileCovered;
  }

  String get percent =>
      lines == 0 ? 'n/a' : '${(100 * covered / lines).toStringAsFixed(1)}%';
}

class Summary {
  final all = CoverageRow();
  final logic = CoverageRow();
  final ui = CoverageRow();
  final other = CoverageRow();

  CoverageRow operator [](Area area) => switch (area) {
        Area.logic => logic,
        Area.ui => ui,
        Area.other => other,
      };
}

/// The rows of an lcov.info. A line listed twice counts once, at its highest
/// hit count. Files with no executable line are left out.
Summary summarize(String lcov) {
  final hits = <String, Map<int, int>>{};
  Map<int, int>? file;
  for (final line in lcov.split('\n').map((line) => line.trim())) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3);
      final lib = path.indexOf('lib/');
      final relative = lib < 0 ? path : path.substring(lib + 'lib/'.length);
      file = relative.startsWith('l10n/gen/')
          ? null
          : hits.putIfAbsent(relative, () => {});
    } else if (line.startsWith('DA:') && file != null) {
      final [number, count, ...] = line.substring(3).split(',');
      final n = int.parse(number);
      final c = int.parse(count);
      file[n] = c > (file[n] ?? 0) ? c : (file[n] ?? 0);
    } else if (line == 'end_of_record') {
      file = null;
    }
  }
  final summary = Summary();
  for (final MapEntry(key: path, value: lines) in hits.entries) {
    if (lines.isEmpty) continue;
    final covered = lines.values.where((count) => count > 0).length;
    summary.all.add(lines.length, covered);
    summary[classify(path)].add(lines.length, covered);
  }
  return summary;
}

String withCommas(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String _plural(int n, String word) =>
    '${withCommas(n)} $word${n == 1 ? '' : 's'}';

/// Whether the import-all helper's test passed in a run's tests.json (the
/// JSON reporter's output, one event per line). A helper that fails to
/// compile reports only a failed load, so its test never starts.
bool helperRan(String testsJson) {
  int? helperTest;
  for (final line in const LineSplitter().convert(testsJson)) {
    if (line.trim().isEmpty) continue;
    final event = jsonDecode(line);
    if (event is! Map<String, dynamic>) continue;
    if (event['type'] == 'testStart') {
      final test = event['test'] as Map<String, dynamic>;
      if (test['name'] == helperTestName &&
          '${test['url']}'.endsWith(helperPath)) {
        helperTest = test['id'] as int;
      }
    } else if (event['type'] == 'testDone' &&
        helperTest != null &&
        event['testID'] == helperTest) {
      return event['result'] == 'success';
    }
  }
  return false;
}

/// #1803's table, with a note on what it counts. [helperRan] false adds a
/// warning: without the helper, files no test loads are missing.
String markdown(Summary summary, {bool helperRan = true}) {
  String row(String label, CoverageRow r, {bool bold = false}) {
    final percent = bold ? '**${r.percent}**' : r.percent;
    return '| $label | ${withCommas(r.lines)} | $percent '
        '| ${withCommas(r.untested)} of ${withCommas(r.files)} |';
  }

  return [
    '### 1.x unit test coverage',
    '',
    '| | Lines | Covered | Files at 0% |',
    '|---|--:|--:|--:|',
    row('**All of `lib/`**', summary.all, bold: true),
    row(
        'Logic (providers, notifiers, states, models, `core/`, `route/`, '
        'utils)',
        summary.logic,
        bold: true),
    row('UI (views, widgets, components)', summary.ui),
    '',
    if (!helperRan)
      '**Warning**: the import-all helper did not run, so the files no test '
          'loads are missing and the figure reads high. See its failure in '
          'the test log.\n',
    '${_plural(summary.other.files, 'file')} '
        '(${_plural(summary.other.lines, 'line')}) '
        '${summary.other.files == 1 ? 'is' : 'are'} in neither row.',
    'Measured as #1803 describes: the run imports every lib file, so a file '
        'no test loads counts at 0%. `lib/l10n/gen/` and web-only files are '
        'left out.',
    '',
  ].join('\n');
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart test_scripts/coverage_summary.dart '
        '<lcov.info> [tests.json]');
    exit(2);
  }
  final [lcov, ...rest] = args;
  final summary = summarize(File(lcov).readAsStringSync());
  final ran = rest.isEmpty || helperRan(File(rest.first).readAsStringSync());
  stdout.write(markdown(summary, helperRan: ran));
}
