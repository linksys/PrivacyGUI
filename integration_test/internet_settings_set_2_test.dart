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
  integrationDriver(timeout: const Duration(minutes: 30));
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
      await tester.pumpFrames(app(), Duration(seconds: 5));

      final login = TestLocalLoginActions(tester);
      await login.inputPassword(IntegrationTestConfig.password);
      expect(
        IntegrationTestConfig.password,
        tester.getText(find.byType(AppPasswordField)),
      );
      await login.tapLoginButton();
    });
/* TODO: Fix testing errors

    testWidgets('IPv4 - PPTP (DHCP IP) operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
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
      await tester.pumpAndSettle(Duration(seconds: 25));
    });

    testWidgets('IPv4 - PPTP (Specify IP) operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
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
      await tester.pumpAndSettle(Duration(seconds: 10));
    });

    testWidgets('IPv4 - L2TP operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
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
      await tester.pumpAndSettle(Duration(seconds: 10));
    });
*/
    testWidgets('IPv4 - Bridge mode operations', (tester) async {
      await tester.pumpFrames(app(), Duration(seconds: 5));
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
  });
}
