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
}
