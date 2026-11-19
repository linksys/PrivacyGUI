import 'package:test/test.dart';

import '../../test_scripts/coverage_import_all.dart';
import '../../test_scripts/coverage_summary.dart';

/// Files as `flutter test --coverage` reports them: a provider with both
/// lines run, a view with neither, `main.dart`, generated l10n, and a file
/// with no line to run.
const _lcov = '''
SF:lib/page/wifi/providers/wifi_provider.dart
DA:1,1
DA:2,3
DA:2,0
end_of_record
SF:/home/runner/work/PrivacyGUI/lib/page/wifi/views/wifi_view.dart
DA:1,0
DA:2,0
end_of_record
SF:lib/main.dart
DA:1,1
end_of_record
SF:lib/l10n/gen/app_localizations.dart
DA:1,1
DA:2,1
end_of_record
SF:lib/constants/pref_key.dart
end_of_record
''';

void main() {
  group('classify', () {
    test('puts views, widgets and components in UI', () {
      expect(classify('page/wifi/views/wifi_list.dart'), Area.ui);
      expect(classify('page/components/styled/top_bar.dart'), Area.ui);
      expect(classify('core/widgets/spinner.dart'), Area.ui);
      expect(classify('page/login/login_view.dart'), Area.ui);
    });

    test('puts core, route, providers, models and utils in logic', () {
      expect(classify('core/jnap/router_repository.dart'), Area.logic);
      expect(classify('route/router_provider.dart'), Area.logic);
      expect(classify('providers/auth/auth_provider.dart'), Area.logic);
      expect(classify('utils/format.dart'), Area.logic);
      expect(classify('page/ddns/models/ddns.dart'), Area.logic);
      expect(classify('page/wifi/wifi_state.dart'), Area.logic);
    });

    test('checks UI first', () {
      expect(classify('core/views/model/tree_view_node.dart'), Area.ui);
    });

    test('leaves the rest out of both', () {
      expect(classify('main.dart'), Area.other);
      expect(classify('constants/build_config.dart'), Area.other);
    });
  });

  group('summarize', () {
    final summary = summarize(_lcov);

    test('counts each line once, at its highest hit count', () {
      expect(summary.all.lines, 5);
      expect(summary.all.covered, 3);
    });

    test('leaves out generated l10n, and files with no line to run', () {
      expect(summary.all.files, 3);
    });

    test('counts the files no test runs', () {
      expect(summary.all.untested, 1);
      expect(summary.ui.untested, 1);
      expect(summary.logic.untested, 0);
    });

    test('splits logic from UI', () {
      expect((summary.logic.lines, summary.logic.covered), (2, 2));
      expect((summary.ui.lines, summary.ui.covered), (2, 0));
      expect((summary.other.files, summary.other.lines), (1, 1));
    });
  });

  test('writes the table #1803 reports', () {
    final table = markdown(summarize(_lcov));

    expect(table, contains('| **All of `lib/`** | 5 | **60.0%** | 1 of 3 |'));
    expect(table, contains('| 2 | **100.0%** | 0 of 1 |'));
    expect(table, contains('| 2 | 0.0% | 1 of 1 |'));
    expect(table, contains('1 file (1 line) is in neither row.'));
    expect(table, isNot(contains('Warning')));
  });

  test('warns when the import-all helper did not run', () {
    final table = markdown(summarize(_lcov), helperRan: false);

    expect(table, contains('**Warning**'));
    expect(table, contains('reads high'));
  });

  group('helperRan', () {
    String start(int id, String name, String path) =>
        '{"test":{"id":$id,"name":"$name","url":"file:///repo/$path"},'
        '"type":"testStart"}';
    String done(int id, String result) =>
        '{"testID":$id,"result":"$result","type":"testDone"}';

    test('is true when the helper test passed', () {
      expect(
          helperRan([
            start(7, helperTestName, helperPath),
            done(7, 'success'),
          ].join('\n')),
          isTrue);
    });

    test('is false when the helper test failed or never started', () {
      expect(
          helperRan([
            start(7, helperTestName, helperPath),
            done(7, 'error'),
          ].join('\n')),
          isFalse);
      // A helper that does not compile reports only a failed load.
      expect(helperRan(done(1, 'error')), isFalse);
    });

    test('ignores a test of the same name in another file', () {
      expect(
          helperRan([
            start(7, helperTestName, 'test/other_test.dart'),
            done(7, 'success'),
          ].join('\n')),
          isFalse);
    });
  });

  test('writes thousands with a comma', () {
    expect(withCommas(38545), '38,545');
    expect(withCommas(999), '999');
  });
}
