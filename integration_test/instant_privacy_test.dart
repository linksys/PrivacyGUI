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

  group('Instant Privacy', () {
    testWidgets('Instant Privacy - Log in and enter dashboard', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
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

    testWidgets('Instant Privacy - Test the enable switch', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      // Enter the menu page
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      // Enter the instant privacy page
      final menuActions = TestMenuActions(tester);
      await menuActions.enterPrivacyPage();
      final privacyActions = TestInstantPrivacyActions(tester);
      await privacyActions.checkTitle(privacyActions.title);
      // Start testing
      await privacyActions.tapEnableSwitch();
      await privacyActions.tapTurnOnButton();
      await tester.pumpAndSettle();
    });
  });
}
