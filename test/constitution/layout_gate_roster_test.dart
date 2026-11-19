import 'dart:io';

import 'package:test/test.dart';

import 'roster_scanner.dart';
import 'source_scan.dart';

/// Holds `lib/page` to `constitution.md` 3.3: every page has a case in #1802's
/// layout gate, a `testLocalizations` suite that constructs it, except for
/// the rows of the table in 3.3.
void main() {
  testAgainstTable(
    section: '3.3',
    table: 'layout-gate-roster',
    scope: 'lib/page',
    scan: () => findUncoveredPages(dartSources('lib'), dartSources('test')),
    fix: "Give the page a testLocalizations case that constructs it, in the "
        "feature's localizations/ directory (constitution 3.5).",
  );

  test('the roster takes the pages constitution 5.1 names without the suffix',
      () {
    final rule = File('constitution.md')
        .readAsLinesSync()
        .singleWhere((line) => line.startsWith('- A page is `*_view.dart`.'));
    final named = {
      for (final m in RegExp(r'`(lib/page/[^`]+\.dart)`').allMatches(rule))
        m.group(1)!,
    };

    expect(pagesNamedOtherwise, named,
        reason: 'pagesNamedOtherwise in roster_scanner.dart has to list the '
            'pages that constitution 5.1 names.');
    for (final page in pagesNamedOtherwise) {
      expect(File(page).existsSync(), isTrue, reason: '$page is gone.');
    }
  });
}
