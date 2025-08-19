import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'actions/base_actions.dart';
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

  testWidgets('Dashboard home operations', (tester) async {
    // Log in
    await tester.pumpFrames(app(), Duration(seconds: 5));
    final login = TestLocalLoginActions(tester);
    await login.inputPassword(IntegrationTestConfig.password);
    expect(
      IntegrationTestConfig.password,
      tester.getText(login.passwordFieldFinder()),
    );
    await login.tapLoginButton();
    // Enter the dashboard screen
    final dashboardHomeActions = TestDashboardHomeActions(tester);
    await dashboardHomeActions.checkTopologyPage();
    await dashboardHomeActions.checkDeviceListPage();
    await dashboardHomeActions.checkMasterNodeDetailPage();
    await dashboardHomeActions.hoverToNightModeInfoIcon();
    //
    await dashboardHomeActions.toggleNightMode();
    //
    await dashboardHomeActions.toggleNightMode();
    await dashboardHomeActions.hoverToInstantPrivacyInfoIcon();
    //
    await dashboardHomeActions.toggleInstantPrivacy();
    //
    await dashboardHomeActions.toggleInstantPrivacy();
    await dashboardHomeActions.checkInstantPrivacyPage();

    // Speed Test
    const isHealthCheckSupported = String.fromEnvironment(
            'isHealthCheckSupported',
            defaultValue: 'false') ==
        'true';

    if (isHealthCheckSupported) {
      // Speed Test
      await dashboardHomeActions.startSpeedTest();
      await dashboardHomeActions.checkSpeedTestResult();
    }

    //WiFi cards
    const bands =
        String.fromEnvironment('wifiBands', defaultValue: '2.4,5,guest');
    final bandsList = bands.split(',').map((e) => e.trim()).toList();
    if (bandsList.contains('2.4')) {
      await dashboardHomeActions.hoverToWifi24gQrIcon();
      await dashboardHomeActions.toggle24gWifi();
      await dashboardHomeActions.toggle24gWifi();

      await dashboardHomeActions.checkWifi24gPage();
    }
    if (bandsList.contains('5')) {
      await dashboardHomeActions.hoverToWifi5gQrIcon();
      await dashboardHomeActions.toggle5gWifi();
      await dashboardHomeActions.toggle5gWifi();
      await dashboardHomeActions.checkWifi5gPage();
    }
    if (bandsList.contains('6')) {
      await dashboardHomeActions.hoverToWifi6gQrIcon();
      await dashboardHomeActions.toggle6gWifi();
      await dashboardHomeActions.toggle6gWifi();
      await dashboardHomeActions.checkWifi6gPage();
    }
    if (bandsList.contains('guest')) {
      await dashboardHomeActions.hoverToGuestWifiQrIcon();
      await dashboardHomeActions.toggleGuestWifi();
      await dashboardHomeActions.toggleGuestWifi();
      await dashboardHomeActions.checkGuestWifiPage();
    }
  });
}
