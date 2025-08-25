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

  group('Apps and Gaming', () {
    testWidgets('Apps and Gaming - login operations', (tester) async {
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

    testWidgets('Apps and Gaming - DDNS operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Apps Gaming screen
      await advancedSettingsActions.enterAppsAndGamingPage();
      final appsGamingActions = TestAppsAndGamingActions(tester);
      await appsGamingActions.checkTitle(appsGamingActions.title);
      // Switch to DDNS tab
      await appsGamingActions.tapDdnsTab();
      // Select dyn provider
      await appsGamingActions.selectDynProvider();
      // Input data
      await appsGamingActions.inputUsername();
      await appsGamingActions.inputPassword();
      await appsGamingActions.inputHostname();
      await appsGamingActions.selectStaticSystem();
      await appsGamingActions.inputMailExchange();
      await appsGamingActions.toggleBackMxSwitch();
      await appsGamingActions.toggleWildcardSwitch();
      // Save the data
      await appsGamingActions.tapSaveButton();
      // Examine the result of saving
      await appsGamingActions.tapBackButton();
      await advancedSettingsActions.enterAppsAndGamingPage();
      await appsGamingActions.tapDdnsTab();
      await appsGamingActions.checkSavedItems();
    });

    testWidgets('Apps and Gaming - Single port forwarding operations',
        (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Apps Gaming screen
      await advancedSettingsActions.enterAppsAndGamingPage();
      final appsGamingActions = TestAppsAndGamingActions(tester);
      await appsGamingActions.checkTitle(appsGamingActions.title);
      // Switch to the single port forwarding tab
      await appsGamingActions.tapPortForwardingTab();
      // Add a new single port forwarding
      await appsGamingActions.tapAddNewButton();
      await appsGamingActions.inputForwardingAppName();
      await appsGamingActions.inputInternalPort();
      await appsGamingActions.inputExternalPort();
      await appsGamingActions.selectTcpProtocol();
      await appsGamingActions.selectUdpProtocol();
      await appsGamingActions.selectBothProtocol();
      await appsGamingActions.inputLastDeviceIp();
      // Commit the data
      await appsGamingActions.tapCheckIconButton();
      // Check edit button
      await appsGamingActions.tapEditIconButton();
      await appsGamingActions.tapCheckIconButton();
      // Check delete button
      await appsGamingActions.tapDeleteIconButton();
      // Re-enter the data again
      await appsGamingActions.tapAddNewButton();
      await appsGamingActions.inputForwardingAppName();
      await appsGamingActions.inputInternalPort();
      await appsGamingActions.inputExternalPort();
      await appsGamingActions.selectBothProtocol();
      await appsGamingActions.inputLastDeviceIp();
      await appsGamingActions.tapCheckIconButton();
      // Save the data
      await appsGamingActions.tapSaveButton();
      // Examine the result of saving
      await appsGamingActions.tapBackButton();
      await advancedSettingsActions.enterAppsAndGamingPage();
      await appsGamingActions.tapPortForwardingTab();
      await appsGamingActions.checkSavedItems();
    });  

    testWidgets('Apps and Gaming - Port range forwarding operations',
        (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Apps Gaming screen
      await advancedSettingsActions.enterAppsAndGamingPage();
      final appsGamingActions = TestAppsAndGamingActions(tester);
      await appsGamingActions.checkTitle(appsGamingActions.title);
      // Switch to the port range forwarding tab
      await appsGamingActions.tapRangeForwardingTab();
      // Add a new port range forwarding
      await appsGamingActions.tapAddNewButton();
      await appsGamingActions.inputForwardingAppName();
      await appsGamingActions.inputStartPort();
      await appsGamingActions.inputEndPort();
      await appsGamingActions.selectTcpProtocol();
      await appsGamingActions.selectBothProtocol();
      await appsGamingActions.selectUdpProtocol();
      await appsGamingActions.inputLastDeviceIp();
      // Commit the data
      await appsGamingActions.tapCheckIconButton();
      await appsGamingActions.tapEditIconButton();
      await appsGamingActions.tapCheckIconButton();
      await appsGamingActions.tapDeleteIconButton();
      // Re-enter the data again
      await appsGamingActions.tapAddNewButton();
      await appsGamingActions.inputForwardingAppName();
      await appsGamingActions.inputStartPort();
      await appsGamingActions.inputEndPort();
      await appsGamingActions.selectUdpProtocol();
      await appsGamingActions.inputLastDeviceIp();
      await appsGamingActions.tapCheckIconButton();
      // Save the data
      await appsGamingActions.tapSaveButton();
      // Examine the result of saving
      await appsGamingActions.tapBackButton();
      await advancedSettingsActions.enterAppsAndGamingPage();
      await appsGamingActions.tapRangeForwardingTab();
      await appsGamingActions.checkSavedItems();
    });

    testWidgets('Apps and Gaming - Port range triggering operations',
        (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Apps Gaming screen
      await advancedSettingsActions.enterAppsAndGamingPage();
      final appsGamingActions = TestAppsAndGamingActions(tester);
      await appsGamingActions.checkTitle(appsGamingActions.title);
      // Switch to the port range triggering tab
      await appsGamingActions.tapRangeTriggeringTab();
      // Add a new port range triggering
      await appsGamingActions.tapAddNewButton();
      await appsGamingActions.inputTriggeringAppName();
      await appsGamingActions.inputStartTriggeredRange();
      await appsGamingActions.inputEndTriggeredRange();
      await appsGamingActions.inputStartForwardedRange();
      await appsGamingActions.inputEndForwardedRange();
      // Commit the data
      await appsGamingActions.tapCheckIconButton();
      await appsGamingActions.tapEditIconButton();
      await appsGamingActions.tapCheckIconButton();
      await appsGamingActions.tapDeleteIconButton();
      // Re-enter the data again
      await appsGamingActions.tapAddNewButton();
      await appsGamingActions.inputTriggeringAppName();
      await appsGamingActions.inputStartTriggeredRange();
      await appsGamingActions.inputEndTriggeredRange();
      await appsGamingActions.inputStartForwardedRange();
      await appsGamingActions.inputEndForwardedRange();
      await appsGamingActions.tapCheckIconButton();
      // Save the data
      await appsGamingActions.tapSaveButton();
      // Examine the result of saving
      await appsGamingActions.tapBackButton();
      await advancedSettingsActions.enterAppsAndGamingPage();
      await appsGamingActions.tapRangeTriggeringTab();
      await appsGamingActions.checkSavedItems();
    });
  });
}
