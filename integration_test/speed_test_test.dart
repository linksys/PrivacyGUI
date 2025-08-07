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

  group('Speed Test', () {
    testWidgets('Speed Test - Log in ', (tester) async {
      await tester.pumpFrames(app(), const Duration(seconds: 3));
      final login = TestLocalLoginActions(tester);
      await login.inputPassword(IntegrationTestConfig.password);
      await login.tapLoginButton();
    });

    testWidgets('Speed Test - Run speed test', (tester) async {
      await tester.pumpFrames(app(), const Duration(seconds: 3));
      // Enter the menu screen
      final topbarActions = TestTopbarActions(tester);
      await topbarActions.tapMenuButton();
      final menuActions = TestMenuActions(tester);
      // Enter Speed Test screen
      await menuActions.enterSpeedTestPage();
      await tester.pumpAndSettle();
      final speedTestActions = TestSpeedTestActions(tester);
      await speedTestActions.tapGoButton();
      await tester.pumpAndSettle();
      await tester.pumpFrames(app(), Duration(seconds: 30));
      // Check try again button
      speedTestActions.checkDownloadBandWidth();
      speedTestActions.checkUploadBandWidth();
      speedTestActions.tryAgainButtonFinder();
    });
  });
}
