import 'dart:io';

import 'package:test/test.dart';

/// Constitution 3.1 and 3.5 rely on `run_tests.sh` leaving out the golden and
/// loc tests, which have no golden images to compare against in this repo.
///
/// It also leaves out `layout-gate`, the layout gate's tests, which take long
/// enough to run in CI jobs of their own (#1802 P3, Decision 11).
void main() {
  // The commands, without the comments, which may quote other commands.
  final script = File('run_tests.sh')
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n');
  final excludes = RegExp(r'--exclude-tags=\S+').allMatches(script).toList();

  /// The tags run_tests.sh excludes, as bash expands its argument.
  Set<String> excludedTags() {
    final result = Process.runSync(
      'bash',
      ['-c', 'printf %s ${excludes.single.group(0)}'],
      environment: const {},
      includeParentEnvironment: false,
    );
    final value = (result.stdout as String).replaceFirst('--exclude-tags=', '');
    return value.split('||').toSet();
  }

  test('run_tests.sh passes one --exclude-tags', () {
    // flutter test takes the option once: a second one replaces the first, and
    // the run would include golden and loc again.
    expect(excludes, hasLength(1));
  });

  test('run_tests.sh excludes the golden, loc and layout-gate tags', () {
    expect(excludedTags(), {'golden', 'loc', 'layout-gate'});
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
