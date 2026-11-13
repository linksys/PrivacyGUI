import 'dart:io';

/// Every Dart file under [directory], keyed by its repo-relative path.
Map<String, String> dartSources(String directory) => {
      for (final file in Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')))
        file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
    };

/// A comment that starts a line: `//` to the end of the line, or `/*` to the
/// next `*/`. A comment after code is left alone, so that a URL in a string,
/// such as `'http://…'`, cannot hide the rest of its line.
final _lineStartComment =
    RegExp(r'^\s*(?://[^\n]*|/\*[\s\S]*?\*/)', multiLine: true);

String withoutLineStartComments(String source) =>
    source.replaceAll(_lineStartComment, '');

final _row = RegExp(r'^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|', multiLine: true);

/// Reads the exception table that `constitution.md` keeps between
/// `<!-- [name]:begin -->` and `<!-- [name]:end -->`, as `<from> -> <to>`
/// taken from the first two cells of each row.
///
/// Throws when the markers are not there exactly once, in order, or when a
/// row below the header has no backticked first two cells, so that a row the
/// checks cannot read never goes unnoticed.
Set<String> readExceptionTable(String constitution, String name) {
  final beginMarker = '<!-- $name:begin -->';
  final endMarker = '<!-- $name:end -->';
  final begin = constitution.indexOf(beginMarker);
  final end = constitution.indexOf(endMarker);
  if (beginMarker.allMatches(constitution).length != 1 ||
      endMarker.allMatches(constitution).length != 1 ||
      end < begin) {
    throw StateError(
        'constitution.md must hold the "$name" table markers once, in order.');
  }
  final rows = <String>{};
  final tableLines = constitution
      .substring(begin, end)
      .split('\n')
      .where((line) => line.startsWith('|'));
  // The first two lines are the header and its separator.
  for (final line in tableLines.skip(2)) {
    final row = _row.firstMatch(line);
    if (row == null) {
      throw StateError(
          'The "$name" table in constitution.md has a row the checks cannot '
          'read; put its first two cells in backticks:\n$line');
    }
    rows.add('${row.group(1)} -> ${row.group(2)}');
  }
  return rows;
}

/// [items], sorted, one `  - item` line each, for a failure message.
String bulletList(Set<String> items) =>
    (items.toList()..sort()).map((item) => '  - $item').join('\n');
