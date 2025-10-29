import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/_index.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
  });

  testLocalizations('local reset router password view - init state',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const LocalResetRouterPasswordView(),
      config: LinksysRouteConfig(noNaviRail: true),
      locale: locale,
    );
  });

  testLocalizations('local reset router password view - input password masked',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const LocalResetRouterPasswordView(),
      config: LinksysRouteConfig(noNaviRail: true),
      locale: locale,
    );
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder.first, 'Linksys');
    await tester.pumpAndSettle();
  });

  testLocalizations('local reset router password view - input password visible',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const LocalResetRouterPasswordView(),
      config: LinksysRouteConfig(noNaviRail: true),
      locale: locale,
    );
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder.first, 'Linksys');
    await tester.pumpAndSettle();
    // Tap eye icon
    final secureIconFinder = find.byIcon(LinksysIcons.visibility);
    await tester.tap(secureIconFinder.first);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'local reset router password view - input password visible and hint',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const LocalResetRouterPasswordView(),
      config: LinksysRouteConfig(noNaviRail: true),
      locale: locale,
    );
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder.first, 'Linksys');
    await tester.enterText(passwordFinder.last, 'Linksys');
    await tester.pumpAndSettle();
    // Tap eye icon
    final secureIconFinder = find.byIcon(LinksysIcons.visibility);
    await tester.tap(secureIconFinder.first);
    await tester.pumpAndSettle();
    // Input hint
    final hintFinder = find.byType(AppTextField).last;
    await tester.enterText(hintFinder, 'Linksys');
    await tester.pumpAndSettle();
  });

  testLocalizations('local reset router password view - success prompt',
      (tester, locale) async {
    when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(isValid: true),
    );

    await testHelper.pumpView(
      tester,
      child: const LocalResetRouterPasswordView(),
      config: LinksysRouteConfig(noNaviRail: true),
      locale: locale,
    );
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder.first, 'Linksys123!');
    await tester.enterText(passwordFinder.last, 'Linksys123!');
    await tester.pumpAndSettle();
    // scroll until button visible
    final saveFinder = find.byType(AppFilledButton);
    await tester.scrollUntilVisible(saveFinder, 100,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    // Tap save
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();
  });
}