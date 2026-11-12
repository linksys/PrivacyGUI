import 'dart:io';

import 'package:test/test.dart';

import 'boundary_scanner.dart';

/// Holds `lib/` to `constitution.md` Article I: what the scanner finds must
/// equal the exception table in section 1.4, row for row.
void main() {
  late Set<String> found;
  late Set<String> listed;

  setUpAll(() {
    found = findBoundaryViolations(_libSources());
    listed = _listedExceptions(File('constitution.md').readAsStringSync());
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

Map<String, String> _libSources() => {
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')))
        file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
    };

const _begin = '<!-- boundary-exceptions:begin -->';
const _end = '<!-- boundary-exceptions:end -->';
final _row = RegExp(r'^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|', multiLine: true);

/// Reads the rows between the boundary-exceptions markers as `<from> -> <to>`.
Set<String> _listedExceptions(String constitution) {
  final begin = constitution.indexOf(_begin);
  final end = constitution.indexOf(_end);
  if (begin < 0 || end < begin) {
    throw StateError(
        'constitution.md has lost its "$_begin" … "$_end" block (section 1.4).');
  }
  return {
    for (final row in _row.allMatches(constitution.substring(begin, end)))
      '${row.group(1)} -> ${row.group(2)}',
  };
}

String _bullets(Set<String> items) =>
    (items.toList()..sort()).map((item) => '  - $item').join('\n');
