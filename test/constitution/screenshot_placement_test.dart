import 'dart:io';

import 'package:test/test.dart';

import 'screenshot_scanner.dart';
import 'source_scan.dart';

/// Holds `test/` to `constitution.md` 3.5: golden checks stay in
/// `testLocalizations`, and its cases stay in `localizations/` directories,
/// except for the rows of the table in 3.5.
void main() {
  late Set<String> found;
  late Set<String> listed;

  setUpAll(() {
    // test/constitution/ holds these checks and their fixtures, which name
    // the very calls they look for.
    final sources = dartSources('test')
      ..removeWhere((path, _) => path.startsWith('test/constitution/'));
    found = findScreenshotTestViolations(sources);
    listed = readExceptionTable(
      File('constitution.md').readAsStringSync(),
      'screenshot-exceptions',
    );
  });

  test(
      'every misplaced screenshot check in test/ has a row in '
      'constitution.md 3.5', () {
    final unlisted = found.difference(listed);

    expect(
      unlisted,
      isEmpty,
      reason: 'These files break constitution.md 3.5 and have no row in its '
          'table:\n${_bullets(unlisted)}\n'
          'Write the golden check as a testLocalizations case, in a '
          'localizations/ directory. Adding a row instead is an amendment '
          '(Article IX).',
    );
  });

  test('every row in constitution.md 3.5 is still misplaced in test/', () {
    final stale = listed.difference(found);

    expect(
      stale,
      isEmpty,
      reason: 'These rows of the constitution.md 3.5 table no longer match the '
          'tests. Delete them:\n${_bullets(stale)}',
    );
  });
}

String _bullets(Set<String> items) =>
    (items.toList()..sort()).map((item) => '  - $item').join('\n');
