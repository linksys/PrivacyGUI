import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/switch/switch.dart';

class TestPnpSetupActions {
  TestPnpSetupActions(this.tester);

  final WidgetTester tester;

  Finder continueButtonFinder() {
    final continueButtonFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton));
    expect(continueButtonFinder, findsOneWidget);
    return continueButtonFinder;
  }

  Finder nextButtonFinder() {
    final nextButtonFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton));
    expect(nextButtonFinder, findsOneWidget);
    return nextButtonFinder;
  }

  Finder visibilityFinder() {
    final visibleFinder = find.byIcon(LinksysIcons.visibility);
    expect(visibleFinder, findsOneWidget);
    return visibleFinder;
  }

  Finder visibilityOffFinder() {
    final visibleFinder = find.byIcon(LinksysIcons.visibilityOff);
    expect(visibleFinder, findsOneWidget);
    return visibleFinder;
  }

  Finder addNodeButtonFinder() {
    final addNodeButtonFinder = find.byIcon(LinksysIcons.add);
    expect(addNodeButtonFinder, findsOneWidget);
    return addNodeButtonFinder;
  }

  Finder doneButtonFinder() {
    final doneButtonFinder = find.byType(AppFilledButton);
    expect(doneButtonFinder, findsOneWidget);
    return doneButtonFinder;
  }

  Finder appSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Future<void> tapContinueButton({int seconds = 5}) async {
    await tester.tap(continueButtonFinder());
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }

  Future<void> tapNextButton({int seconds = 5}) async {
    await tester.tap(nextButtonFinder());
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }

   Future<void> showPassword() async {
    final visibleFinder = visibilityFinder();
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hidePassword() async {
    final visibleFinder = visibilityOffFinder();
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapAddNodeButton({int seconds = 5}) async {
    final addNodeBtnFinder = addNodeButtonFinder();
    await tester.tap(addNodeBtnFinder);
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }

  Future<void> tapDoneButton({int seconds = 5}) async {
    final doneBtnFinder = doneButtonFinder();
    await tester.tap(doneBtnFinder);
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }

  Future<void> tapSwitch({int seconds = 5}) async {
    final switchFinder = appSwitchFinder();
    await tester.tap(switchFinder);
    await tester.pumpFrames(app(), Duration(seconds: seconds));
  }
}