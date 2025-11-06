import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/support/faq_list_view.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });
  testLocalizations('Dashboard Support View - default', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const FaqListView(),
      locale: locale,
    );
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

  testLocalizations('Dashboard Support View - expended',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const FaqListView(),
      locale: locale,
    );
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