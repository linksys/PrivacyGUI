part of 'base_actions.dart';

class TestLocalRecoveryActions extends CommonBaseActions {
  TestLocalRecoveryActions(super.tester);

  Finder recoveryFieldFinder() {
    final recoveryFinder = find.byType(PinCodeTextField);
    expect(recoveryFinder, findsOneWidget);
    return recoveryFinder;
  }

  Finder continueButtonFinder() {
    final continueBtnFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton));
    expect(continueBtnFinder, findsOneWidget);
    return continueBtnFinder;
  }

  Future<void> inputRecoveryCode(String recoveryCode) async {
    final recoveryFinder = recoveryFieldFinder();
    await tester.tap(recoveryFinder);
    await tester.enterText(recoveryFinder, recoveryCode);
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }

  Future<void> tapContinueButton() async {
    await tester.tap(continueButtonFinder());
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }
}
