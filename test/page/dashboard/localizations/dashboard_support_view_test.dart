import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/support/faq_list_view.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() async {
  mockDependencyRegister();

  Widget testableWidget(Locale locale) => testableRouteShellWidget(
        child: const FaqListView(),
        locale: locale,
        overrides: [],
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testLocalizations('Dashboard Support View - default', (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

  testLocalizations('Dashboard Support View - expended',
      (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
    final expansionCardFinder =
        find.byType(AppExpansionCard, skipOffstage: false);
    await tester.tap(expansionCardFinder.first);
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(1));
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(2));
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(3));
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(4));
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1600)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1440)).toList()
  ]);
}
