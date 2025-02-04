import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // init better actions
    initBetterActions();
    // clear all cache data to make sure every test case is independent
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    BuildConfig.load();

    // GetIt
    dependencySetup();
  });
  group('end-to-end test - Login', () {
    testWidgets('Recovery flow golden', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 3));

      // Login page
      final login = TestLocalLoginActions(tester);
      await login.tapForgetPassword();

      // Recovery page
      final recovery = TestLocalRecoveryActions(tester);
      await recovery.inputRecoveryCode('66584');
      expect('66584', tester.getText(find.byType(PinCodeTextField)));
      await recovery.tapContinueButton();

      // Reset password page
      final reset = TestLocalResetPasswordActions(tester);
      await reset.inputNewPassword('4jQnu5wyt@');
      await reset.inputConfirmPassword('4jQnu5wyt@');
      await reset.showNewPassword();
      await reset.showConfirmPassword();
      await reset.inputPasswordHint('Linksys');
      expect('4jQnu5wyt@', tester.getText(find.byType(AppPasswordField).first));
      expect('4jQnu5wyt@', tester.getText(find.byType(AppPasswordField).last));
      expect('Linksys', tester.getText(find.byType(TextField).last));
      await reset.tapSaveButton();
      expect(find.byKey(const ValueKey('resetSavedDialog')), findsOneWidget);
      await reset.backToLogin();

      // Login page
      expect(find.byType(AppPasswordField), findsOneWidget);
    });
    testWidgets('Login flow golden', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 3));
      
      // Login page
      final login = TestLocalLoginActions(tester);
      await login.inputPassword('4jQnu5wyt@');
      expect('4jQnu5wyt@', tester.getText(find.byType(AppPasswordField)));
      await login.showPassword();
      await login.hidePassword();
      await login.tapLoginButton();

      // Dashboard
      final quickPanelFinder = find.byType(DashboardQuickPanel);
      expect(quickPanelFinder, findsOneWidget);
    });
  });
}

extension WidgetTesterExt on WidgetTester {
  String getText(Finder finder) {
    return (widget(finder) as dynamic).controller?.text ?? '';
  }
}

class TestLocalResetPasswordActions {
  TestLocalResetPasswordActions(this.tester);

  final WidgetTester tester;

  Future<void> showNewPassword() async {
    final visibleFinder = find.descendant(
        of: find.byType(AppPasswordField).first,
        matching: find.byIcon(LinksysIcons.visibility));
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hideNewPassword() async {
    final visibleFinder = find.descendant(
        of: find.byType(AppPasswordField).first,
        matching: find.byIcon(LinksysIcons.visibilityOff));
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> showConfirmPassword() async {
    final visibleFinder = find.descendant(
        of: find.byType(AppPasswordField).last,
        matching: find.byIcon(LinksysIcons.visibility));
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hideConfirmPassword() async {
    final visibleFinder = find.descendant(
        of: find.byType(AppPasswordField).last,
        matching: find.byIcon(LinksysIcons.visibilityOff));
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputNewPassword(String password) async {
    final finder = find.byType(AppPasswordField).first;
    await tester.enterText(finder, password);
    await tester.pumpAndSettle();
  }

  Future<void> inputConfirmPassword(String password) async {
    final finder = find.byType(AppPasswordField).last;
    await tester.enterText(finder, password);
    await tester.pumpAndSettle();
  }

  Future<void> inputPasswordHint(String hint) async {
    final finder = find.byType(AppTextField).last;
    await tester.enterText(finder, hint);
    await tester.pumpAndSettle();
  }

  Future<void> tapSaveButton() async {
    await tester.tap(find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton)));
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }

  Future<void> backToLogin() async {
    await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('resetSavedDialog')),
        matching: find.byType(AppTextButton)));
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }
}

class TestLocalRecoveryActions {
  TestLocalRecoveryActions(this.tester);

  final WidgetTester tester;

  Future<void> inputRecoveryCode(String recoveryCode) async {
    final recoveryFinder = find.byType(PinCodeTextField);
    await tester.tap(recoveryFinder);
    await tester.enterText(recoveryFinder, recoveryCode);
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }

  Future<void> tapContinueButton() async {
    await tester.tap(find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton)));
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }
}

class TestLocalLoginActions {
  TestLocalLoginActions(this.tester);

  final WidgetTester tester;

  Future<void> showPassword() async {
    final visibleFinder = find.byIcon(LinksysIcons.visibility);
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hidePassword() async {
    final visibleFinder = find.byIcon(LinksysIcons.visibilityOff);
    await tester.tap(visibleFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputPassword(String adminPassword) async {
    final passwordFinder = find.byType(AppPasswordField);
    await tester.tap(passwordFinder);
    await tester.enterText(passwordFinder, adminPassword);
    await tester.pumpAndSettle();
  }

  Future<void> tapLoginButton() async {
    await tester.tap(find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppFilledButton)));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> tapForgetPassword() async {
    await tester.tap(find.descendant(
        of: find.byType(AppCard), matching: find.byType(AppTextButton)));
    // Using pumpFrames for infinite animations
    await tester.pumpFrames(app(), const Duration(seconds: 1));
  }
}
