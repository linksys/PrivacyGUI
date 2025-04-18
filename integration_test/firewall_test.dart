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

  group('Firewall', () {
    testWidgets('Firewall - login operations', (tester) async {
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

    testWidgets('Firewall - Firewall tab operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Firewall screen
      await advancedSettingsActions.enterFirewallPage();
      final firewallActions = TestFirewallActions(tester);
      await firewallActions.checkTitle(firewallActions.title);
      // Tap the Firewall tab
      await firewallActions.tapFirewallTab();
      await firewallActions.toggleIpv4ProtectionSwitch();
      await firewallActions.toggleIpv6ProtectionSwitch();
      await firewallActions.tapSaveButton();
    });

    testWidgets('Firewall - VPN Passthrough tab operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Firewall screen
      await advancedSettingsActions.enterFirewallPage();
      final firewallActions = TestFirewallActions(tester);
      await firewallActions.checkTitle(firewallActions.title);
      // Tap the VPN Passthrough tab
      await firewallActions.tapVpnPassthroughTab();
      await firewallActions.toggleIpSecSwitch();
      await firewallActions.togglePptpSwitch();
      await firewallActions.toggleL2tpSwitch();
      await firewallActions.tapSaveButton();
    });

    testWidgets('Firewall - Internet filters tab operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Firewall screen
      await advancedSettingsActions.enterFirewallPage();
      final firewallActions = TestFirewallActions(tester);
      await firewallActions.checkTitle(firewallActions.title);
      // Tap the Internet filters tab
      await firewallActions.tapInternetFiltersTab();
      await firewallActions.toggleAnonymousSwitch();
      await firewallActions.toggleMulticastSwitch();
      await firewallActions.toggleInternetNatRedirectionSwitch();
      await firewallActions.toggleIdentSwitch();
      await firewallActions.tapSaveButton();
    });

    testWidgets('Firewall - IPv6 port services tab operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Firewall screen
      await advancedSettingsActions.enterFirewallPage();
      final firewallActions = TestFirewallActions(tester);
      await firewallActions.checkTitle(firewallActions.title);
      // Tap the IPv6 port services tab
      await firewallActions.tapIpv6PortServicesTab();
      // Tap add new IP button
      await firewallActions.tapAddIpv6Button();
      // Tap the close button
      await firewallActions.tapCloseIconButton();
      // Tap add new IP button again
      await firewallActions.tapAddIpv6Button();
      // Input the application name
      await firewallActions.inputName();
      // Select all protocols
      await firewallActions.selectTcpProtocol();
      await firewallActions.selectUdpProtocol();
      await firewallActions.selectBothProtocol();
      // Input device IP in IPv6 format
      await firewallActions.inputIpv6Address();
      // Input the start and end ports
      await firewallActions.inputStartPort();
      await firewallActions.inputEndPort();
      // Tap the check button
      await firewallActions.tapCheckIconButton();
      // Tap edit button
      await firewallActions.tapEditIconButton();
      // Tap the check button
      await firewallActions.tapCheckIconButton();
      // Delete the current commit
      await firewallActions.tapDeleteIconButton();
      ////////
      // Tap add new IP button again
      await firewallActions.tapAddIpv6Button();
      // Input the application name
      await firewallActions.inputName();
      // Select all protocols
      await firewallActions.selectBothProtocol();
      // Input device IP in IPv6 format
      await firewallActions.inputIpv6Address();
      // Input the start and end ports
      await firewallActions.inputStartPort();
      await firewallActions.inputEndPort();
      // Tap the check button
      await firewallActions.tapCheckIconButton();
      // Save
      await firewallActions.tapSaveButton();
      // Re-enter Firewall screen
      await firewallActions.tapBackButton();
      await advancedSettingsActions.enterFirewallPage();
      // Change to the IPv6 port services tab
      await firewallActions.tapIpv6PortServicesTab();
      // Verify updated values
      await firewallActions.checkSavedApplicationName();
    });

    testWidgets('Firewall - Error operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Firewall screen
      await advancedSettingsActions.enterFirewallPage();
      final firewallActions = TestFirewallActions(tester);
      await firewallActions.checkTitle(firewallActions.title);
      // Tap the IPv6 port services tab
      await firewallActions.tapIpv6PortServicesTab();
      await firewallActions.tapAddIpv6Button();
      await firewallActions.tapNameTextField();
      await firewallActions.tapLastIpv6FormField();
      await firewallActions.inputIncorrectPorts();
      await firewallActions.tapLastIpv6FormField(); // Unfocus the port fields
      await firewallActions.tapStartPortTextField();
      await firewallActions.tapLastIpv6FormField();
    });
  });
}
