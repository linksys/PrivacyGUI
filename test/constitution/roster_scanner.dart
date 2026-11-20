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

/// The screenshot suites in [test]: the files that call `testLocalizations`,
/// as `package:analyzer` sees it, other than [testLocalizationsHelper]. The
/// roster, the layout gate's pre-push hook, and the check on CI's suite
/// selection all count suites this way.
Set<String> screenshotSuites(Map<String, String> test) => {
      for (final MapEntry(key: path, value: source) in test.entries)
        if (path != testLocalizationsHelper &&
            namesIn(parseDart(source)).contains('testLocalizations'))
          path,
    };

/// The pages in [lib] that no screenshot suite in [test] constructs, as
/// `<page file> -> <page class>`, the way constitution 3.3's table lists them.
///
/// A suite is one of [screenshotSuites]. A page counts only where a suite
/// constructs its class: a page
/// that a suite reaches as a parent's tab is not laid out unless that tab is
/// selected, so it is not covered. A page file without a public widget class
/// reads `<page file> -> ?`.
Set<String> findUncoveredPages(
    Map<String, String> lib, Map<String, String> test) {
  final constructed = {
    for (final suite in screenshotSuites(test))
      ...constructedNamesIn(test[suite]!),
  };
  return {
    for (final page in rosterPages(lib.keys))
      if (pageClassIn(page, lib[page]!) case final pageClass)
        if (pageClass == null || !constructed.contains(pageClass))
          '$page -> ${pageClass ?? '?'}',
  };
}

/// The public classes that [source] declares.
Set<String> declaredClassesIn(String source) => {
      for (final declaration in parseDart(source).declarations)
        if (declaration is ClassDeclaration &&
            !declaration.name.lexeme.startsWith('_'))
          declaration.name.lexeme,
    };

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

  // A tear-off, `AView.new`: unresolved, it parses as a prefixed identifier.
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'new' && _capitalised(node.prefix.name)) {
      names.add(node.prefix.name);
    }
    super.visitPrefixedIdentifier(node);
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

/// What a roster row says of a page that nothing in `lib/` builds.
const unreachableReason = 'nothing in `lib/` builds it';

/// The rows of the 3.3 roster in [constitution] whose reason says that
/// nothing in `lib/` builds the page, but whose class a file in [lib] other
/// than the page's own constructs, as `<page> -> <Class>`. Such a page is
/// reachable now and needs a case.
Set<String> builtUnreachablePages(
    String constitution, Map<String, String> lib) {
  final unreachable = {
    for (final row in readExceptionRows(constitution, 'layout-gate-roster'))
      if (row.rest.contains(unreachableReason)) row.from: row.to,
  };
  final built = {
    for (final MapEntry(key: path, value: source) in lib.entries)
      for (final name in constructedNamesIn(source)) (path, name),
  };
  return {
    for (final MapEntry(key: page, value: pageClass) in unreachable.entries)
      if (built.any((b) => b.$2 == pageClass && b.$1 != page))
        '$page -> $pageClass',
  };
}

/// What a roster row says of a page whose route nothing navigates to; the
/// route's name follows in backticks.
const unreachableRouteReason = 'nothing navigates to its route';

/// The rows of the 3.3 roster in [constitution] whose reason says that
/// nothing navigates to the page's route, but whose route a file in [lib]
/// outside `lib/route/` names, as `<page> -> <Class>`. Such a page can be
/// opened now and needs a case.
Set<String> navigatedUnreachablePages(
    String constitution, Map<String, String> lib) {
  final routeIn = RegExp('$unreachableRouteReason, `(\\w+)`');
  final named = {
    for (final MapEntry(key: path, value: source) in lib.entries)
      if (!path.startsWith('lib/route/')) ...routesNamedIn(source),
  };
  return {
    for (final row in readExceptionRows(constitution, 'layout-gate-roster'))
      if (routeIn.firstMatch(row.rest) case final match?)
        if (named.contains(match.group(1))) '${row.from} -> ${row.to}',
  };
}

/// The routes [source] names as `RouteNamed.<route>` or `RoutePath.<route>`.
Set<String> routesNamedIn(String source) {
  final names = <String>{};
  parseDart(source).accept(_RouteCollector(names));
  return names;
}

class _RouteCollector extends RecursiveAstVisitor<void> {
  _RouteCollector(this.names);

  final Set<String> names;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (const {'RouteNamed', 'RoutePath'}.contains(node.prefix.name)) {
      names.add(node.identifier.name);
    }
    super.visitPrefixedIdentifier(node);
  }
}
