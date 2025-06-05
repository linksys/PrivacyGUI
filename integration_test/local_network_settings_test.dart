import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'actions/base_actions.dart';
import 'config/integration_test_config.dart';

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

  Future<TestLocalNetworkSettingsActions> enterLocalNetworkSettings(
      WidgetTester tester) async {
    await tester.pumpFrames(app(), const Duration(seconds: 3));
    final topbarActions = TestTopbarActions(tester);
    await topbarActions.tapMenuButton();
    final menuActions = TestMenuActions(tester);
    await menuActions.enterAdvancedSettingsPage();
    final advancedSettingsActions = TestAdvancedSettingsActions(tester);
    await advancedSettingsActions.enterLocalNetworkSettingsPage();
    final localNetworkSettingsActions = TestLocalNetworkSettingsActions(tester);
    await localNetworkSettingsActions
        .checkTitle(localNetworkSettingsActions.title);
    return localNetworkSettingsActions;
  }

  group('Local Network Settings - Log in', () {
    testWidgets('Local Network Settings - Log in ', (tester) async {
      await tester.pumpFrames(app(), const Duration(seconds: 3));
      final login = TestLocalLoginActions(tester);
      await login.inputPassword(IntegrationTestConfig.password);
      await login.tapLoginButton();
    });
  });

  group('Local Network Settings - Host Name Tab', () {
    testWidgets('Local Network Settings - Valid and invalid host name', (tester) async {
      final actions = await enterLocalNetworkSettings(tester);
      await actions.tapHostNameTab();
      // Invalid
      await actions.inputHostName('Invalid Host Name!');
      await actions.verifyInvalidHostName();
      await actions.inputHostName('');
      await actions.verifyEmptyHostName();
      // Valid
      await actions.inputHostName('TestHostName');
      await actions.verifyHostName('TestHostName');
      // Save and check
      await actions.tapSaveButton();
      await actions.tapBackButton();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.enterLocalNetworkSettingsPage();
      await actions.verifyHostName('TestHostName');
    });
  });

  group('Local Network Settings - LAN IP Address Tab', () {
    testWidgets('Local Network Settings - Valid and invalid IP address and subnet mask', (tester) async {
      final actions = await enterLocalNetworkSettings(tester);
      await actions.tapLanIPAddressTab();
      // Invalid IP
      await tester.tap(actions.ipAddressFieldFinder());
      await tester.pumpAndSettle(Duration(seconds: 5));
      await actions.inputIPAddress('0.0.0.0');
      await actions.verifyIpAddressInvalid();
      // Invalid subnet mask
      await actions.inputSubnetMask('255.255.0.255');
      await actions.verifySubnetMaskInvalid();
      // Valid
      await actions.inputIPAddress('192.168.1.1');
      await actions.inputSubnetMask('255.255.255.0');
      await actions.verifyIPAddress('192.168.1.1');
      await actions.verifySubnetMask('255.255.255.0');
      // Save and check
      await actions.tapSaveButton();
      await actions.tapBackButton();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.enterLocalNetworkSettingsPage();
      await actions.tapLanIPAddressTab();
      await actions.verifyIPAddress('192.168.1.1');
      await actions.verifySubnetMask('255.255.255.0');
    });
  });

  group('Local Network Settings - DHCP Server Tab', () {
    testWidgets('Local Network Settings - Valid and invalid DHCP Server settings', (tester) async {
      final actions = await enterLocalNetworkSettings(tester);
      await actions.tapDHCPServerTab();
      await actions.toggleDHCPServer(false);
      await actions.verifyDHCPServerDisable();
      await actions.toggleDHCPServer(true);
      await actions.verifyDHCPServerEnable();
      // Invalid 
      await actions.inputStartIPAddress('192.168.1.0');
      await actions.verifyStartIPAddressNotInValidRange();
      await actions.inputStartIPAddress('192.168.1.1');
      await actions.verifyStartIPAddressInvalid();
      await actions.inputDNS1('0.0.0.0');
      await actions.inputDNS2('0.0.0.0');
      await actions.inputDNS3('0.0.0.0');
      await actions.inputWINS('0.0.0.0');
      await actions.verifyDnsAndWinsInvalid();
      // Valid
      await actions.inputStartIPAddress('192.168.1.100');
      await actions.inputMaxUsers('50');
      await actions.inputClientLeaseTime('1400');
      await actions.inputDNS1('8.8.8.8');
      await actions.inputDNS2('8.8.4.4');
      await actions.inputDNS3('1.1.1.1');
      await actions.inputWINS('192.168.1.10');
      await actions.tapSaveButton();
      // Save and check
      await actions.tapBackButton();
      final advancedSettingsActions = TestAdvancedSettingsActions(tester);
      await advancedSettingsActions.enterLocalNetworkSettingsPage();
      await actions.tapDHCPServerTab();
      await actions.verifyStartIPAddress('192.168.1.100');
      await actions.verifyMaxUsers('50');
      await actions.verifyClientLeaseTime('1400');
      await actions.verifyDNS1('8.8.8.8');
      await actions.verifyDNS2('8.8.4.4');
      await actions.verifyDNS3('1.1.1.1');
      await actions.verifyWINS('192.168.1.10');
    });
  });
}
