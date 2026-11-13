import 'package:test/test.dart';

import 'screenshot_scanner.dart';

void main() {
  test('a golden check outside testLocalizations is a violation', () {
    final violations = findScreenshotTestViolations({
      'test/page/foo/views/foo_view_test.dart':
          "await expectLater(find.byType(FooView), matchesGoldenFile('foo.png'));\n",
    });

    expect(violations, {
      'test/page/foo/views/foo_view_test.dart -> matchesGoldenFile',
    });
  });

  for (final call in ['screenMatchesGolden', 'multiScreenGolden']) {
    test('a golden_toolkit $call check is a violation', () {
      final violations = findScreenshotTestViolations({
        'test/page/foo/views/foo_view_test.dart':
            "await $call(tester, 'foo');\n",
      });

      expect(violations, {'test/page/foo/views/foo_view_test.dart -> $call'});
    });
  }

  test(
      'a testLocalizations case outside a localizations/ directory is a '
      'violation', () {
    final violations = findScreenshotTestViolations({
      'test/page/foo/views/foo_view_test.dart':
          "testLocalizations('Foo view', (tester, locale) async {});\n",
    });

    expect(violations, {
      'test/page/foo/views/foo_view_test.dart -> testLocalizations',
    });
  });

  test('a testLocalizations case under localizations/ is not a violation', () {
    final violations = findScreenshotTestViolations({
      'test/page/foo/views/localizations/foo_view_test.dart':
          "testLocalizations('Foo view', (tester, locale) async {});\n",
    });

    expect(violations, isEmpty);
  });

  test('commented-out calls are not violations', () {
    final violations = findScreenshotTestViolations({
      'test/page/foo/views/foo_view_test.dart':
          "    // testLocalizations('Foo view', (tester, locale) async {});\n"
              '/// Compared with [matchesGoldenFile] by the localizations/ tests.\n',
    });

    expect(violations, isEmpty);
  });

  test('the helper that defines testLocalizations is not a violation', () {
    final violations = findScreenshotTestViolations({
      'test/common/test_responsive_widget.dart':
          'void testLocalizations(String name) {}\n'
              "final matcher = matchesGoldenFile('goldens/foo.png');\n",
    });

    expect(violations, isEmpty);
  });
}
