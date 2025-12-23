import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/_index.dart';

// View ID: LRRP
// Implementation: lib/page/login/views/local_reset_router_password_view.dart
// Summary:
// - LRRP-INIT: Default page layout with validators and disabled Save.
// - LRRP-EDIT: User types passwords, toggles visibility, and fills hint field.
// - LRRP-VALID: Save button enabled when provider state is valid.
// - LRRP-SUCCESS: Successful reset shows confirmation dialog.
// - LRRP-FAIL: Failed reset surfaces error dialog.

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
    when(
      testHelper.mockRouterPasswordNotifier.setAdminPasswordWithResetCode(
        any,
        any,
        any,
      ),
    ).thenAnswer((_) async {});
  });

  RouterPasswordState baseState() =>
      RouterPasswordState.fromMap(routerPasswordTestState1);

  Future<void> fillPasswords(
    WidgetTester tester, {
    required String password,
    String? confirm,
  }) async {
    final passwordFinder = find.byType(AppPasswordInput);
    await tester.enterText(passwordFinder.at(0), password);
    await tester.enterText(passwordFinder.at(1), confirm ?? password);
    await tester.pumpAndSettle();
  }

  Future<void> fillHint(WidgetTester tester, String hint) async {
    final hintField = find.byType(AppTextFormField).last;
    await tester.enterText(hintField, hint);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToSave(
    WidgetTester tester,
    String saveText,
  ) async {
    // Use specific finder for Save button to avoid multiple AppButtons
    final saveFinder = find.widgetWithText(AppButton, saveText);
    await tester.scrollUntilVisible(
      saveFinder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  // Test ID: LRRP-INIT
  testLocalizations(
    'local reset router password view - initial layout',
    (tester, screen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const LocalResetRouterPasswordView(),
        config: LinksysRouteConfig(noNaviRail: true),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();
      final loc = testHelper.loc(context);

      expect(
        find.text(loc.localResetRouterPasswordTitle),
        findsOneWidget,
      );
      expect(
        find.text(loc.localResetRouterPasswordDescription),
        findsOneWidget,
      );
      // After UI Kit migration: 2 AppPasswordInput + 1 AppTextFormField (hint)
      expect(find.byType(AppTextFormField), findsNWidgets(1));
      expect(find.byType(AppPasswordInput), findsNWidgets(2));
      // Use specific widget+text finder for Save button
      final saveButtonFinder =
          find.byKey(const Key('localResetPassword_saveButton'));
      expect(saveButtonFinder, findsOneWidget);
      final saveButton = tester.widget<AppButton>(saveButtonFinder);
      expect(saveButton.onTap, isNull);
    },
    goldenFilename: 'LRRP-INIT_01_initial_state',
    helper: testHelper,
  );

  // Test ID: LRRP-EDIT
  testLocalizations(
    'local reset router password view - editing password and hint',
    (tester, screen) async {
      await testHelper.pumpView(
        tester,
        child: const LocalResetRouterPasswordView(),
        config: LinksysRouteConfig(noNaviRail: true),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      await fillPasswords(tester, password: 'Linksys123!', confirm: 'Linksys!');
      final visibilityFinder = find.byIcon(AppFontIcons.visibility).first;
      await tester.tap(visibilityFinder);
      await tester.pumpAndSettle();
      await fillHint(tester, 'Home Wifi');
    },
    goldenFilename: 'LRRP-EDIT_01_password_not_match',
    helper: testHelper,
  );

  // Test ID: LRRP-VALID
  testLocalizations(
    'local reset router password view - save button enabled on valid state',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
        baseState().copyWith(isValid: true),
      );
      final context = await testHelper.pumpView(
        tester,
        child: const LocalResetRouterPasswordView(),
        config: LinksysRouteConfig(noNaviRail: true),
        locale: screen.locale,
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();
      await scrollToSave(tester, loc.save);

      final saveButtonFinder =
          find.byKey(const Key('localResetPassword_saveButton'));
      expect(saveButtonFinder, findsOneWidget);
      final saveButton = tester.widget<AppButton>(saveButtonFinder);
      expect(saveButton.onTap, isNotNull);
    },
    goldenFilename: 'LRRP-VALID_01_save_enabled',
    helper: testHelper,
  );

  // Test ID: LRRP-SUCCESS
  testLocalizations(
    'local reset router password view - successful reset dialog',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
        baseState().copyWith(isValid: true),
      );

      final context = await testHelper.pumpView(
        tester,
        child: const LocalResetRouterPasswordView(),
        config: LinksysRouteConfig(noNaviRail: true),
        locale: screen.locale,
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();

      await fillPasswords(tester, password: 'Linksys123!');
      await fillHint(tester, 'Home Wifi');
      await scrollToSave(tester, loc.save);
      await tester.tap(find.byKey(const Key('localResetPassword_saveButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('resetSavedDialog')), findsOneWidget);
      expect(find.text(loc.localResetRouterPasswordSuccessContent),
          findsOneWidget);
    },
    goldenFilename: 'LRRP-SUCCESS_01_success_dialog',
    helper: testHelper,
  );

  // Test ID: LRRP-FAIL
  testLocalizations(
    'local reset router password view - failure dialog',
    (tester, screen) async {
      when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
        baseState().copyWith(isValid: true),
      );
      when(
        testHelper.mockRouterPasswordNotifier.setAdminPasswordWithResetCode(
          any,
          any,
          any,
        ),
      ).thenAnswer((_) async => throw Exception('failed'));

      final context = await testHelper.pumpView(
        tester,
        child: const LocalResetRouterPasswordView(),
        config: LinksysRouteConfig(noNaviRail: true),
        locale: screen.locale,
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();

      await fillPasswords(tester, password: 'Linksys123!');
      await fillHint(tester, 'Office Wifi');
      await scrollToSave(tester, loc.save);
      await tester.tap(find.byKey(const Key('localResetPassword_saveButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('resetSavedDialog')), findsOneWidget);
      expect(find.text(loc.invalidAdminPassword), findsOneWidget);
    },
    goldenFilename: 'LRRP-FAIL_01_failure_dialog',
    helper: testHelper,
  );
}
