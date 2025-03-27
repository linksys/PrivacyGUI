part of 'base_actions.dart';

class TestInstantAdminActions extends CommonBaseActions {
  TestInstantAdminActions(super.tester);

  Finder autoUpdateSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder manualUpdateButtonFinder() {
    final textButtonFinder = find.byType(AppTextButton);
    expect(textButtonFinder, findsOneWidget);
    return textButtonFinder;
  }

  Finder passwordEyeButtonFinder() {
    final eyeButtonFinder = find.descendant(
      of: find.byType(AppPasswordField),
      matching: find.byType(AppIconButton),
    );
    expect(eyeButtonFinder, findsOneWidget);
    return eyeButtonFinder;
  }

  Finder editPasswordTappableFinder() {
    final editPasswordFinder = find.byType(AppCard);
    expect(editPasswordFinder, findsNWidgets(6));
    return editPasswordFinder.at(1);
  }

  Finder passwordInputAlertDialogFinder() {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    return dialogFinder;
  }

  Finder newPasswordFieldFinder() {
    final dialogFinder = passwordInputAlertDialogFinder();
    final passwordFieldFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppPasswordField),
    );
    expect(passwordFieldFinder, findsNWidgets(2));
    return passwordFieldFinder.first;
  }

  Finder confirmPasswordFieldFinder() {
    final dialogFinder = passwordInputAlertDialogFinder();
    final passwordFieldFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppPasswordField),
    );
    expect(passwordFieldFinder, findsNWidgets(2));
    return passwordFieldFinder.last;
  }

  Finder passwordHintFieldFinder() {
    final dialogFinder = passwordInputAlertDialogFinder();
    final hintFieldFinder = find
        .descendant(
          of: dialogFinder,
          matching: find.byType(AppTextField),
        )
        .last;
    expect(hintFieldFinder, findsOneWidget);
    return hintFieldFinder;
  }

  Finder editPasswordCancelButtonFinder() {
    final dialogFinder = passwordInputAlertDialogFinder();
    final textButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(textButtonFinder, findsNWidgets(2));
    return textButtonFinder.first;
  }

  Finder editPasswordSaveButtonFinder() {
    final dialogFinder = passwordInputAlertDialogFinder();
    final textButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(textButtonFinder, findsNWidgets(2));
    return textButtonFinder.last;
  }

  Finder editTimezoneTappableFinder() {
    final editPasswordFinder = find.byType(AppCard);
    expect(editPasswordFinder, findsNWidgets(6));
    return editPasswordFinder.at(5);
  }

  Finder daylightSavingSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder taiwanTimeZoneCardFinder() {
    final taiwan = find.text('Singapore, Taiwan, Russia');
    final card = find
        .ancestor(
          of: taiwan,
          matching: find.byType(AppCard),
        )
        .first;
    expect(card, findsOneWidget);
    return card;
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  Future<void> toggleAutoFirmwareUpdateSwitch() async {
    // Find auto update switch
    final switchFinder = autoUpdateSwitchFinder();
    // Toggle the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapManualUpdateButton() async {
    // Find manual update button
    final buttonFinder = manualUpdateButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapPasswordEyeButton() async {
    // Find password eye button
    final buttonFinder = passwordEyeButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputNewPassword(String adminPassword) async {
    final passwordFieldFinder = newPasswordFieldFinder();
    await tester.tap(passwordFieldFinder);
    await tester.enterText(passwordFieldFinder, adminPassword);
    await tester.pumpAndSettle();
  }

  Future<void> inputConfirmPassword(String adminPassword) async {
    final passwordFinder = confirmPasswordFieldFinder();
    await tester.tap(passwordFinder);
    await tester.enterText(passwordFinder, adminPassword);
    await tester.pumpAndSettle();
  }

  Future<void> inputPasswordHint(String hint) async {
    final hintFieldFinder = passwordHintFieldFinder();
    await tester.tap(hintFieldFinder);
    await tester.enterText(hintFieldFinder, hint);
    await tester.pumpAndSettle();
  }

  Future<void> tapEditPasswordCancelButton() async {
    final cancelButton = editPasswordCancelButtonFinder();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapEditPasswordSaveButton() async {
    final saveButton = editPasswordSaveButtonFinder();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapEditPasswordTappableArea() async {
    // Find edit password tappable
    final editPasswordFinder = editPasswordTappableFinder();
    // Tap the edit password
    await tester.tap(editPasswordFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapTimezoneTappableArea() async {
    // Find time zone tappable
    final timezoneTappableFinder = editTimezoneTappableFinder();
    // Tap the time zone
    await tester.tap(timezoneTappableFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleDaylightSavingSwitch() async {
    // Find daylight saving switch
    final switchFinder = daylightSavingSwitchFinder();
    // Toggle the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> selectTaiwanTimeZone() async {
    // Find taiwan time zone
    final cardFinder = taiwanTimeZoneCardFinder();
    // Scroll the screen
    await scrollUntil(cardFinder);
    // Tap the time zone
    await tester.tap(cardFinder);
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
}
