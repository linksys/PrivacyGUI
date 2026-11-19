/// Finds #1802's roster (constitution 3.3): the pages under `lib/page`, and
/// the classes that the screenshot cases construct.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'source_scan.dart';

/// The routed pages that constitution 5.1 lists as exceptions to the
/// `*_view.dart` suffix. The roster finds pages by that suffix, so these five
/// would escape it otherwise.
const Set<String> pagesNamedOtherwise = {
  'lib/page/vpn/views/vpn_settings_page.dart',
  'lib/page/otp_flow/views/otp_add_phone.dart',
  'lib/page/otp_flow/views/otp_code_input.dart',
  'lib/page/health_check/views/speed_test_external.dart',
  'lib/page/health_check/views/speed_test_selection.dart',
};

/// The pages among [paths]: every `lib/page/**/*_view.dart`, and
/// [pagesNamedOtherwise].
Set<String> rosterPages(Iterable<String> paths) => {
      for (final path in paths)
        if ((path.startsWith('lib/page/') && path.endsWith('_view.dart')) ||
            pagesNamedOtherwise.contains(path))
          path,
    };

/// The page's widget class in the file at [path]: the public class named after
/// the file, compared without case or underscores, or else the first public
/// class that extends a widget. Null when the file defines no public widget.
String? pageClassIn(String path, String source) {
  final classes = [
    for (final declaration in parseDart(source).declarations)
      if (declaration is ClassDeclaration &&
          !declaration.name.lexeme.startsWith('_'))
        declaration,
  ];
  final file = path.split('/').last.replaceAll('.dart', '');
  final key = file.replaceAll('_', '').toLowerCase();
  for (final c in classes) {
    if (c.name.lexeme.toLowerCase() == key) return c.name.lexeme;
  }
  for (final c in classes) {
    final superclass = c.extendsClause?.superclass.name2.lexeme;
    if (superclass != null &&
        (superclass.endsWith('Widget') || superclass.endsWith('View'))) {
      return c.name.lexeme;
    }
  }
  return null;
}

/// The pages in [lib] that no screenshot suite in [test] constructs, as
/// `<page file> -> <page class>`, the way constitution 3.3's table lists them.
///
/// A suite is a file that calls `testLocalizations`, other than the file that
/// defines it. A page counts only where a suite constructs its class: a page
/// that a suite reaches as a parent's tab is not laid out unless that tab is
/// selected, so it is not covered. A page file without a public widget class
/// reads `<page file> -> ?`.
Set<String> findUncoveredPages(
    Map<String, String> lib, Map<String, String> test) {
  final constructed = <String>{};
  test.forEach((path, source) {
    if (path == 'test/common/test_responsive_widget.dart') return;
    if (!namesIn(parseDart(source)).contains('testLocalizations')) return;
    constructed.addAll(constructedNamesIn(source));
  });
  return {
    for (final page in rosterPages(lib.keys))
      if (pageClassIn(page, lib[page]!) case final pageClass)
        if (pageClass == null || !constructed.contains(pageClass))
          '$page -> ${pageClass ?? '?'}',
  };
}

/// The classes that [source] constructs: `A()`, `const A()`, `new A()` and
/// `A.named()`. Without type resolution `A()` parses as a call, so a call to
/// a capitalised name counts; a type named only as a value, as in
/// `find.byType(A)`, does not.
Set<String> constructedNamesIn(String source) {
  final names = <String>{};
  parseDart(source).accept(_ConstructionCollector(names));
  return names;
}

class _ConstructionCollector extends RecursiveAstVisitor<void> {
  _ConstructionCollector(this.names);

  final Set<String> names;

  static bool _capitalised(String name) =>
      name.isNotEmpty && name[0].toUpperCase() == name[0] && name[0] != '_';

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    names.add(node.constructorName.type.name2.lexeme);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target == null && _capitalised(node.methodName.name)) {
      names.add(node.methodName.name);
    } else if (target is SimpleIdentifier && _capitalised(target.name)) {
      names.add(target.name);
    }
    super.visitMethodInvocation(node);
  }
}
