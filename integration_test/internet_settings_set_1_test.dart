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

    testWidgets('IPv4 - DHCP with Manual MTU operations', (tester) async {
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
      await tester.pumpAndSettle(Duration(seconds: 10));
    });

    testWidgets('IPv4 - Static operations', (tester) async {
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
      await tester.pumpAndSettle(Duration(seconds: 10));
    });

    testWidgets('IPv4 - PPPoE operations', (tester) async {
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
      await tester.pumpAndSettle(Duration(seconds: 10));
    });
  });
}
