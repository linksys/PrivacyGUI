// What a route's config decides (route_model.dart): whether the page shows
// the navigation rail (menu_holder.dart reads it), the column overlay's
// starting state, and when two configs are the same.
//
// Values compared with one built as const are built at run time: two equal
// const values are one instance, so == would hold whatever props says.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/route/route_model.dart';

void main() {
  late BuildContext context;

  Future<void> open(WidgetTester tester) =>
      tester.pumpWidget(Builder(builder: (built) {
        context = built;
        return const SizedBox();
      }));

  group('isShowNaviRail', () {
    testWidgets('shows the rail on a route with no config', (tester) async {
      await open(tester);

      expect(LinksysRoute.isShowNaviRail(context, null), isTrue);
    });

    testWidgets('hides it on a route that asks for no rail', (tester) async {
      await open(tester);

      expect(
          LinksysRoute.isShowNaviRail(
              context, const LinksysRouteConfig(noNaviRail: true)),
          isFalse);
    });

    testWidgets('shows it on a route that does not ask', (tester) async {
      await open(tester);

      expect(
          LinksysRoute.isShowNaviRail(context, const LinksysRouteConfig()),
          isTrue);
      expect(
          LinksysRoute.isShowNaviRail(
              context, const LinksysRouteConfig(noNaviRail: false)),
          isTrue);
    });
  });

  test('a default build starts with the column overlay off', () {
    expect(showColumnOverlayNotifier.value, isFalse);
  });

  group('LinksysRouteConfig', () {
    test('starts with no column, the rail as the route has it, and no flags',
        () {
      const config = LinksysRouteConfig();

      expect(config.column, isNull);
      expect(config.noNaviRail, isNull);
      expect(config.ignoreConnectivityEvent, isFalse);
      expect(config.ignoreCloudOfflineEvent, isFalse);
      expect(config.writeFlow, isFalse);
    });

    test('is equal to a config with the same values', () {
      final grid = ColumnGrid(column: 6, centered: true);

      expect(
          LinksysRouteConfig(column: grid, noNaviRail: true, writeFlow: true),
          LinksysRouteConfig(column: grid, noNaviRail: true, writeFlow: true));
      expect(LinksysRouteConfig(), const LinksysRouteConfig());
    });

    // Each route builds its own ColumnGrid, so equality must compare the
    // grid's values, not the instance.
    test('is equal to a config with the same column in a grid of its own', () {
      expect(LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
          LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)));
      expect(ColumnGrid(column: 6, centered: true),
          isNot(ColumnGrid(column: 6)));
      expect(ColumnGrid(column: 6), isNot(ColumnGrid(column: 9)));
    });

    test('differs from a config that differs in any value', () {
      final config = LinksysRouteConfig(noNaviRail: true);

      expect(config, isNot(LinksysRouteConfig(noNaviRail: false)));
      expect(config,
          isNot(LinksysRouteConfig(noNaviRail: true, writeFlow: true)));
      expect(
          config,
          isNot(LinksysRouteConfig(
              noNaviRail: true, ignoreConnectivityEvent: true)));
      expect(
          config,
          isNot(LinksysRouteConfig(
              noNaviRail: true, ignoreCloudOfflineEvent: true)));
      expect(
          config,
          isNot(LinksysRouteConfig(
              noNaviRail: true, column: ColumnGrid(column: 12))));
    });
  });
}
