// Prints the screenshot suites that a change can break the layout of, one per
// line (#1802 P3, Decision 12). The pre-push hook, .githooks/pre-push, runs
// the layout gate on them.
//
//   git diff --name-only <from> <to> | dart test_scripts/layout_gate_affected.dart
//
// Reads the changed paths from stdin, one per line, relative to the repo root.
// The rules are in test/layout_gate/affected_suites.dart, where their tests
// are; the suites are found as the roster finds them.
import 'dart:io';

import '../test/constitution/roster_scanner.dart';
import '../test/constitution/source_scan.dart';
import '../test/layout_gate/affected_suites.dart';

void main() {
  final changed = <String>[];
  for (String? line; (line = stdin.readLineSync()) != null;) {
    if (line!.trim().isNotEmpty) changed.add(line.trim());
  }
  final suites = screenshotSuites(dartSources('test'));
  for (final suite in affectedGateSuites(changed, suites).toList()..sort()) {
    stdout.writeln(suite);
  }
}
