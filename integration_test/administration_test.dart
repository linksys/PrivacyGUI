import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'actions/base_actions.dart';
import 'config/integration_test_config.dart';
import 'extensions/extensions.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dependencySetup();
    initBetterActions();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    BuildConfig.load();
  });

  group('Administration', () {
    testWidgets('Administration - login operations', (tester) async {
      // Log in
      await tester.pumpFrames(app(), Duration(seconds: 3));

      final login = TestLocalLoginActions(tester);
      await login.inputPassword(IntegrationTestConfig.password);
      expect(
        IntegrationTestConfig.password,
        tester.getText(find.byType(AppPasswordField)),
      );
      await login.tapLoginButton();
    });

    testWidgets('Administration operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Administration screen
      await advancedSettingsActions.enterAdministrationPage();
      final administrationActions = TestAdministrationActions(tester);
      await administrationActions.checkTitle(administrationActions.title);
      // Record the current status
      final previousValue1 = administrationActions.isAllowToConfigureChecked();
      final previousValue2 = administrationActions.isAllowToDisableChecked();
      final previousValue3 = administrationActions.isSipSwitchEnabled();
      final previousValue4 =
          administrationActions.isExpressForwardingSwitchEnabled();
      // Disable the local management wirelessly if it exists
      if (administrationActions.isManageWirelesslySupported()) {
        await administrationActions.toggleManageWirelesslySwitch();
      }
      // Disable the UPnP switch
      await administrationActions.toggleUpnpSwitch();
      // Check all checkboxes are hidden
      administrationActions.checkAllCheckboxHidden();
      // Enable the UPnP switch again
      await administrationActions.toggleUpnpSwitch();
      // Toggle two checkboxes
      await administrationActions.tapAllowToConfigureCheckbox();
      await administrationActions.tapAllowToDisableInternetCheckbox();
      // Toggle the SIP switch
      await administrationActions.toggleSipSwitch();
      // Toggle the Express Forwarding switch
      await administrationActions.toggleExpressForwardingSwitch();
      // Tap the save button
      await administrationActions.tapSaveButton();
      // Re-enter the Administration screen
      await administrationActions.tapBackButton();
      await advancedSettingsActions.enterAdministrationPage();
      // Verify updated values
      final currentValue1 = administrationActions.isAllowToConfigureChecked();
      final currentValue2 = administrationActions.isAllowToDisableChecked();
      final currentValue3 = administrationActions.isSipSwitchEnabled();
      final currentValue4 =
          administrationActions.isExpressForwardingSwitchEnabled();
      expect(previousValue1, isNot(currentValue1));
      expect(previousValue2, isNot(currentValue2));
      expect(previousValue3, isNot(currentValue3));
      expect(previousValue4, isNot(currentValue4));
    });
  });
}
