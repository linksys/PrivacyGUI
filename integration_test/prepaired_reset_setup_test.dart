import 'package:flutter/widgets.dart';
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

import 'actions/prepair_pnp_setup_actions.dart';
import 'config/integration_test_config.dart';
import 'recovery_and_login_test.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String password = IntegrationTestConfig.password;

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

  testWidgets('Prepaired reset setup flow golden', (tester) async {
    // Load app widget.
    await tester.pumpFrames(app(), Duration(seconds: 3));

    final setup = TestPrepairPnpSetupActions(tester);

    // Login page
    await setup.inputPassword(password);
    expect(password, tester.getText(setup.passwordFinder()));
    await setup.showPassword();
    await setup.tapLoginButton();

    // Pnp page
    // Personalize wifi
    await setup.tapNextButton();
    // Guest wifi
    await setup.tapSwitch();
    await setup.tapSwitch();
    await setup.tapNextButton();
    // Night mode
    await setup.tapNextButton();
    await tester.pumpFrames(app(), const Duration(seconds: 60));
    // Done
    final doneBtnFinder = setup.doneButtonFinder();
    await tester.scrollUntilVisible(
      doneBtnFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await setup.tapDoneButton();

    // Dashboard
    final quickPanelFinder = find.byType(DashboardQuickPanel);
    expect(quickPanelFinder, findsOneWidget);
  });
}
