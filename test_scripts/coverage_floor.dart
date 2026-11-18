// Fails when coverage drops below the committed floor (#1803 Q5).
//
// usage: dart test_scripts/coverage_floor.dart <lcov.info>
//
// It reads the floor from coverage_floor.txt, prints one line for the job
// summary, and exits 1 when the total of lib/ is below the floor. The total is
// the one coverage_summary.dart reports, so run it on the lcov.info of
// run_coverage.sh.
import 'dart:io';

import 'coverage_summary.dart' show summarize;

/// The committed floor, a percentage of lib/'s lines.
const floorPath = 'coverage_floor.txt';

/// The floor in [text]: the one line that is neither blank nor a `#` comment.
double readFloor(String text) {
  final values = [
    for (final line in text.split('\n'))
      if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#'))
        line.trim(),
  ];
  if (values.length != 1) {
    throw FormatException(
        '$floorPath should hold one number, not ${values.length}.', text);
  }
  final floor = double.parse(values.single);
  if (floor < 0 || floor > 100) {
    throw FormatException('$floorPath holds $floor, not a percentage.', text);
  }
  return floor;
}

/// Whether [covered] of [lines] is at or above [floor], and the line that
/// says so. The comparison is exact, to a hundredth of a percent, so a total
/// that only rounds up to the floor is below it.
({bool passes, String message}) checkFloor({
  required int covered,
  required int lines,
  required double floor,
}) {
  final passes = covered * 10000 >= (floor * 100).round() * lines;
  final total = (100 * covered / lines).toStringAsFixed(2);
  return passes
      ? (
          passes: true,
          message: 'Coverage $total% is at or above the floor of $floor% '
              '(`$floorPath`).',
        )
      : (
          passes: false,
          message: '**Coverage $total% is below the floor of $floor%** '
              '(`$floorPath`). Add the tests that went missing, or lower the '
              'floor with the reason in the PR.',
        );
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart test_scripts/coverage_floor.dart <lcov.info>');
    exit(2);
  }
  final all = summarize(File(args.single).readAsStringSync()).all;
  final check = checkFloor(
    covered: all.covered,
    lines: all.lines,
    floor: readFloor(File(floorPath).readAsStringSync()),
  );
  stdout.writeln(check.message);
  exit(check.passes ? 0 : 1);
}
