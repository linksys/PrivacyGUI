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

    // testWidgets('IPv4 - Set back to DHCP operations', (tester) async {
    //   await tester.pumpFrames(app(), Duration(seconds: 5));
    //   // Enter the menu screen
    //   final topbarActions = TestTopbarActions(tester);
    //   await topbarActions.tapMenuButton();
    //   final menuActions = TestMenuActions(tester);
    //   // Enter Advanced Settings screen
    //   await menuActions.enterAdvancedSettingsPage();
    //   final advancedSettingsActions = TestAdvancedSettingsActions(tester);
    //   await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
    //   // Enter Internet Settings screen
    //   await advancedSettingsActions.enterInternetSettingsPage();
    //   final internetSettingsActions = TestInternetSettingsActions(tester);
    //   await internetSettingsActions.checkTitle(internetSettingsActions.title);
    //   // Switch to IPv4 tab
    //   await internetSettingsActions.tapIpv4Tab();
    //   await internetSettingsActions.tapEditIconButton();
    //   await internetSettingsActions.selectDhcpType();
    //   await internetSettingsActions.selectAutoMtu();
    //   await internetSettingsActions.tapSaveButton();
    //   await internetSettingsActions.tapCancelButton();
    //   await internetSettingsActions.tapSaveButton();
    //   await internetSettingsActions.tapRestartButton();
    //   await tester.pumpAndSettle(Duration(seconds: 15));
    // });

    testWidgets('IPv6 - Automatic operations', (tester) async {
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
      await tester.pumpAndSettle(Duration(seconds: 10));
    });

    testWidgets('IPv6 - PPPoE operations', (tester) async {
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
      // Switch to Release & Renew tab
      await internetSettingsActions.tapReleaseTab();
      await internetSettingsActions.tapIpv6RleaseButton();
      await internetSettingsActions.tapCancelOnReleaseAlertDialog();
      await internetSettingsActions.tapIpv4RleaseButton();
      await internetSettingsActions.tapReleaseOnReleaseAlertDialog();
      // await tester.pumpAndSettle(Duration(seconds: 10));
    });
  });
}
