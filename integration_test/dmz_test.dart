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

  group('DMZ', () {
    testWidgets('DMZ - login operations', (tester) async {
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

    testWidgets('DMZ - enabling operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      await Future.delayed(const Duration(seconds: 5));
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter DMZ screen
      await advancedSettingsActions.enterDmzPage();
      final dmzActions = TestDmzActions(tester);
      await dmzActions.checkTitle(dmzActions.title);
      // Enable the DMZ function
      await dmzActions.toggleDmzSwitch();
      await dmzActions.tapAutomaticRadio();
      await dmzActions.tapSpecifiedRangeRadio();
      await dmzActions.inputStartSpecifiedIp();
      await dmzActions.inputEndSpecifiedIp();
      await dmzActions.tapDestinationIpRadio();
      await dmzActions.scrollUntil(
        dmzActions.lastDestinationIpFormFieldFinder(),
      );
      await dmzActions.inputLastDestinationIpField();
      await dmzActions.tapDestinationMacRadio();
      await dmzActions.scrollUntil(dmzActions.macTextFieldFinder());
      await dmzActions.inputMacAddress();
      // Go to selecting DHCP client screen
      await dmzActions.tapViewDhcpClientButton();
      await dmzActions.checkSelectDevicesScreen();
      // Go back to the DMZ screen
      await dmzActions.tapBackButton();
      // Save the input data
      await dmzActions.tapSaveButton();
    });
  });
}
