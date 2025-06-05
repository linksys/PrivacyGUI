part of 'base_actions.dart';

class TestInstantSafetyActions extends CommonBaseActions {
  TestInstantSafetyActions(super.tester);

  Finder instantSafetySwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  bool isFeatureEnabled() {
    // Find instant safety switch
    final switchFinder = instantSafetySwitchFinder();
    final instantSafetySwitch = tester.widget<AppSwitch>(switchFinder);
    return instantSafetySwitch.value;
  }

  Future<void> toggleInstantSafetySwitch() async {
    // Find instant safety switch
    final switchFinder = instantSafetySwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapSaveButton() async {
    // Find save button
    Finder buttonFinder = saveButtonFinder();
    // Ensure that the button is enabled
    final button = tester.widget<AppFilledButton>(buttonFinder);
    expect(button.onTap, isNotNull);
    // Tap the save button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelOnInstantSafetyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the cancel button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the cancel button
    await tester.tap(dialogButtonFinder.first);
    await tester.pumpAndSettle();
  }

  Future<void> tapRestartOnInstantSafetyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the Restart button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the Restart button
    await tester.tap(dialogButtonFinder.last);
    await tester.pumpAndSettle();
  }
}
