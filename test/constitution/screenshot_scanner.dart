import 'package:analyzer/dart/ast/ast.dart';

import 'source_scan.dart';

/// Finds screenshot tests that break `constitution.md` 3.5.
///
/// [sources] maps repo-relative paths (`test/...`) to Dart source. Each
/// violation reads `<file> -> <call>`.
Set<String> findScreenshotTestViolations(Map<String, String> sources) {
  final violations = <String>{};
  sources.forEach((path, source) {
    final unit = parseDart(source);
    final names =
        path == _helper ? _namesOutsideTestLocalizations(unit) : namesIn(unit);
    for (final check in _goldenChecks) {
      if (names.contains(check)) violations.add('$path -> $check');
    }
    final directories = path.split('/')..removeLast();
    if (!directories.contains('localizations') &&
        names.contains('testLocalizations')) {
      violations.add('$path -> testLocalizations');
    }
  });
  return violations;
}

/// Defines `testLocalizations`, whose body is the one place a golden check is
/// made.
const _helper = 'test/common/test_responsive_widget.dart';

/// Flutter's golden matcher, and `golden_toolkit`'s two golden checks.
const _goldenChecks = [
  'matchesGoldenFile',
  'screenMatchesGolden',
  'multiScreenGolden',
];

Set<String> _namesOutsideTestLocalizations(CompilationUnit unit) => {
      for (final declaration in unit.declarations)
        if (declaration is! FunctionDeclaration ||
            declaration.name.lexeme != 'testLocalizations')
          ...namesIn(declaration),
    };
