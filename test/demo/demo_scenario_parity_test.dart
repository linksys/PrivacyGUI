import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';

/// [kDemoScenarios] against the scenario files the E2E export actually writes.
///
/// The allowlist's own doc comment says it "must match" the export, and for a
/// while it did not — in both directions, silently. The E2E table had grown to 15
/// scenarios while the app listed 9, so eight exported files were unreachable:
/// the picker did not offer them and `applyScenario` refused them by name. Both
/// mesh shapes were in that eight, which is why a topology with an extender could
/// not be shown in demo mode at all. In the other direction `dmz-enabled` had been
/// renamed `dmz-on` upstream, leaving the app offering a name whose file 404s.
///
/// Neither failure announces itself: an unknown name logs and falls back, a
/// missing file logs and falls back. Prose in a doc comment cannot fail, so this
/// does.
///
/// **Skipped when `web/data/` is absent, which is the normal state.** The
/// directory is gitignored and per-worktree — it exists only where someone has run
/// `npx tsx scripts/export-demo-data.mts <worktree>/web/data` from the e2e repo. A
/// hard failure here would red the suite on every checkout that has not, which
/// would teach people to ignore it. Where the export *has* been run, the
/// comparison is exact.
void main() {
  group('kDemoScenarios matches the exported scenario files', () {
    final dataDir = Directory('web/data');

    late Set<String> exported;

    setUpAll(() {
      exported = dataDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.startsWith('scenario-') && n.endsWith('.json'))
          .map(
              (n) => n.substring('scenario-'.length, n.length - '.json'.length))
          .toSet();
    });

    test('every exported file is reachable from the app', () {
      final listed = kDemoScenarios.toSet();
      final unreachable = exported.difference(listed);

      expect(
        unreachable,
        isEmpty,
        reason:
            'these scenario files are exported but not in kDemoScenarios, so '
            'the picker never offers them and applyScenario refuses them by '
            'name — add them to the list, or stop exporting them',
      );
    });

    test('every listed name has a file to fetch', () {
      // `populated` is the clean base and has no override file by design.
      final listed = kDemoScenarios.where((n) => n != 'populated').toSet();
      final missing = listed.difference(exported);

      expect(
        missing,
        isEmpty,
        reason:
            'these names are offered by the app but no scenario file exists, '
            'so choosing one 404s and silently falls back to the base — most '
            'likely the scenario was renamed upstream',
      );
    });

    test('populated is offered, and is the only name without a file', () {
      expect(kDemoScenarios, contains('populated'));
      expect(exported, isNot(contains('populated')));
    });
  },
      skip: !Directory('web/data').existsSync()
          ? 'web/data/ is absent — run the e2e export for this worktree to enable'
          : null);
}
