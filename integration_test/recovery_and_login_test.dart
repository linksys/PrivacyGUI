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
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'actions/base_actions.dart';
import 'config/integration_test_config.dart';
import 'extensions/extensions.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String newPassword = IntegrationTestConfig.newPassword;
  const String recoveryCode = IntegrationTestConfig.recoveryCode;
  const String passwordHint = IntegrationTestConfig.passwordHint;

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

  testWidgets('Recovery and log in flow golden', (tester) async {
    // Load app widget.
    await tester.pumpFrames(app(), Duration(seconds: 3));

    // Login page
    final login = TestLocalLoginActions(tester);
    await login.tapForgetPassword();

    // Recovery page
    final recovery = TestLocalRecoveryActions(tester);
    await recovery.inputRecoveryCode(recoveryCode);
    expect(recoveryCode, tester.getText(find.byType(PinCodeTextField)));
    await recovery.tapContinueButton();

    // Reset password page
    final reset = TestLocalResetPasswordActions(tester);
    await reset.inputNewPassword(newPassword);
    await reset.inputConfirmPassword(newPassword);
    await reset.showNewPassword();
    await reset.showConfirmPassword();
    await reset.inputPasswordHint(passwordHint);
    expect(newPassword, tester.getText(find.byType(AppPasswordField).first));
    expect(newPassword, tester.getText(find.byType(AppPasswordField).last));
    expect(passwordHint, tester.getText(find.byType(TextField).last));
    await tester.scrollUntilVisible(
      reset.saveButtonFinder(),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await reset.tapSaveButton();
    await reset.backToLogin();

    // Login page
    expect(find.byType(AppPasswordField), findsOneWidget);

    // Login page
    await login.inputPassword(newPassword);
    expect(newPassword, tester.getText(find.byType(AppPasswordField)));
    await login.showPassword();
    await login.hidePassword();
    await login.tapLoginButton();

    // Dashboard
    final quickPanelFinder = find.byType(DashboardQuickPanel);
    expect(quickPanelFinder, findsOneWidget);
  });
}
