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

  group('Internet Settings', () {
    testWidgets('Login operations', (tester) async {
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

    testWidgets('IPv4 - DHCP operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectDhcpType();
      await internetSettingsActions.selectAutoMtu();
      await internetSettingsActions.selectManualMtu();
      await internetSettingsActions.inputMtuSize();
      await internetSettingsActions.toggleMacCloneSwitch();
      await internetSettingsActions.tapCloneMacButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });

    testWidgets('IPv4 - Static operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectStaticIpType();
      await internetSettingsActions.inputIpv4StaticAddress();
      await internetSettingsActions.inputIpv4StaticSubmask();
      await internetSettingsActions.inputIpv4StaticGateway();
      await internetSettingsActions.scrollUntil(
        internetSettingsActions.ipv4StaticDns1FieldFinder().last,
      );
      await internetSettingsActions.inputIpv4StaticDns1();
      await internetSettingsActions.scrollUntil(
        internetSettingsActions.ipv4StaticDns2FieldFinder().last,
      );
      await internetSettingsActions.inputIpv4StaticDns2();
      await internetSettingsActions.scrollUntil(
        internetSettingsActions.ipv4StaticDns3FieldFinder().last,
      );
      await internetSettingsActions.inputIpv4StaticDns3();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });

    testWidgets('IPv4 - PPPoE operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectPppoeType();
      await internetSettingsActions.inputPppoeUserName();
      await internetSettingsActions.inputPppoePassword();
      await internetSettingsActions.inputPppoeVlanId();
      await internetSettingsActions.inputPppoeServiceName();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.keepAliveRadioFinder(),
      );
      await internetSettingsActions.inputRedialPeriod();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.connectOnDemandRadioFinder(),
      );
      await internetSettingsActions.inputMaxIdleTime();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });

    testWidgets('IPv4 - PPTP (DHCP IP) operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectPptpType();
      await internetSettingsActions.tapPPtpAutoIpRadio();
      await internetSettingsActions.inputServerIpv4Address();
      await internetSettingsActions.inputUserName();
      await internetSettingsActions.inputPassword();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.keepAliveRadioFinder(),
      );
      await internetSettingsActions.inputRedialPeriod();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.connectOnDemandRadioFinder(),
      );
      await internetSettingsActions.inputMaxIdleTime();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });

    testWidgets('IPv4 - PPTP (Specify IP) operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectPptpType();
      await internetSettingsActions.tapPPtpSpecifyIpRadio();
      await internetSettingsActions.scrollUntil(
        internetSettingsActions.ipv4PptpGatewaysFieldFinder().first,
      );
      await internetSettingsActions.inputIpv4PptpAddress();
      await internetSettingsActions.inputIpv4PptpSubmask();
      await internetSettingsActions.inputIpv4PptpGateway();
      await internetSettingsActions.scrollUntil(
        internetSettingsActions.ipv4PptpDns3FieldFinder().first,
      );
      await internetSettingsActions.inputIpv4PptpDns1();
      await internetSettingsActions.inputIpv4PptpDns2();
      await internetSettingsActions.inputIpv4PptpDns3();

      await internetSettingsActions.scrollUntil(
        internetSettingsActions.ipv4PasswordTextfieldFinder(),
      );
      await internetSettingsActions.inputServerIpv4Address();
      await internetSettingsActions.inputUserName();
      await internetSettingsActions.inputPassword();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.keepAliveRadioFinder(),
      );
      await internetSettingsActions.inputRedialPeriod();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.connectOnDemandRadioFinder(),
      );
      await internetSettingsActions.inputMaxIdleTime();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });

    testWidgets('IPv4 - L2TP operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectL2tpType();
      await internetSettingsActions.inputServerIpv4Address();
      await internetSettingsActions.inputUserName();
      await internetSettingsActions.inputPassword();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.keepAliveRadioFinder(),
      );
      await internetSettingsActions.inputRedialPeriod();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.connectOnDemandRadioFinder(),
      );
      await internetSettingsActions.inputMaxIdleTime();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });

    testWidgets('IPv4 - Bridge mode operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectBridgeType();
    });

    testWidgets('IPv4 - Set back to DHCP operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to IPv4 tab
      await internetSettingsActions.tapIpv4Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectDhcpType();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });
    
    testWidgets('IPv6 - Automatic operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Check if the current IPv4 setting is DHCP
      await internetSettingsActions.checkIpv4DhcpType();
      // Switch to IPv6 tab
      await internetSettingsActions.tapIpv6Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectIPv6AutomaticType();
      await internetSettingsActions.tapIpv6AutomaticCheckbox();
      await internetSettingsActions.selectIpv6TunnelDisabled();
      await internetSettingsActions.selectIpv6TunnelAutomatic();
      await internetSettingsActions.selectIpv6TunnelManual();
      await internetSettingsActions.scrollAndTap(
        internetSettingsActions.ipv6BorderRelayLengthTextfieldFinder(),
      );
      await internetSettingsActions.inputPrefix();
      await internetSettingsActions.inputPrefixLength();
      await internetSettingsActions.inputBorderRelay();
      await internetSettingsActions.inputBorderRelayLength();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
    });

    testWidgets('IPv6 - PPPoE operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Check if the current IPv4 setting is DHCP
      await internetSettingsActions.checkIpv4DhcpType();
      // Switch to IPv6 tab
      await internetSettingsActions.tapIpv6Tab();
      await internetSettingsActions.tapEditIconButton();
      await internetSettingsActions.selectIPv6PppoeType();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapCancelButton();
      await internetSettingsActions.tapSaveButton();
      await internetSettingsActions.tapRestartButton();
      // Check if the error prompt pops up
      expect(internetSettingsActions.errorAlertDialogFinder(), findsOneWidget);
      await internetSettingsActions.tapOkOnErrorAlertDialog();
    });

    testWidgets('IPv6 - Release & Renew operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Advanced Settings screen
      await menuActions.enterAdvancedSettingsPage();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
      // Enter Internet Settings screen
      await advancedSettingsActions.enterInternetSettingsPage();
      final internetSettingsActions = TestInternetSettingsActions(tester);
      await internetSettingsActions.checkTitle(internetSettingsActions.title);
      // Switch to Release & Renew tab
      await internetSettingsActions.tapReleaseTab();
      await internetSettingsActions.tapIpv6RleaseButton();
      await internetSettingsActions.tapCancelOnReleaseAlertDialog();
      await internetSettingsActions.tapIpv4RleaseButton();
      await internetSettingsActions.tapReleaseOnReleaseAlertDialog();
    });
  });
}
