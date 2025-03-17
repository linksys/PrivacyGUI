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
    await tester.pumpFrames(app(), Duration(seconds: 3));
    final login = TestLocalLoginActions(tester);
    await login.inputPassword(IntegrationTestConfig.password);
    expect(
      IntegrationTestConfig.password,
      tester.getText(find.byType(AppPasswordField)),
    );
    await login.tapLoginButton();
    // Enter the dashboard screen
    final dashboardHomeActions = TestDashboardHomeActions(tester);
    await dashboardHomeActions.checkTopologyPage();
    await dashboardHomeActions.checkDeviceListPage();
    await dashboardHomeActions.checkMasterNodeDetailPage();
    await dashboardHomeActions.hoverToNightModeInfoIcon();
    await dashboardHomeActions.toggleNightMode();
    await dashboardHomeActions.hoverToInstantPrivacyInfoIcon();
    await dashboardHomeActions.toggleInstantPrivacy();
    await dashboardHomeActions.checkInstantPrivacyPage();
    await dashboardHomeActions.hoverToWifi24gQrIcon();
    //await dashboardHomeActions.toggle24gWifi(); // cannot turn off all wifi
    await dashboardHomeActions.checkWifi24gPage();
    await dashboardHomeActions.hoverToWifi5gQrIcon();
    await dashboardHomeActions.toggle5gWifi();
    await dashboardHomeActions.checkWifi5gPage();
    await dashboardHomeActions.hoverToGuestWifiQrIcon();
    await dashboardHomeActions.toggleGuestWifi();
    await dashboardHomeActions.checkGuestWifiPage();
  });
}
