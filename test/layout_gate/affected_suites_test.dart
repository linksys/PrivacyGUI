import 'package:test/test.dart';

import 'affected_suites.dart';

void main() {
  const wifi = 'test/page/wifi_settings/views/localizations/wifi_main_view_test.dart';
  const nodes = 'test/page/nodes/localizations/node_detail_view_test.dart';
  const dashboard = 'test/page/dashboard/localizations/dashboard_home_view_test.dart';
  const suites = {wifi, nodes, dashboard};

  test('runs the suites of each feature whose pages or tests changed', () {
    expect(
      affectedGateSuites([
        'lib/page/wifi_settings/views/wifi_list_view.dart',
        'test/page/nodes/views/node_detail_view_test.dart',
      ], suites),
      {wifi, nodes},
    );
  });

  test('runs every suite when a part that every page lays out with changed', () {
    for (final shared in [
      'lib/page/components/styled/styled_page_view.dart',
      'plugins/widgets',
      'plugins/widgets/lib/widgets/page/base_page_view.dart',
      'lib/l10n/app_ja.arb',
      'test/common/config.dart',
      'test/layout_gate/gate.dart',
      'test/fonts/NotoSans-Regular.ttf',
      'test/test_data/wifi_list_test_state.dart',
      'assets/icons/linksys_icons.ttf',
    ]) {
      expect(affectedGateSuites([shared], suites), suites, reason: shared);
    }
  });

  test('runs nothing for a change that does not touch the UI', () {
    expect(
      affectedGateSuites([
        'lib/core/jnap/router_repository.dart',
        'lib/route/router_provider.dart',
        'README.md',
        'test/core/jnap/router_repository_test.dart',
      ], suites),
      isEmpty,
    );
  });

  test("runs the suites that construct a changed page, in another feature's "
      'directory too', () {
    // lib/page/support has no test/page/support: the dashboard suite is the
    // one that builds FaqListView.
    expect(
      affectedGateSuites(
        ['lib/page/support/faq_list_view.dart'],
        suites,
        declares: {
          'lib/page/support/faq_list_view.dart': {'FaqListView'},
        },
        constructs: {
          dashboard: {'DashboardHomeView', 'FaqListView'},
          wifi: {'WiFiMainView'},
        },
      ),
      {dashboard},
    );
  });

  test('does not take a path that only starts like a shared one', () {
    expect(affectedGateSuites(['plugins/widgets_old/readme.md'], suites),
        isEmpty);
  });
}
