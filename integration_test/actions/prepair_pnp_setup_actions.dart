import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/input_field/app_password_field.dart';
import 'package:privacygui_widgets/widgets/switch/switch.dart';

import 'base_actions.dart';

class TestPrepairPnpSetupActions extends CommonBaseActions {
  TestPrepairPnpSetupActions(super.tester);

  Finder passwordFinder() {
    final passwordFinder = find.byType(AppPasswordField).first;
    expect(passwordFinder, findsOneWidget);
    return passwordFinder;
  }

  Finder visibilityFinder() {
    final visibleFinder = find.byIcon(LinksysIcons.visibility);
    expect(visibleFinder, findsOneWidget);
    return visibleFinder;
  }

  Finder loginButtonFinder() {
    final loginButtonFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton));
    expect(loginButtonFinder, findsOneWidget);
    return loginButtonFinder;
  }

  Finder nextButtonFinder() {
    final nextButtonFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton));
    expect(nextButtonFinder, findsOneWidget);
    return nextButtonFinder;
  }

  Finder appSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder doneButtonFinder() {
    final doneButtonFinder = find.byType(AppFilledButton);
    expect(doneButtonFinder, findsOneWidget);
    return doneButtonFinder;
  }

  Future<void> tapNextButton({int seconds = 5}) async {
    await tester.tap(nextButtonFinder());
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }

  Future<void> inputPassword(String password) async {
    final finder = passwordFinder();
    await tester.enterText(finder, password);
    await tester.pumpAndSettle();
  }

  Future<void> showPassword() async {
    final visibleFinder = visibilityFinder();
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapLoginButton() async {
    await tester.tap(loginButtonFinder());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> tapSwitch({int seconds = 5}) async {
    final switchFinder = appSwitchFinder();
    await tester.tap(switchFinder);
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }

  Future<void> tapDoneButton({int seconds = 5}) async {
    final doneBtnFinder = doneButtonFinder();
    await tester.tap(doneBtnFinder);
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }

}