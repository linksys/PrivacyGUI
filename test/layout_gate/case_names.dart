/// The names of the `testLocalizations` cases in a Dart source (#1802 P3).
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../constitution/source_scan.dart';

/// The name of each `testLocalizations` call in [source] that is a constant
/// string, adjacent strings included. A name built by interpolation cannot be
/// read here and is left out.
Set<String> caseNamesIn(String source) {
  final names = <String>{};
  parseDart(source).accept(_CaseNameCollector(names));
  return names;
}

class _CaseNameCollector extends RecursiveAstVisitor<void> {
  _CaseNameCollector(this.names);

  final Set<String> names;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == 'testLocalizations') {
      final first = node.argumentList.arguments.firstOrNull;
      if (first is StringLiteral && first.stringValue != null) {
        names.add(first.stringValue!);
      }
    }
    super.visitMethodInvocation(node);
  }
}
