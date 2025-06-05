import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'actions/base_actions.dart';
import 'config/integration_test_config.dart';
import 'extensions/extensions.dart';

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

  testWidgets('Instant admin operations', (tester) async {
    // Log in
    await tester.pumpFrames(app(), Duration(seconds: 3));
    final login = TestLocalLoginActions(tester);
    await login.inputPassword(IntegrationTestConfig.password);
    expect(
      IntegrationTestConfig.password,
      tester.getText(find.byType(AppPasswordField)),
    );
    await login.tapLoginButton();
    // Enter the menu screen
    final topbarActions = TestTopbarActions(tester);
    await topbarActions.tapMenuButton();
    final menuActions = TestMenuActions(tester);
    // Enter Instant Admin screen
    await menuActions.enterAdminPage();
    final adminActions = TestInstantAdminActions(tester);
    await adminActions.checkTitle(adminActions.title);
    // Record the current status of auto firmware update
    final previousAutoUpdateValue = adminActions.isAutoUpdateEnabled();
    // Switch auto firmware update
    await adminActions.toggleAutoFirmwareUpdateSwitch();
    // Check manual firmware update screen
    await adminActions.tapManualUpdateButton();
    await adminActions.tapBackButton();
    // Hide&Show password
    await adminActions.tapPasswordEyeButton();
    await adminActions.tapPasswordEyeButton();
    // Start changing admin password
    // Open the edit password dialog
    await adminActions.tapEditPasswordTappableArea();
    // At first, tap cancel button
    await adminActions.tapEditPasswordCancelButton();
    // Again, open the edit password dialog
    await adminActions.tapEditPasswordTappableArea();
    // Input new passwords
    await adminActions.inputNewPassword(IntegrationTestConfig.newPassword);
    await adminActions.inputConfirmPassword(IntegrationTestConfig.newPassword);
    await adminActions.inputPasswordHint(IntegrationTestConfig.passwordHint);
    // Save the new password
    await adminActions.tapEditPasswordSaveButton();
    // Enter time zone selection screen
    await adminActions.tapTimezoneTappableArea();
    // Record the current status of auto daylight saving
    final previousAutoDaylightSavingValue =
        adminActions.isAutoDaylightSavingEnabled();
    // Toggle the auto daylight saving
    await adminActions.toggleDaylightSavingSwitch();
    // Select the specific time zone value - Australia GMT+10:00 (support daylight savings time)
    await adminActions.selectAustraliaTimeZone();
    // Save time zone settings
    await adminActions.tapSaveButton();
    // Re-enter Instant Admin screen
    await adminActions.tapBackButton();
    await menuActions.enterAdminPage();
    // Verify updated values
    // Auto firmware update
    final currentAutoUpdateValue = adminActions.isAutoUpdateEnabled();
    expect(previousAutoUpdateValue, isNot(currentAutoUpdateValue));
    // Enter time zone selection screen
    await adminActions.tapTimezoneTappableArea();
    // Time zone and auto daylight savings time
    final currentAutoDaylightSavingValue =
        adminActions.isAutoDaylightSavingEnabled();
    expect(
        previousAutoDaylightSavingValue, isNot(currentAutoDaylightSavingValue));
    final currentCheckIconFinder =
        adminActions.australiaTimezoneCheckIconFinder();
    expect(currentCheckIconFinder, findsOneWidget);
  });
}
