import 'screenshot_scanner.dart';
import 'source_scan.dart';

/// Holds `test/` to `constitution.md` 3.5: golden checks stay in the body of
/// `testLocalizations`, and its cases stay in `localizations/` directories,
/// except for the rows of the table in 3.5.
void main() {
  testAgainstTable(
    section: '3.5',
    table: 'screenshot-exceptions',
    scope: 'test/',
    scan: () => findScreenshotTestViolations(dartSources('test')),
    fix: 'Write the golden check as a testLocalizations case, in a '
        'localizations/ directory.',
  );
}
