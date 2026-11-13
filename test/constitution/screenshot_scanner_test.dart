import 'package:test/test.dart';

import 'screenshot_scanner.dart';

const _helper = 'test/common/test_responsive_widget.dart';
const _viewTest = 'test/page/foo/views/foo_view_test.dart';

void main() {
  group('golden checks', () {
    test('a golden check outside testLocalizations is a violation', () {
      final violations = findScreenshotTestViolations({
        _viewTest: 'void main() async {\n'
            "  await expectLater(find.byType(FooView), matchesGoldenFile('foo.png'));\n"
            '}\n',
      });

      expect(violations, {'$_viewTest -> matchesGoldenFile'});
    });

    for (final call in ['screenMatchesGolden', 'multiScreenGolden']) {
      test('a golden_toolkit $call check is a violation', () {
        final violations = findScreenshotTestViolations({
          _viewTest: "void main() async {\n  await $call(tester, 'foo');\n}\n",
        });

        expect(violations, {'$_viewTest -> $call'});
      });
    }

    test('a golden check inside testLocalizations is not a violation', () {
      final violations = findScreenshotTestViolations({
        _helper: 'void testLocalizations(String name) {\n'
            "  expectLater(find.byType(Foo), matchesGoldenFile('goldens/\$name.png'));\n"
            '}\n',
      });

      expect(violations, isEmpty);
    });

    test('a golden check elsewhere in the helper file is a violation', () {
      final violations = findScreenshotTestViolations({
        _helper: 'void testLocalizations(String name) {}\n'
            '\n'
            'void testGolden(String name) {\n'
            "  expectLater(find.byType(Foo), matchesGoldenFile('goldens/\$name.png'));\n"
            '}\n',
      });

      expect(violations, {'$_helper -> matchesGoldenFile'});
    });
  });

  group('testLocalizations cases', () {
    test('a case outside a localizations/ directory is a violation', () {
      final violations = findScreenshotTestViolations({
        _viewTest: 'void main() {\n'
            "  testLocalizations('Foo view', (tester, locale) async {});\n"
            '}\n',
      });

      expect(violations, {'$_viewTest -> testLocalizations'});
    });

    test('a case under localizations/ is not a violation', () {
      final violations = findScreenshotTestViolations({
        'test/page/foo/views/localizations/foo_view_test.dart':
            'void main() {\n'
                "  testLocalizations('Foo view', (tester, locale) async {});\n"
                '}\n',
      });

      expect(violations, isEmpty);
    });
  });

  test('names in strings and comments are not violations', () {
    final violations = findScreenshotTestViolations({
      _viewTest: 'void main() {\n'
          "  // testLocalizations('Foo view', (tester, locale) async {});\n"
          "  print('matchesGoldenFile and testLocalizations(x)');\n"
          '}\n'
          '/// Compared with [matchesGoldenFile] by the localizations/ tests.\n'
          'class Foo {}\n',
    });

    expect(violations, isEmpty);
  });
}
