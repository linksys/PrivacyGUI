import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/test.dart';

/// Every Dart file under [directory], keyed by its repo-relative path.
Map<String, String> dartSources(String directory) => {
      for (final file in Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')))
        file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
    };

/// [source] parsed as Dart. A file with syntax errors still yields the nodes
/// the parser recovered.
CompilationUnit parseDart(String source) =>
    parseString(content: source, throwIfDiagnostics: false).unit;

/// The URIs that [unit]'s imports and exports name, conditional ones included.
Iterable<String> directiveUris(CompilationUnit unit) sync* {
  for (final directive in unit.directives.whereType<NamespaceDirective>()) {
    final uri = directive.uri.stringValue;
    if (uri != null) yield uri;
    for (final configuration in directive.configurations) {
      final conditional = configuration.uri.stringValue;
      if (conditional != null) yield conditional;
    }
  }
}

/// The identifiers and type names that the code in [node] uses. Comments are
/// not code, and a string is not a name.
Set<String> namesIn(AstNode node) {
  final names = <String>{};
  node.accept(_NameCollector(names));
  return names;
}

class _NameCollector extends RecursiveAstVisitor<void> {
  _NameCollector(this.names);

  final Set<String> names;

  @override
  void visitComment(Comment node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name2.lexeme);
    super.visitNamedType(node);
  }
}

final _row = RegExp(r'^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|');
final _separator = RegExp(r'^\|(\s*:?-{3,}:?\s*\|)+\s*$');

/// Reads the exception table that `constitution.md` keeps between
/// `<!-- [name]:begin -->` and `<!-- [name]:end -->`, as `<from> -> <to>`
/// taken from the first two cells of each row.
///
/// Throws unless the markers are there exactly once, in order, the table
/// starts with a header and its `|---|` separator, and every row below them
/// has backticked first two cells. A row the checks cannot read never goes
/// unnoticed.
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
  final tableLines = constitution
      .substring(begin, end)
      .split('\n')
      .where((line) => line.startsWith('|'))
      .toList();
  if (tableLines.length < 2 ||
      tableLines[0].contains('`') ||
      !_separator.hasMatch(tableLines[1])) {
    throw StateError('The "$name" table in constitution.md must start with a '
        'header row and its |---| separator.');
  }
  final rows = <String>{};
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

/// Declares the two tests that hold what [scan] finds to the
/// `constitution.md` table called [table], in [section]: every finding has a
/// row, and every row is still a finding. [fix] tells the reader what to do
/// about a finding instead of adding a row.
void testAgainstTable({
  required String section,
  required String table,
  required String scope,
  required Set<String> Function() scan,
  required String fix,
}) {
  late Set<String> found;
  late Set<String> listed;

  setUpAll(() {
    found = scan();
    listed =
        readExceptionTable(File('constitution.md').readAsStringSync(), table);
  });

  test('every finding in $scope has a row in constitution.md $section', () {
    final unlisted = found.difference(listed);

    expect(
      unlisted,
      isEmpty,
      reason: 'These break constitution.md $section and have no row in its '
          'table:\n${bulletList(unlisted)}\n'
          '$fix Adding a row instead is an amendment (Article IX).',
    );
  });

  test('every row in constitution.md $section is still found in $scope', () {
    final stale = listed.difference(found);

    expect(
      stale,
      isEmpty,
      reason: 'These rows of the constitution.md $section table no longer '
          'match $scope. Delete them:\n${bulletList(stale)}',
    );
  });
}
