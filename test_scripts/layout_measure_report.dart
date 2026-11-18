// Prints the Markdown report of a layout measurement run (#1802 P2).
//
//   dart test_scripts/layout_measure_report.dart <tests.json>...
//
// Each argument is the `tests.json` of one measuring job, written with
// `--file-reporter json:`. The report logic is in
// test/layout_gate/measure_report.dart, where its tests are.
import 'dart:convert';
import 'dart:io';

import '../test/layout_gate/measure_report.dart';

void main(List<String> paths) {
  if (paths.isEmpty) {
    stderr.writeln(
        'usage: dart test_scripts/layout_measure_report.dart <tests.json>...');
    exit(64);
  }
  final runs = [
    for (final path in paths)
      [
        for (final line in File(path).readAsLinesSync())
          if (line.trim().isNotEmpty)
            jsonDecode(line) as Map<String, Object?>,
      ],
  ];
  stdout.write(MeasureReport.fromRuns(runs).toMarkdown());
}
