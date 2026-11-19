import 'package:test/test.dart';

import '../../test_scripts/coverage_import_all.dart';

/// The lib paths a helper imports, in the order it imports them.
List<String> _imported(String helper) => [
      for (final match in RegExp(r"import 'package:privacy_gui/(.+?)' as i\d+;")
          .allMatches(helper))
        match.group(1)!,
    ];

void main() {
  test('imports every lib file, in path order', () {
    final helper = importAllHelper({
      'lib/page/b.dart': 'class B {}',
      'lib/core/a.dart': 'class A {}',
      'lib/main.dart': 'void main() {}',
    });

    expect(_imported(helper), ['core/a.dart', 'main.dart', 'page/b.dart']);
  });

  test('leaves out generated l10n, part files and web-only files', () {
    final helper = importAllHelper({
      'lib/l10n/gen/app_localizations.dart': 'class AppLocalizations {}',
      'lib/core/model.g.dart': "part of 'model.dart';",
      'lib/core/html.dart': "import 'dart:html';",
      'lib/core/js.dart': "import 'dart:js_interop';",
      'lib/core/ui_web.dart': "import 'dart:ui_web' as ui_web;",
      'lib/core/web.dart': "import 'package:web/web.dart';",
      'lib/core/package_js.dart': "import 'package:js/js.dart';",
      'lib/core/browser.dart': "import 'package:http/browser_client.dart';",
      'lib/core/kept.dart': "import 'dart:io';",
    });

    expect(_imported(helper), ['core/kept.dart']);
  });

  test('keeps a file whose web import is only a conditional choice', () {
    final helper = importAllHelper({
      'lib/core/ip.dart': "import 'mobile_ip.dart'\n"
          "    if (dart.library.html) 'web_ip.dart';",
    });

    expect(_imported(helper), ['core/ip.dart']);
  });

  test('keeps a file that only mentions a web import in a comment', () {
    final helper = importAllHelper({
      'lib/core/note.dart': "// Not import 'dart:html', which the VM lacks.",
    });

    expect(_imported(helper), ['core/note.dart']);
  });

  test('goes where the suite runs it, apart from the script tests', () {
    expect(helperPath, 'test/import_all_for_coverage_test.dart');
  });

  test('is a test file the suite runs, and says not to commit it', () {
    final helper = importAllHelper({'lib/main.dart': ''});

    expect(helper, contains('Do not commit'));
    expect(helper, contains('// ignore_for_file: unused_import'));
    expect(
        helper, contains("import 'package:flutter_test/flutter_test.dart';"));
    expect(helper, contains("test('$helperTestName'"));
  });
}
