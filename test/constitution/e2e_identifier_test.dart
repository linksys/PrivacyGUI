import 'identifier_scanner.dart';
import 'source_scan.dart';

/// Holds `lib/` to `constitution.md` Article XI: what the scanners find must
/// equal the tables in 11.1.3 and 11.2, file for file and count for count.
void main() {
  late final lib = dartSources('lib');
  late final hooks = findHookViolations(lib);
  late final labels = findLiteralSemanticLabels(lib);
  const countChanged = 'A file whose count changed is listed twice: here with '
      'its new count, and as a stale row with its old one. Lowering the count '
      'because you fixed calls is not an amendment.';

  testAgainstTable(
    section: '11.2',
    table: 'identifier-pages',
    scope: 'lib/page/',
    scan: () => countsByFile(hooks),
    explain: (unlisted) => describeFindings(hooks, unlisted),
    fix: 'Give each control an identifier (constitution 11.2, 11.3). '
        '$countChanged',
  );

  testAgainstTable(
    section: '11.1.3',
    table: 'semantic-label-literals',
    scope: 'lib/',
    scan: () => countsByFile(labels),
    explain: (unlisted) => describeFindings(labels, unlisted),
    fix: 'Take the screen-reader text from the ARB files, and the test hook '
        'from an identifier (constitution 11.1). $countChanged',
  );
}
