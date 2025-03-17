import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'actions/_actions.dart';
import 'config/integration_test_config.dart';
import 'extensions/extensions.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // init better actions
    initBetterActions();
    // clear all cache data to make sure every test case is independent
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    BuildConfig.load();

    // GetIt
    dependencySetup();
  });

  testWidgets('Menu operations', (tester) async {
    // Load app widget.
    await tester.pumpFrames(app(), Duration(seconds: 3));
    // Log in
    final login = TestLocalLoginActions(tester);
    await login.inputPassword(IntegrationTestConfig.password);
    expect(
      IntegrationTestConfig.password,
      tester.getText(find.byType(AppPasswordField)),
    );
    await login.tapLoginButton();
    // Enter the dashboard screen
    final topbarActions = TestTopbarActions(tester);
    await topbarActions.tapMenuButton();
    // Enter the menu screen
    final menuActions = TestMenuActions(tester);
    // Wifi
    await menuActions.enterWifiPage();
    final wifiActions = TestIncredibleWifiActions(tester);
    await wifiActions.checkTitle(wifiActions.title);
    await wifiActions.tapBackButton();
    // Instant Admin
    await menuActions.enterAdminPage();
    final adminActions = TestInstantAdminActions(tester);
    await adminActions.checkTitle(adminActions.title);
    await adminActions.tapBackButton();
    // Instant Topology
    await menuActions.enterTopologyPage();
    final topologyActions = TestInstantTopologyActions(tester);
    await topologyActions.checkTitle(topologyActions.title);
    await topologyActions.tapBackButton();
    // Instant Safety
    await menuActions.enterSafetyPage();
    final safetyActions = TestInstantSafetyActions(tester);
    await safetyActions.checkTitle(safetyActions.title);
    await safetyActions.tapBackButton();
    // Instant Privacy
    menuActions.privacyBetaLabelFinder(); // Check the beta label
    await menuActions.enterPrivacyPage();
    final privacyActions = TestInstantPrivacyActions(tester);
    await privacyActions.checkTitle(privacyActions.title);
    await privacyActions.tapBackButton();
    // Instant Devices
    await menuActions.enterDevicesPage();
    final devicesActions = TestInstantDevicesActions(tester);
    await devicesActions.checkTitle(devicesActions.title);
    await devicesActions.tapBackButton();
    // Advanced Settings
    await menuActions.enterAdvancedSettingsPage();
    final advancedSettingsActions = TestAdvancedSettingsActions(tester);
    await advancedSettingsActions.checkTitle(advancedSettingsActions.title);
    await advancedSettingsActions.tapBackButton();
    // Instant Verify
    await menuActions.enterVerifyPage();
    final verifyActions = TestInstantVerifyActions(tester);
    await verifyActions.checkTitle(verifyActions.title);
    await verifyActions.tapBackButton();
    // External Speed Test
    await menuActions.enterExternalSpeedTestPage();
    final externalSpeedTestActions = TestExternalSpeedTestActions(tester);
    await externalSpeedTestActions.checkTitle(externalSpeedTestActions.title);
    await externalSpeedTestActions.tapBackButton();
    // Add Nodes
    await menuActions.enterAddNodePage();
    final addNodeActions = TestAddNodesActions(tester);
    await addNodeActions.checkTitle(addNodeActions.title);
    await addNodeActions.tapBackButton();
    // Restart
    await menuActions.tapRestartBtn();
    await menuActions.tapCancelBtn();

  });
}
