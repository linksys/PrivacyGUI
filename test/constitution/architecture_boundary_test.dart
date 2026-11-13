import 'boundary_scanner.dart';
import 'source_scan.dart';

/// Holds `lib/` to `constitution.md` Article I: what the scanner finds must
/// equal the exception table in section 1.4, row for row.
void main() {
  testAgainstTable(
    section: '1.4',
    table: 'boundary-exceptions',
    scope: 'lib/',
    scan: () => findBoundaryViolations(dartSources('lib')),
    fix: "Move the call into the feature's notifier.",
  );
}
