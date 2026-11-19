import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../constitution/roster_scanner.dart';
import '../constitution/source_scan.dart';
import 'gate.dart';

/// Holds `.github/workflows/ci-1x.yml`'s layout gate to the gate's own lists
/// (#1802 P3): the locales it runs, and the suites it picks.
void main() {
  final workflow = File('.github/workflows/ci-1x.yml').readAsStringSync();

  group('the locale matrix', () {
    final matrix = RegExp(r"""locale: \$\{\{ fromJSON\(github\.base_ref == 'main' && '(\[[^']*\])' \|\| '(\[[^']*\])'\) \}\}""")
        .firstMatch(workflow);

    test('is written the way this test reads it', () {
      expect(matrix, isNotNull,
          reason: 'ci-1x.yml has to choose the gate locales with '
              "fromJSON(github.base_ref == 'main' && '[...]' || '[...]').");
    });

    test('runs every gate locale on a PR into main', () {
      expect(jsonDecode(matrix!.group(1)!), gateLocales);
    });

    test('runs en only on any other PR', () {
      // #1802, Decision 4: a PR's wait stays short.
      expect(jsonDecode(matrix!.group(2)!), ['en']);
    });
  });

  test('picks every screenshot suite', () {
    // The job selects suites with this git grep; the roster counts a suite
    // from the code. A suite the grep misses would count as covered and
    // never run in CI.
    const grep = r"git grep -l -E '^[[:space:]]*testLocalizations\(' -- test";
    expect(workflow, contains(grep));

    final picked = RegExp(r'^[ \t]*testLocalizations\(', multiLine: true);
    final sources = dartSources('test');
    final missed = {
      for (final suite in screenshotSuites(sources))
        if (!picked.hasMatch(sources[suite]!)) suite,
    };

    expect(missed, isEmpty,
        reason: "ci-1x.yml's git grep misses these suites. Call "
            'testLocalizations at the start of a line:\n${bulletList(missed)}');
  });
}
