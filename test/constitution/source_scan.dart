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
Set<String> readExceptionTable(String constitution, String name) {
  final begin = constitution.indexOf('<!-- $name:begin -->');
  final end = constitution.indexOf('<!-- $name:end -->');
  if (begin < 0 || end < begin) {
    throw StateError('constitution.md has lost its "$name" table markers.');
  }
  return {
    for (final row in _row.allMatches(constitution.substring(begin, end)))
      '${row.group(1)} -> ${row.group(2)}',
  };
}
