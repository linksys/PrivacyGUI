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

import 'actions/local_login_actions.dart';
import 'actions/recovery_actions.dart';
import 'actions/reset_password_actions.dart';
import 'config/integration_test_config.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String password = IntegrationTestConfig.password;
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
    await reset.inputNewPassword(password);
    await reset.inputConfirmPassword(password);
    await reset.showNewPassword();
    await reset.showConfirmPassword();
    await reset.inputPasswordHint(passwordHint);
    expect(password, tester.getText(find.byType(AppPasswordField).first));
    expect(password, tester.getText(find.byType(AppPasswordField).last));
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
    await login.inputPassword(password);
    expect(password, tester.getText(find.byType(AppPasswordField)));
    await login.showPassword();
    await login.hidePassword();
    await login.tapLoginButton();

    // Dashboard
    final quickPanelFinder = find.byType(DashboardQuickPanel);
    expect(quickPanelFinder, findsOneWidget);
  });
}

extension WidgetTesterExt on WidgetTester {
  String getText(Finder finder) {
    return (widget(finder) as dynamic).controller?.text ?? '';
  }
}
