import 'package:test/test.dart';

import 'roster_scanner.dart';

void main() {
  group('rosterPages', () {
    test('takes every *_view.dart under lib/page, and the five 5.1 pages', () {
      final pages = rosterPages([
        'lib/page/wifi_settings/views/wifi_list_view.dart',
        'lib/page/wifi_settings/views/widgets/wifi_card.dart',
        'lib/page/wifi_settings/views/_views.dart',
        'lib/page/vpn/views/vpn_settings_page.dart',
        'lib/page/health_check/views/speed_test_selection.dart',
        'lib/core/some_view.dart',
      ]);

      expect(pages, {
        'lib/page/wifi_settings/views/wifi_list_view.dart',
        'lib/page/vpn/views/vpn_settings_page.dart',
        'lib/page/health_check/views/speed_test_selection.dart',
      });
    });
  });

  group('pageClassIn', () {
    test('picks the class named after the file, whatever its case', () {
      const source = '''
class WifiCard extends StatelessWidget {}
class WiFiListView extends ArgumentsConsumerStatefulView {}
class _WiFiListViewState extends ConsumerState<WiFiListView> {}
''';

      expect(
          pageClassIn(
              'lib/page/wifi_settings/views/wifi_list_view.dart', source),
          'WiFiListView');
    });

    test('falls back to the first public widget class', () {
      const source = '''
mixin VpnHelpers {}
class _Helper extends StatelessWidget {}
class VPNSettingsPage extends ArgumentsConsumerStatefulView {}
''';

      expect(pageClassIn('lib/page/vpn/views/vpn_settings_page.dart', source),
          'VPNSettingsPage');
    });

    test('gives null for a file that defines no public widget', () {
      expect(
          pageClassIn('lib/page/a/a_view.dart', 'enum AView { one }'), isNull);
    });
  });

  group('screenshotSuites', () {
    test('takes the files that call testLocalizations, but not its own file',
        () {
      final suites = screenshotSuites({
        'test/page/a/localizations/a_view_test.dart':
            "void main() { testLocalizations('A', (t, l) async {}); }",
        'test/page/b/localizations/b_view_test.dart':
            "void main() async { await testLocalizations('B', (t, l) async {}); }",
        'test/page/c/views/c_view_test.dart':
            "void main() { testWidgets('C', (t) async {}); }",
        'test/common/test_responsive_widget.dart':
            'void testLocalizations(String name, Function body) {}',
      });

      expect(suites, {
        'test/page/a/localizations/a_view_test.dart',
        'test/page/b/localizations/b_view_test.dart',
      });
    });
  });

  group('findUncoveredPages', () {
    test('lists each page no testLocalizations suite constructs', () {
      final lib = {
        'lib/page/a/views/a_view.dart':
            'class AView extends StatelessWidget {}',
        'lib/page/b/views/b_view.dart':
            'class BView extends StatelessWidget {}',
        'lib/page/c/views/c_view.dart':
            'class CView extends StatelessWidget {}',
        'lib/page/c/views/widgets/c_card.dart':
            'class CCard extends StatelessWidget {}',
      };
      final test = {
        // A suite that constructs A, and only finds C.
        'test/page/a/localizations/a_view_test.dart': '''
void main() {
  testLocalizations('A', (tester, locale) async {
    await tester.pumpWidget(const AView());
    expect(find.byType(CView), findsNothing);
  });
}
''',
        // A unit test, not a screenshot case, that constructs B.
        'test/page/b/views/b_view_test.dart': '''
void main() {
  testWidgets('B', (tester) async => tester.pumpWidget(BView()));
}
''',
      };

      expect(findUncoveredPages(lib, test), {
        'lib/page/b/views/b_view.dart -> BView',
        'lib/page/c/views/c_view.dart -> CView',
      });
    });
  });

  group('declaredClassesIn', () {
    test('lists the public classes a file declares', () {
      const source = '''
class FaqListView extends ConsumerWidget {}
class _FaqListViewState {}
class FaqItem extends StatelessWidget {}
mixin FaqMixin {}
''';

      expect(declaredClassesIn(source), {'FaqListView', 'FaqItem'});
    });
  });

  group('constructedNamesIn', () {
    test('counts a constructor tear-off as building the class', () {
      // A route can be given AView.new instead of a closure that calls it.
      expect(constructedNamesIn('final build = AView.new;'), contains('AView'));
    });

    test('finds the classes a source constructs, by any form of creation', () {
      const source = '''
void main() {
  pump(const DashboardMenuView());
  pump(NodeDetailView(args: {}));
  pump(SpeedTestView.withRouter());
  pump(new VPNSettingsPage());
  final finder = find.byType(WiFiListView);
  helper();
}
''';

      expect(
          constructedNamesIn(source),
          containsAll([
            'DashboardMenuView',
            'NodeDetailView',
            'SpeedTestView',
            'VPNSettingsPage'
          ]));
      expect(constructedNamesIn(source), isNot(contains('WiFiListView')));
      expect(constructedNamesIn(source), isNot(contains('helper')));
    });
  });

  group('builtUnreachablePages', () {
    const constitution = """
<!-- layout-gate-roster:begin -->
| Page | Class | Why |
|---|---|---|
| `lib/page/a/a_view.dart` | `AView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/b/b_view.dart` | `BView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/c/c_view.dart` | `CView` | Permanent: a component, not a page. |
<!-- layout-gate-roster:end -->
""";

    test('fails on a roster without its markers, as the other tables do', () {
      expect(() => builtUnreachablePages('No roster here.', const {}),
          throwsStateError);
    });

    test('lists an unreachable page that another file in lib/ constructs', () {
      final lib = {
        'lib/page/a/a_view.dart': 'class AView {} final self = AView();',
        'lib/page/b/b_view.dart': 'class BView {}',
        'lib/page/c/c_view.dart': 'class CView {}',
        // Builds AView, names BView only in a comment, and builds CView, whose
        // row gives another reason.
        'lib/route/routes.dart':
            'final a = AView(); /// [BView] is not built. final c = CView();',
      };

      expect(builtUnreachablePages(constitution, lib),
          {'lib/page/a/a_view.dart -> AView'});
    });
  });

  group('navigatedUnreachablePages', () {
    const constitution = """
<!-- layout-gate-roster:begin -->
| Page | Class | Why |
|---|---|---|
| `lib/page/e/e_view.dart` | `EView` | Permanent while unreachable: nothing navigates to its route, `eRoute`, and opened without the route's arguments it throws. |
| `lib/page/f/f_view.dart` | `FView` | Permanent while unreachable: nothing navigates to its route, `fRoute`, and opened without the route's arguments it throws. |
<!-- layout-gate-roster:end -->
""";

    test('lists a page whose route something outside lib/route/ names', () {
      final lib = {
        // The route table names both routes; that is not navigating.
        'lib/route/routes.dart': 'final e = LinksysRoute(name: RouteNamed.eRoute, '
            'path: RoutePath.eRoute); final f = RouteNamed.fRoute;',
        // Navigates to eRoute. fRoute is only in a comment.
        'lib/page/x/x_view.dart': 'void go(c) => c.pushNamed(RouteNamed.eRoute);'
            ' // c.pushNamed(RouteNamed.fRoute);',
      };

      expect(navigatedUnreachablePages(constitution, lib),
          {'lib/page/e/e_view.dart -> EView'});
    });
  });
}
