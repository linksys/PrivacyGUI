import 'dart:io';

import 'package:test/test.dart';

import 'boundary_scanner.dart';
import 'source_scan.dart';

/// Holds `lib/` to `constitution.md` Article I: what the scanner finds must
/// equal the exception table in section 1.4, row for row.
void main() {
  late Set<String> found;
  late Set<String> listed;

  setUpAll(() {
    found = findBoundaryViolations(dartSources('lib'));
    listed = readExceptionTable(
      File('constitution.md').readAsStringSync(),
      'boundary-exceptions',
    );
  });

  test('every boundary violation in lib/ has a row in constitution.md 1.4', () {
    final unlisted = found.difference(listed);

    expect(
      unlisted,
      isEmpty,
      reason: 'These dependencies break constitution.md Article I and have no '
          'row in its 1.4 table:\n${_bullets(unlisted)}\n'
          "Move the call into the feature's notifier. Adding a row instead is "
          'an amendment (Article IX).',
    );
  });

  test('every row in constitution.md 1.4 is still a violation in lib/', () {
    final stale = listed.difference(found);

    expect(
      stale,
      isEmpty,
      reason: 'These rows of the constitution.md 1.4 table no longer match the '
          'code. Delete them:\n${_bullets(stale)}',
    );
  });
}

String _bullets(Set<String> items) =>
    (items.toList()..sort()).map((item) => '  - $item').join('\n');
