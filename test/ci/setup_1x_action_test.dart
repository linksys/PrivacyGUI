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

  group('the 1.x setup', () {
    // The pub commands the setup runs. Comments are skipped: they explain the
    // commands and are free to name them.
    final pubCommands = [
      for (final line
          in File('.github/actions/setup-1x/action.yml').readAsLinesSync())
        if (!line.trimLeft().startsWith('#') &&
            line.contains(RegExp(r'pub (get|upgrade|downgrade|add)\b')))
          line.trim(),
    ];

    test('installs the lock as it is, and never resolves afresh', () {
      expect(pubCommands, isNotEmpty);
      for (final command in pubCommands) {
        expect(command, contains('pub get'));
        expect(command, contains('--enforce-lockfile'));
      }
    });

    test('runs dart pub get after flutter pub get', () {
      final flutterPubGet = pubCommands
          .indexWhere((command) => command.contains('flutter pub get'));
      final dartPubGet =
          pubCommands.indexWhere((command) => command.contains('dart pub get'));

      expect(flutterPubGet, isNot(-1));
      expect(dartPubGet, greaterThan(flutterPubGet),
          reason: 'On Flutter 3.27, `flutter pub get --enforce-lockfile` '
              'leaves the synthetic flutter_gen package in '
              'package_config.json with no pubspec, and build_runner then '
              'fails to build its package graph. `dart pub get` rewrites '
              'package_config.json without it.');
    });
  });
}
