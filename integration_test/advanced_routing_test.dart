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

  group('Advanced Routing', () {
    testWidgets('Advanced routing - login operations', (tester) async {
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

    testWidgets('Advanced routing - adding and deleting operations',
        (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Advanced routing screen
      await advancedSettingsActions.enterAdvancedRoutingPage();
      final advancedRoutingActions = TestAdvancedRoutingActions(tester);
      await advancedRoutingActions.checkTitle(advancedRoutingActions.title);
      // Switch to dynamic routing
      await advancedRoutingActions.tapDynamicRoutingRadioButton();
      // Switch to NAT routing
      await advancedRoutingActions.tapNatRadioButton();
      // Add a new static routing
      await advancedRoutingActions.tapAddRoutingButton();
      // Tap cancel at first
      await advancedRoutingActions.tapCloseIconButton();
      // Add a new static routing
      await advancedRoutingActions.tapAddRoutingButton();
      // Input the new routing name
      await advancedRoutingActions.inputRoutingName();
      // Input the destination IP
      await advancedRoutingActions.inputDestinationIp();
      // Input the gateway IP
      await advancedRoutingActions.inputGatewayIpForInternetInterface();
      // Change interface to Internet
      await advancedRoutingActions.selectInternetInterface();
      // Commit the static routing data
      await advancedRoutingActions.tapCheckIconButton();
      // Remove the current one
      await advancedRoutingActions.tapDeleteIconButton();
      // Add a new static routing again
      await advancedRoutingActions.tapAddRoutingButton();
      // Input the new routing name
      await advancedRoutingActions.inputRoutingName();
      // Input the destination IP
      await advancedRoutingActions.inputDestinationIp();
      // Input the gateway IP
      await advancedRoutingActions.inputGatewayIpForInternetInterface();
      // Change the interface to LAN/Wireless
      await advancedRoutingActions.selectLanWirelessInterface();
      // Change the interface to Internet
      await advancedRoutingActions.selectInternetInterface();
      // Commit the static routing data
      await advancedRoutingActions.tapCheckIconButton();
      // Save
      await advancedRoutingActions.tapSaveButton();
      // Re-enter Advanced Routing screen
      await advancedRoutingActions.tapBackButton();
      await advancedSettingsActions.enterAdvancedRoutingPage();
      // Verify updated values
      await advancedRoutingActions.checkSavedRoutingName();
    });

    testWidgets('Advanced routing - Incorrect input operations',
        (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Advanced routing screen
      await advancedSettingsActions.enterAdvancedRoutingPage();
      final advancedRoutingActions = TestAdvancedRoutingActions(tester);
      await advancedRoutingActions.checkTitle(advancedRoutingActions.title);
      // Add a new static routing
      await advancedRoutingActions.tapAddRoutingButton();
      // Tap the name field
      await advancedRoutingActions.tapRoutingNameField();
      await advancedRoutingActions.tapRoutingNameField();
      // Tap the destination IP field
      await advancedRoutingActions.tapLastDestinationIpField();
      await advancedRoutingActions.tapLastDestinationIpField();
      // Tap the gateway IP field
      await advancedRoutingActions.tapLastGatewayIpField();
      await advancedRoutingActions.tapLastGatewayIpField();
    });
  });
}
