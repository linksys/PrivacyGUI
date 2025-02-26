import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'actions/pnp_setup_actions.dart';

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

  testWidgets('Factory reset setup flow golden', (tester) async {
    // Load app widget.
    await tester.pumpFrames(app(), Duration(seconds: 3));

    // Pnp page
    final setup = TestPnpSetupActions(tester);
    await setup.tapContinueButton();
    // Personalize wifi
    await setup.tapNextButton();
    // Guest wifi
    await setup.tapSwitch();
    await setup.tapSwitch();
    await setup.tapNextButton();
    // Night mode
    await setup.tapNextButton();
    await tester.pumpFrames(app(), const Duration(seconds: 60));
    // 
    await setup.tapDoneButton();
    // Done
    await setup.tapDoneButton();

    // Dashboard
      final quickPanelFinder = find.byType(DashboardQuickPanel);
      expect(quickPanelFinder, findsOneWidget);
  });

}

