import 'dart:io';

import 'package:test/test.dart';

/// CI installs the committed lock, so that it tests the packages a developer
/// tested, and a package released upstream cannot turn the required checks
/// red with no change in the PR (#1802).
void main() {
  test('pubspec.lock is committed', () {
    final tracked =
        Process.runSync('git', ['ls-files', '--error-unmatch', 'pubspec.lock']);

    expect(tracked.exitCode, 0, reason: 'git does not track pubspec.lock');
    expect(File('.gitignore').readAsLinesSync().map((line) => line.trim()),
        isNot(contains('/pubspec.lock')));
  });

  test('every pub get in the 1.x setup installs the lock as it is', () {
    final pubGets = [
      for (final line
          in File('.github/actions/setup-1x/action.yml').readAsLinesSync())
        if (line.contains('pub get')) line.trim(),
    ];

    expect(pubGets, isNotEmpty);
    for (final pubGet in pubGets) {
      expect(pubGet, contains('--enforce-lockfile'));
    }
  });
}
