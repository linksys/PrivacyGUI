import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/widgets/stepper/app_stepper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'actions/pnp_setup_actions.dart';

class MyServiceHelper extends ServiceHelper {
  @override
  bool isSupportGuestNetwork([List<String>? services]) => false;

  @override
  bool isSupportLedMode([List<String>? services]) => false;
}

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
    ServiceHelper mockServiceHelper = MyServiceHelper();
    getIt.registerSingleton<ServiceHelper>(mockServiceHelper);
  });
  group('end-to-end test - Pinnacle PnP setup', () {
    testWidgets('PnP no guest wifi and night mode services - Unconfigured', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 3));

      // Pnp page
      final setup = TestPnpSetupActions(tester);
      await setup.tapContinueButton();
      // WiFi Personal
      await setup.showPassword();

      // Expectations
      expect(false, serviceHelper.isSupportGuestNetwork());
      expect(false, serviceHelper.isSupportLedMode());

      final steperFinder = find.byType(AppStepper);
      expect(steperFinder, findsOneWidget);
      final steperWidget = tester.widget<AppStepper>(steperFinder);
      expect(steperWidget.steps.length, 2);

      await setup.tapContinueButton(seconds: 60);
    });
  });
}
