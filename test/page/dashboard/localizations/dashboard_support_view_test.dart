import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/support/faq_list_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/config.dart';
import '../../../common/screen.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

// View ID: DSUP
// Implementation: lib/page/support/faq_list_view.dart
//
// | Test ID        | Description                                           |
// | :------------- | :---------------------------------------------------- |
// | `DSUP-DESKTOP` | Default desktop view renders FAQ headers and CTA.     |
// | `DSUP-MOBILE`  | Mobile view toggles menu to reveal CTA text.          |
// | `DSUP-EXPAND`  | Expands every category to reveal FAQ entries.         |

final _expandedScreens = [
  ...responsiveMobileScreens.map(
    (screen) => screen.copyWith(height: 1900),
  ),
  ...responsiveDesktopScreens.map(
    (screen) => screen.copyWith(height: 1740),
  ),
];

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  Future<BuildContext> pumpFaq(WidgetTester tester, LocalizedScreen screen) {
    return testHelper.pumpShellView(
      tester,
      child: const FaqListView(),
      locale: screen.locale,
    );
  }

  Future<void> expandAllCategories(WidgetTester tester) async {
    final finder = find.byType(AppExpansionPanel, skipOffstage: false);
    for (var i = 0; i < finder.evaluate().length; i++) {
      await tester.tap(finder.at(i));
      await tester.pumpAndSettle();
    }
  }

  // Test ID: DSUP-DESKTOP
  // Desktop screens (>905px) should show sidebar with menu content directly visible.
  testThemeLocalizations(
    'dashboard support view - default desktop layout',
    (tester, screen) async {
      final context = await pumpFaq(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.faqs), findsOneWidget);
      expect(find.text(loc.faqLookingFor), findsOneWidget);
      expect(find.text(loc.faqVisitLinksysSupport), findsOneWidget);
      expect(find.byType(AppExpansionPanel), findsNWidgets(5));
    },
    screens: [device1080w, device1280w, device1440w],
    goldenFilename: 'DSUP-DESKTOP_01_base',
    helper: testHelper,
  );

  // Test ID: DSUP-MOBILE
  testThemeLocalizations(
    'dashboard support view - default mobile layout',
    (tester, screen) async {
      final context = await pumpFaq(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.faqs), findsOneWidget);
      expect(find.byType(AppExpansionPanel), findsNWidgets(5));
      await testHelper.takeScreenshot(
        tester,
        'DSUP-MOBILE_01_base',
      );
      final menuButton = find.byType(AppIconButton);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      expect(find.text(loc.faqLookingFor), findsOneWidget);
      expect(find.text(loc.faqVisitLinksysSupport), findsOneWidget);
    },
    screens: responsiveMobileScreens,
    goldenFilename: 'DSUP-MOBILE_02_menu',
    helper: testHelper,
  );

  // Test ID: DSUP-TABLET
  // Tablet (744w) falls in tablet breakpoint (600-905px), sidebar should NOT display.
  // Behavior should match mobile: menu must be triggered via AppIconButton.
  testThemeLocalizations(
    'dashboard support view - tablet layout (no sidebar)',
    (tester, screen) async {
      final context = await pumpFaq(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.faqs), findsOneWidget);
      expect(find.byType(AppExpansionPanel), findsNWidgets(5));

      // On tablet, sidebar should NOT be visible - must tap menu button
      final menuButton = find.byType(AppIconButton);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      expect(find.text(loc.faqLookingFor), findsOneWidget);
      expect(find.text(loc.faqVisitLinksysSupport), findsOneWidget);
    },
    screens: [device744w],
    goldenFilename: 'DSUP-TABLET_01_menu',
    helper: testHelper,
  );

  // Test ID: DSUP-EXPAND
  testThemeLocalizations(
    'dashboard support view - expanded all categories',
    (tester, screen) async {
      final context = await pumpFaq(tester, screen);
      final loc = testHelper.loc(context);

      await expandAllCategories(tester);
      expect(find.text(loc.faqListCannotAddChildNode), findsOneWidget);
      expect(find.text(loc.faqListWhatLightsMean), findsOneWidget);
    },
    screens: _expandedScreens,
    goldenFilename: 'DSUP-EXPAND_01_all_open',
    helper: testHelper,
  );
}
