import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/widgets/input_field/app_password_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'actions/base_actions.dart';
import 'config/integration_test_config.dart';
import 'extensions/extensions.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const newWifiName = IntegrationTestConfig.newWifiName;
  final wifiBands = IntegrationTestConfig.wifiBands.split(',');

  setUpAll(() async {
    // GetIt
    dependencySetup();

    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // init better actions
    initBetterActions();

    BuildConfig.load();

    // clear all cache data to make sure every test case is independent
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  });

  setUp(() async {});

  tearDown(() async {
    // Add any cleanup logic here if needed after each test
  });

  group('Incredible Wifi - Test Advanced tab', () {
    testWidgets('Incredible Wifi - Log in and enter dashboard', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 3));
      // Log in
      final login = TestLocalLoginActions(tester);
      await login.inputPassword(IntegrationTestConfig.password);
      expect(
        IntegrationTestConfig.password,
        tester.getText(find.byType(AppPasswordField)),
      );
      // Log in and enter the dashboard screen
      await login.tapLoginButton();
    });

    testWidgets('Incredible Wifi - Test all switchs', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu page
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      // Enter the wifi page
      final menuActions = TestMenuActions(tester);
      await menuActions.enterWifiPage();
      final wifiActions = TestIncredibleWifiActions(tester);
      await wifiActions.checkTitle(wifiActions.title);
      // Start testing
      // Go to Advanced tab
      await wifiActions.tapAdvancedTab();
      // Test all switch
      await wifiActions.tapClientSteeringSwitch();
      await wifiActions.tapNodeSteeringSwitch();
      await wifiActions.tapDFSSwitch();
      await wifiActions.tapMloSwitch();
      await wifiActions.tapSaveBtn();
      wifiActions.checkDFSAlert();
      await wifiActions.tapAlertOkBtn();
      await tester.pumpAndSettle();
    });

    testWidgets('Incredible Wifi - Test MLO alert', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu page
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      // Enter the wifi page
      final menuActions = TestMenuActions(tester);
      await menuActions.enterWifiPage();
      final wifiActions = TestIncredibleWifiActions(tester);
      await wifiActions.checkTitle(wifiActions.title);
      // Start testing
      // Check the MLO alert
      if (wifiBands.contains('2.4')) {
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '2.4');
        await wifiActions.tapWifiNameCard();
        await wifiActions.inputWifiName('$newWifiName-2_');
        await wifiActions.tapAlertSaveBtn();
      }
      if (wifiBands.contains('5')) {
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '5');
        await wifiActions.tapWifiNameCard();
        await wifiActions.inputWifiName('$newWifiName-5_');
        await wifiActions.tapAlertSaveBtn();
      }
      if (wifiBands.contains('6')) {
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '6');
        await wifiActions.tapWifiNameCard();
        await wifiActions.inputWifiName('$newWifiName-6_');
        await wifiActions.tapAlertSaveBtn();
      }
      await wifiActions.tapSaveBtn();
      wifiActions.checkMLOAlert();
      await wifiActions.tapAlertOkBtn();
      // Go to Advanced tab
      await wifiActions.tapAdvancedTab();
      wifiActions.checkMLOAlert();
      await tester.pumpAndSettle();
    });

    testWidgets('Incredible Wifi - Test mac filtering', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu page
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      // Enter the wifi page
      final menuActions = TestMenuActions(tester);
      await menuActions.enterWifiPage();
      final wifiActions = TestIncredibleWifiActions(tester);
      await wifiActions.checkTitle(wifiActions.title);
      // Start testing
      // Go to Mac Filtering tab
      await wifiActions.tapMacFilteringTab();
      // Enable mac filtering
      await wifiActions.tapMacFilteringSwitch();
      wifiActions.checkDeviceCount(0);
      // Go to filtered devices page
      await wifiActions.goToFilteredDevices();
      wifiActions.checkNoFilteredDevice();
      // Check select device page
      await wifiActions.tapSelectDevice();
      wifiActions.checkSelectDevicesTitle();
      await wifiActions.tapBackButton();
      // Add devices
      await wifiActions.tapManuallyAddDevice();
      await wifiActions.inputMacAddress('AA:AA:AA:AA:AA:AA');
      await wifiActions.tapAlertSaveBtn();
      wifiActions.checkFilteredDevice('AA:AA:AA:AA:AA:AA');
      await wifiActions.tapManuallyAddDevice();
      await wifiActions.inputMacAddress('BB:BB:BB:BB:BB:BB');
      await wifiActions.tapAlertSaveBtn();
      wifiActions.checkFilteredDevice('BB:BB:BB:BB:BB:BB');
      await wifiActions.tapDoneButton();
      wifiActions.checkDeviceCount(2);
      // Remove devices
      await wifiActions.goToFilteredDevices();
      await wifiActions.tapEditButton();
      await wifiActions.tapFilteredDevice('BB:BB:BB:BB:BB:BB');
      await wifiActions.tapRemoveButton();
      await wifiActions.tapDoneButton();
      wifiActions.checkDeviceCount(1);
      // Save settings
      await wifiActions.tapSaveBtn();
      await wifiActions.tapTurnOnButton();
      await tester.pumpAndSettle();
      // Re-enter wifi page to check if save success
      await wifiActions.tapBackButton();
      await menuActions.enterWifiPage();
      await wifiActions.tapMacFilteringTab();
      wifiActions.checkDeviceCount(1);
    });

    testWidgets('Incredible Wifi - Test the instant privacy warning', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu page
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      // Start testing
      // Enter the instant privacy page
      final menuActions = TestMenuActions(tester);
      await menuActions.enterPrivacyPage();
      final privacyActions = TestInstantPrivacyActions(tester);
      await privacyActions.checkTitle(privacyActions.title);
      // Enable instant privacy
      await privacyActions.tapEnableSwitch();
      await privacyActions.tapTurnOnButton();
      await tester.pumpAndSettle();
      // Enter the wifi page
      await topbarActions.tapMenuButton();
      await menuActions.enterWifiPage();
      final wifiActions = TestIncredibleWifiActions(tester);
      await wifiActions.checkTitle(wifiActions.title);
      // Go to Mac Filtering tab and check the instant privacy warning
      await wifiActions.tapMacFilteringTab();
      wifiActions.checkInstantPrivacyWarning();
      await tester.pumpAndSettle();
    });

  });
}
