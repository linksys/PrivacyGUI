import 'source_scan.dart';

/// Finds screenshot tests that break `constitution.md` 3.5.
///
/// [sources] maps repo-relative paths (`test/...`) to Dart source. Each
/// violation reads `<file> -> <call>`.
Set<String> findScreenshotTestViolations(Map<String, String> sources) {
  final violations = <String>{};
  sources.forEach((path, source) {
    if (path == _helper) return;
    final code = withoutLineStartComments(source);
    for (final check in _goldenCheck.allMatches(code)) {
      violations.add('$path -> ${check.group(1)}');
    }
    final directories = path.split('/')..removeLast();
    if (!directories.contains('localizations') &&
        _localizationsCase.hasMatch(code)) {
      violations.add('$path -> testLocalizations');
    }
  });
  return violations;
}

/// Defines `testLocalizations`, the one place a golden check is made.
const _helper = 'test/common/test_responsive_widget.dart';

/// Flutter's golden matcher, and `golden_toolkit`'s two golden checks.
final _goldenCheck =
    RegExp(r'\b(matchesGoldenFile|screenMatchesGolden|multiScreenGolden)\b');
final _localizationsCase = RegExp(r'\btestLocalizations\s*\(');
