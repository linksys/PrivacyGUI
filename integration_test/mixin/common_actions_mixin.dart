import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/app_bar/app_bar.dart';
import 'package:privacygui_widgets/widgets/page/base_page_view.dart';

import '../actions/base_actions.dart';

mixin CommonActionsMixin on BaseActions {
  Future<void> tapBackButton() async {
    // Find back button
    final backButtonFinder = find.descendant(
      of: find.byType(LinksysAppBar),
      matching: find.byIcon(LinksysIcons.arrowBack),
    );
    expect(backButtonFinder, findsOneWidget);
    // Tap the back button
    await scrollAndTap(backButtonFinder);
  }

  Future<void> scrollUntil(Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollAndTap(Finder finder) async {
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> checkTitle(String title) async {
    final titleFinder = find.text(title);
    expect(titleFinder, findsWidgets);
    await tester.pumpAndSettle();
  }

  BuildContext getContext() {
    final finder = find.byType(AppPageView).first;
    expect(finder, findsOneWidget);
    return tester.element(finder);
  }

}
