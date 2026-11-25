// What a route's config decides (route_model.dart): whether the page shows
// the navigation rail (menu_holder.dart reads it), and the column overlay's
// starting state.

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
}
