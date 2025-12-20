import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/device_info_test_data.dart';

// View ID: LGLV
// Implementation: lib/page/login/views/login_local_view.dart
// Summary:
// - LGLV-INIT: Verifies default login form state shows required controls and disabled CTA.
// - LGLV-PASS: Covers password typing, visibility toggle, and hint expansion interactions.
// - LGLV-ERR_COUNTDOWN: Shows countdown error message when attempts remain with delay.
// - LGLV-ERR_LOCKED: Shows lockout error when no attempts remain.
// - LGLV-ERR_GENERIC: Falls back to generic error when auth status omits attempts.

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();

    when(testHelper.mockDashboardManagerNotifier.checkDeviceInfo(null))
        .thenAnswer(
      (_) async =>
          NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
    );
    when(testHelper.mockAuthNotifier.build()).thenAnswer(
      (_) async => Future.value(
        AuthState.empty().copyWith(localPasswordHint: 'Linksys'),
      ),
    );
    when(testHelper.mockAuthNotifier.getPasswordHint())
        .thenAnswer((_) async {});
    when(testHelper.mockAuthNotifier.getAdminPasswordAuthStatus(any))
        .thenAnswer((_) async => null);
  });

  // Test ID: LGLV-INIT
  testLocalizationsV2(
    'login local view - default layout',
    (tester, screen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const LoginLocalView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      final loc = testHelper.loc(context);

      await tester.pumpAndSettle();
      expect(find.text(loc.login), findsWidgets);
      expect(find.byType(AppPasswordInput), findsOneWidget);
      expect(find.text(loc.forgotPassword), findsOneWidget);
      // After UI Kit migration, there are multiple AppButtons (forgot password + login)
      // Use specific widget+text finder for login button
      final loginButtonFinder =
          find.byKey(const Key('loginLocalView_loginButton'));
      expect(loginButtonFinder, findsOneWidget);
      final loginButton = tester.widget<AppButton>(loginButtonFinder);
      expect(loginButton.onTap, isNull);
    },
    goldenFilename: 'LGLV-INIT_01_initial_state',
    helper: testHelper,
  );

  // Test ID: LGLV-PASS
  testLocalizationsV2(
    'login local view - password entry and hint expansion',
    (tester, screen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const LoginLocalView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();

      final passwordFinder = find.byType(AppPasswordInput);
      await tester.enterText(passwordFinder, 'Password!!!');
      await tester.pumpAndSettle();
      // After UI Kit migration, there are multiple AppButtons (forgot password + login)
      // Use specific widget+text finder for login button
      final loginButtonFinder =
          find.byKey(const Key('loginLocalView_loginButton'));
      expect(loginButtonFinder, findsOneWidget);
      var loginButton = tester.widget<AppButton>(loginButtonFinder);
      expect(loginButton.onTap, isNotNull);
      await testHelper.takeScreenshot(
        tester,
        'LGLV-PASS_01_password_masked',
      );

      final secureFinder = find.byIcon(AppFontIcons.visibility);
      await tester.tap(secureFinder);
      await tester.pumpAndSettle();
      final updatedLoginButtonFinder =
          find.byKey(const Key('loginLocalView_loginButton'));
      loginButton = tester.widget<AppButton>(updatedLoginButtonFinder);
      expect(loginButton.onTap, isNotNull);

      final showHintFinder = find.text(loc.showHint);
      expect(showHintFinder, findsOneWidget);
      await tester.tap(showHintFinder);
      await tester.pumpAndSettle();
      expect(find.text('Linksys'), findsWidgets);
    },
    goldenFilename: 'LGLV-PASS_02_password_hint_visible',
    helper: testHelper,
  );

  // Test ID: LGLV-ERR_COUNTDOWN
  testLocalizationsV2(
    'login local view - error countdown',
    (tester, screen) async {
      when(testHelper.mockAuthNotifier.getAdminPasswordAuthStatus(any))
          .thenAnswer((_) async {
        return {
          'attemptsRemaining': 4,
          'delayTimeRemaining': 5,
        };
      });

      final context = await testHelper.pumpView(
        tester,
        child: const LoginLocalView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();
      // Wait for async flow: doSomethingWithSpinner -> checkDeviceInfo -> getAdminPasswordAuthStatus -> setErrorMessage
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      // At the moment of the screenshot, delay time remaining has already dropped from 5 seconds to 4 seconds
      // Error messages are rendered in the UI, search for the text content
      // Expected format: "Try again in: N\nRemaining attempts: N"
      // Use textContaining for more flexible matching
      expect(
        find.textContaining(RegExp(r'Try again in:|Remaining attempts:')),
        findsWidgets,
      );
    },
    goldenFilename: 'LGLV-ERR_COUNTDOWN_01_delay_message',
    helper: testHelper,
  );

  // Test ID: LGLV-ERR_LOCKED
  testLocalizationsV2(
    'login local view - lockout message when attempts exhausted',
    (tester, screen) async {
      when(testHelper.mockAuthNotifier.getAdminPasswordAuthStatus(any))
          .thenAnswer((_) async {
        return {
          'attemptsRemaining': 0,
        };
      });

      final context = await testHelper.pumpView(
        tester,
        child: const LoginLocalView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();
      // Wait for async flow: doSomethingWithSpinner -> checkDeviceInfo -> getAdminPasswordAuthStatus -> setErrorMessage
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Error messages are rendered in the UI, search for the text content
      expect(
        find.textContaining(loc.localLoginTooManyAttemptsTitle),
        findsOneWidget,
      );
    },
    goldenFilename: 'LGLV-ERR_LOCKED_01_lockout_message',
    helper: testHelper,
  );

  // Test ID: LGLV-ERR_GENERIC
  testLocalizationsV2(
    'login local view - generic incorrect password error',
    (tester, screen) async {
      // As long as one of the two parameters is missing, it will display generic incorrect password error
      when(testHelper.mockAuthNotifier.getAdminPasswordAuthStatus(any))
          .thenAnswer((_) async {
        return {
          'attemptsRemaining': null,
          'delayTimeRemaining': 5,
        };
      });

      final context = await testHelper.pumpView(
        tester,
        child: const LoginLocalView(),
        locale: screen.locale,
        config: LinksysRouteConfig(noNaviRail: true),
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();
      // Wait for async flow: doSomethingWithSpinner -> checkDeviceInfo -> getAdminPasswordAuthStatus -> setErrorMessage
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Error messages are rendered in the UI, search for the text content
      expect(
        find.textContaining(loc.localLoginIncorrectRouterPassword),
        findsOneWidget,
      );
    },
    goldenFilename: 'LGLV-ERR_GENERIC_01_generic_message',
    helper: testHelper,
  );
}
