import 'package:flutter_test/flutter_test.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

class TestLocalRecoveryActions {
  TestLocalRecoveryActions(this.tester);

  final WidgetTester tester;

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
