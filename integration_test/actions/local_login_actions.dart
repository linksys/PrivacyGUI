

part of 'base_actions.dart';

class TestLocalLoginActions extends CommonBaseActions {
  TestLocalLoginActions(super.tester);

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

  Finder passwordFieldFinder() {
    final passwordFinder = find.byType(AppPasswordField);
    expect(passwordFinder, findsOneWidget);
    return passwordFinder;
  }

  Finder loginButtonFinder() {
    final loginButtonFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton));
    expect(loginButtonFinder, findsOneWidget);
    return loginButtonFinder;
  }

  Finder forgetPasswordFinder() {
    final forgetPasswordFinder = find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppTextButton));
    expect(forgetPasswordFinder, findsOneWidget);
    return forgetPasswordFinder;
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

  Future<void> inputPassword(String adminPassword) async {
    final passwordFinder = passwordFieldFinder();
    await tester.tap(passwordFinder);
    await tester.enterText(passwordFinder, adminPassword);
    await tester.pumpAndSettle();
  }

  Future<void> tapLoginButton() async {
    await tester.tap(loginButtonFinder());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> tapForgetPassword() async {
    await tester.tap(forgetPasswordFinder());
    // Using pumpFrames for infinite animations
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }
}
