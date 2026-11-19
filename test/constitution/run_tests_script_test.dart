import 'dart:io';

import 'package:test/test.dart';

/// Constitution 3.1 and 3.5 rely on `run_tests.sh` leaving out the golden and
/// loc tests, which have no golden images to compare against in this repo.
///
/// CI's `1.x / Unit Tests` also leaves out `layout-gate`, which runs in jobs
/// of its own (#1802 P3), through `EXTRA_EXCLUDE_TAGS`. With or without it,
/// `golden` and `loc` stay excluded.
void main() {
  final script = File('run_tests.sh').readAsStringSync();
  final excludes = RegExp(r'--exclude-tags=\S+').allMatches(script).toList();

  /// The tags run_tests.sh excludes, as bash expands its argument with
  /// [extra] as `EXTRA_EXCLUDE_TAGS`.
  Set<String> excludedTags({String? extra}) {
    final result = Process.runSync('bash', [
      '-c',
      'printf %s ${excludes.single.group(0)}',
    ], environment: {
      if (extra != null) 'EXTRA_EXCLUDE_TAGS': extra,
    }, includeParentEnvironment: false);
    final value = (result.stdout as String).replaceFirst('--exclude-tags=', '');
    return value.split('||').toSet();
  }

  test('run_tests.sh passes one --exclude-tags', () {
    // flutter test takes the option once: a second one replaces the first, and
    // the run would include golden and loc again.
    expect(excludes, hasLength(1));
  });

  test('run_tests.sh excludes the golden and loc tags', () {
    expect(excludedTags(), {'golden', 'loc'});
  });

  test('run_tests.sh also excludes EXTRA_EXCLUDE_TAGS, and still golden and loc',
      () {
    expect(excludedTags(extra: 'layout-gate'), {'golden', 'loc', 'layout-gate'});
  });
}
