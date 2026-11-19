import 'dart:io';

import 'package:test/test.dart';

/// Constitution 3.1 and 3.5 rely on `run_tests.sh` leaving out the golden and
/// loc tests, which have no golden images to compare against in this repo.
void main() {
  test('run_tests.sh excludes the golden and loc tags', () {
    expect(
      File('run_tests.sh').readAsStringSync(),
      contains('--exclude-tags="golden||loc"'),
    );
  });

  // `1.x / Unit Tests` runs run_coverage.sh (#1803 Q1), so it leaves the tags
  // out only as long as that script goes through run_tests.sh.
  test('run_coverage.sh runs the tests through run_tests.sh', () {
    final commands = File('run_coverage.sh')
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('#'))
        .join('\n');

    expect(commands, contains('bash run_tests.sh'));
    expect(commands, isNot(contains('flutter test')));
  });
}
