import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/login/views/local_router_recovery_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/_index.dart';

// View ID: LRRV
// Implementation: lib/page/login/views/local_router_recovery_view.dart
// Summary:
// - LRRV-INIT: Default page layout with empty pin inputs and disabled CTA.
// - LRRV-PIN: User enters full recovery code, enabling Continue button.
// - LRRV-ERR_WARN: Warns user with remaining attempts > 1.
// - LRRV-ERR_LAST: Shows last-chance warning when only one attempt remains.
// - LRRV-ERR_LOCK: Locks user out when no attempts remain.

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  RouterPasswordState baseState() =>
      RouterPasswordState.fromMap(routerPasswordTestState1);

  // Test ID: LRRV-INIT
  testThemeLocalizations(
    'local router recovery view - initial layout',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build())
          .thenReturn(baseState());

      final context = await testHelper.pumpView(
        tester,
        child: const LocalRouterRecoveryView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      await tester.pumpAndSettle();
      final loc = testHelper.loc(context);

      expect(find.text(loc.forgotPassword), findsOneWidget);
      expect(find.text(loc.localRouterRecoveryDescription), findsOneWidget);
      expect(find.byType(AppPinInput), findsOneWidget);
      // Use specific widget+text finder to avoid multiple AppButtons from page chrome
      final continueButtonFinder =
          find.widgetWithText(AppButton, loc.textContinue);
      expect(continueButtonFinder, findsOneWidget);
      final continueButton = tester.widget<AppButton>(continueButtonFinder);
      expect(continueButton.onTap, isNull);
    },
    goldenFilename: 'LRRV-INIT_01_initial_state',
    helper: testHelper,
  );

  // Test ID: LRRV-PIN
  testThemeLocalizations(
    'local router recovery view - enter recovery code',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build())
          .thenReturn(baseState());

      final context = await testHelper.pumpView(
        tester,
        child: const LocalRouterRecoveryView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      await tester.pumpAndSettle();
      final loc = testHelper.loc(context);

      await tester.enterText(find.byType(AppPinInput), '11111');
      await tester.pumpAndSettle();

      // Use specific widget+text finder to avoid multiple AppButtons from page chrome
      final buttonFinder = find.widgetWithText(AppButton, loc.textContinue);
      expect(buttonFinder, findsOneWidget);
      final continueButton = tester.widget<AppButton>(buttonFinder);
      expect(continueButton.onTap, isNotNull);
    },
    goldenFilename: 'LRRV-PIN_01_code_entered',
    helper: testHelper,
  );

  // Test ID: LRRV-ERR_WARN
  testThemeLocalizations(
    'local router recovery view - warning with attempts remaining',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
        baseState().copyWith(remainingErrorAttempts: 2),
      );

      final context = await testHelper.pumpView(
        tester,
        child: const LocalRouterRecoveryView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      await tester.pumpAndSettle();
      final loc = testHelper.loc(context);

      final expectedMessage = [
        loc.localRouterRecoveryKeyErorr,
        loc.localLoginRemainingAttempts(2),
      ].join('\n');
      expect(find.text(expectedMessage), findsOneWidget);
    },
    goldenFilename: 'LRRV-ERR_WARN_01_attempts_remaining',
    helper: testHelper,
  );

  // Test ID: LRRV-ERR_LAST
  testThemeLocalizations(
    'local router recovery view - last chance warning',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
        baseState().copyWith(remainingErrorAttempts: 1),
      );

      final context = await testHelper.pumpView(
        tester,
        child: const LocalRouterRecoveryView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      await tester.pumpAndSettle();
      final loc = testHelper.loc(context);

      final expectedMessage = [
        loc.localRouterRecoveryKeyErorr,
        loc.localRouterRecoveryKeyLastChance,
      ].join('\n');
      expect(find.text(expectedMessage), findsOneWidget);
    },
    goldenFilename: 'LRRV-ERR_LAST_01_last_chance',
    helper: testHelper,
  );

  // Test ID: LRRV-ERR_LOCK
  testThemeLocalizations(
    'local router recovery view - locked out state',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
        baseState().copyWith(remainingErrorAttempts: 0),
      );

      final context = await testHelper.pumpView(
        tester,
        child: const LocalRouterRecoveryView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      await tester.pumpAndSettle();
      final loc = testHelper.loc(context);

      final expectedMessage = [
        loc.localRouterRecoveryKeyErorr,
        loc.localRouterRecoveryKeyLocked,
      ].join('\n');
      expect(find.text(expectedMessage), findsOneWidget);
    },
    goldenFilename: 'LRRV-ERR_LOCK_01_locked_state',
    helper: testHelper,
  );
}
