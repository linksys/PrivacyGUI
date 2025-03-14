import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/input_field/app_password_field.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';

import 'base_actions.dart';

class TestLocalResetPasswordActions extends CommonBaseActions {
  TestLocalResetPasswordActions(super.tester);

  Finder firstVisibilityFinder() {
    final visibilityFinder = find.descendant(
        of: find.byType(AppPasswordField).first,
        matching: find.byIcon(LinksysIcons.visibility));
    expect(visibilityFinder, findsOneWidget);
    return visibilityFinder;
  }

  Finder firstVisibilityOffFinder() {
    final visibilityOffFinder = find.descendant(
        of: find.byType(AppPasswordField).first,
        matching: find.byIcon(LinksysIcons.visibilityOff));

    expect(visibilityOffFinder, findsOneWidget);
    return visibilityOffFinder;
  }

  Finder lastVisibilityFinder() {
    final visibilityFinder = find.descendant(
        of: find.byType(AppPasswordField).last,
        matching: find.byIcon(LinksysIcons.visibility));
    expect(visibilityFinder, findsOneWidget);
    return visibilityFinder;
  }

  Finder lastVisibilityOffFinder() {
    final visibilityOffFinder = find.descendant(
        of: find.byType(AppPasswordField).last,
        matching: find.byIcon(LinksysIcons.visibilityOff));

    expect(visibilityOffFinder, findsOneWidget);
    return visibilityOffFinder;
  }

  Finder newPasswordFinder() {
    final newPasswordFinder = find.byType(AppPasswordField).first;
    expect(newPasswordFinder, findsOneWidget);
    return newPasswordFinder;
  }

  Finder confirmPasswordFinder() {
    final confirmPasswordFinder = find.byType(AppPasswordField).last;
    expect(confirmPasswordFinder, findsOneWidget);
    return confirmPasswordFinder;
  }

  Finder passwordHintFinder() {
    final passwordHintFinder = find.byType(AppTextField).last;
    expect(passwordHintFinder, findsOneWidget);
    return passwordHintFinder;
  }

  Finder saveButtonFinder() {
    final saveButtonFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton));
    expect(saveButtonFinder, findsOneWidget);
    return saveButtonFinder;
  }

  Finder backToLoginFinder() {
    final backToLoginFinder = find.descendant(
        of: find.byKey(const ValueKey('resetSavedDialog')),
        matching: find.byType(AppTextButton));
    expect(backToLoginFinder, findsOneWidget);
    return backToLoginFinder;
  }

  Future<void> showNewPassword() async {
    final visibleFinder = firstVisibilityFinder();
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hideNewPassword() async {
    final visibleFinder = firstVisibilityOffFinder();
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> showConfirmPassword() async {
    final visibleFinder = lastVisibilityFinder();
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hideConfirmPassword() async {
    final visibleFinder = lastVisibilityOffFinder();
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputNewPassword(String password) async {
    final finder = newPasswordFinder();
    await tester.enterText(finder, password);
    await tester.pumpAndSettle();
  }

  Future<void> inputConfirmPassword(String password) async {
    final finder = confirmPasswordFinder();
    await tester.enterText(finder, password);
    await tester.pumpAndSettle();
  }

  Future<void> inputPasswordHint(String hint) async {
    final finder = passwordHintFinder();
    await tester.enterText(finder, hint);
    await tester.pumpAndSettle();
  }

  Future<void> tapSaveButton() async {
    await tester.tap(saveButtonFinder());
    await tester.pumpFrames(app(), const Duration(seconds: 5));
  }

  Future<void> backToLogin() async {
    await tester.tap(backToLoginFinder());
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }
}
