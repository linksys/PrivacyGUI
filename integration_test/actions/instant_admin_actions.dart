part of 'base_actions.dart';

class TestInstantAdminActions extends CommonBaseActions {
  TestInstantAdminActions(super.tester);

  Finder autoUpdateSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder manualUpdateButtonFinder() {
    final textButtonFinder = find.byKey(const Key('manualUpdateButton'));
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
    final editPasswordFinder = find.byKey(const Key('passwordCard'));
    expect(editPasswordFinder, findsOneWidget);
    return editPasswordFinder;
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
      matching: find.byKey(const Key('newPasswordField')),
    );
    expect(passwordFieldFinder, findsOneWidget);
    return passwordFieldFinder;
  }

  Finder confirmPasswordFieldFinder() {
    final dialogFinder = passwordInputAlertDialogFinder();
    final passwordFieldFinder = find.descendant(
      of: dialogFinder,
      matching: find.byKey(const Key('confirmPasswordField')),
    );
    expect(passwordFieldFinder, findsOneWidget);
    return passwordFieldFinder;
  }

  Finder passwordHintFieldFinder() {
    final dialogFinder = passwordInputAlertDialogFinder();
    final hintFieldFinder = find.descendant(
      of: dialogFinder,
      matching: find.byKey(const Key('hintTextField')),
    );
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
    final editPasswordFinder = find.byKey(const Key('timezoneCard'));
    expect(editPasswordFinder, findsOneWidget);
    return editPasswordFinder;
  }

  Finder daylightSavingSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder australiaTimeZoneCardFinder() {
    final textFinder = find.text('Australia');
    final cardFinder = find
        .ancestor(
          of: textFinder,
          matching: find.byType(AppCard),
        )
        .first;
    expect(cardFinder, findsOneWidget);
    return cardFinder;
  }

  Finder australiaTimezoneCheckIconFinder() {
    final textFinder = find.text('Australia');
    final card = find
        .ancestor(
          of: textFinder,
          matching: find.byType(AppCard),
        )
        .first;
    expect(textFinder, findsOneWidget);
    final checkIconFinder = find.descendant(of: card, matching: find.byType(Icon));
    return checkIconFinder;
  }

  Finder saveButtonFinder() {
    final saveButtonFinder = find.byType(AppFilledButton);
    expect(saveButtonFinder, findsOneWidget);
    return saveButtonFinder;
  }

  bool isAutoUpdateEnabled() {
    // Find auto upfate switch
    final switchFinder = autoUpdateSwitchFinder();
    final autoUpdateSwitch = tester.widget<AppSwitch>(switchFinder);
    return autoUpdateSwitch.value;
  }

  bool isAutoDaylightSavingEnabled() {
    // Find auto daylight saving switch
    final switchFinder = daylightSavingSwitchFinder();
    final autoUpdateSwitch = tester.widget<AppSwitch>(switchFinder);
    return autoUpdateSwitch.value;
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

  Future<void> selectAustraliaTimeZone() async {
    // Find Australia time zone
    final cardFinder = australiaTimeZoneCardFinder();
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
