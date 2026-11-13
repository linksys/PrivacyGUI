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
}
