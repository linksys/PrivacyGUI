import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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

  testWidgets('Incredible Wifi - Test Wifi name and password', (tester) async {
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

    const newWifiName = 'Linksys00019'; //IntegrationTestConfig.password;
    const newWifiPassword = '3rEzbu27c@'; //IntegrationTestConfig.password;
    const newGuestWifiName = 'Linksys00019-guest';
    const newGuestWifiPassword = 'BeMyGuest!@';

    // Define actions
    Future testWifiName(
        TestIncredibleWifiActions wifiActions, String wifiName) async {
      final context = wifiActions.getContext();
      // Test wifi name
      await wifiActions.tapWifiNameCard();
      await wifiActions.inputWifiName('');
      wifiActions.checkErrorMessage(loc(context).theNameMustNotBeEmpty);
      await wifiActions.inputWifiName(' spaceInHead');
      wifiActions
          .checkErrorMessage(loc(context).routerPasswordRuleStartEndWithSpace);
      await wifiActions.inputWifiName('spaceInTheEnd ');
      wifiActions
          .checkErrorMessage(loc(context).routerPasswordRuleStartEndWithSpace);
      await wifiActions.inputWifiName('veryLoooooooooooooooooooooongSSID');
      wifiActions.checkErrorMessage(loc(context).wifiSSIDLengthLimit);
      await wifiActions.inputWifiName(wifiName);
      await wifiActions.tapTextSaveBtn();
      wifiActions.checkWifiName(wifiName);
    }

    Future testWifiPassword(
        TestIncredibleWifiActions wifiActions, String wifiPassword) async {
      // Test wifi password
      await wifiActions.tapWifiPasswordCard();
      await wifiActions.tapPasswordVisibilityOnAlert();
      await wifiActions.inputWifiPassword('');
      wifiActions.infoIconFinder();
      await wifiActions.inputWifiPassword('short');
      wifiActions.closeIconFinder();
      await wifiActions.inputWifiPassword(
          'veryLooooooooooooooooooooooooooooooooooooooooooooooooooongPassword');
      wifiActions.closeIconFinder();
      await wifiActions.inputWifiPassword(' spaceInHead');
      wifiActions.closeIconFinder();
      await wifiActions.inputWifiPassword('spaceInTheEnd ');
      wifiActions.closeIconFinder();
      await wifiActions.inputWifiPassword('withInvalidChar🥲');
      wifiActions.closeIconFinder();
      await wifiActions.inputWifiPassword(wifiPassword);
      await wifiActions.tapTextSaveBtn();
      await wifiActions.tapPasswordVisibility();
      wifiActions.checkWifiPassword(wifiPassword);
      await wifiActions.tapPasswordVisibilityOff();
    }

    Future testGuestWifiName(
        TestIncredibleWifiActions wifiActions, String wifiName) async {
      final context = wifiActions.getContext();
      // Test wifi name
      await wifiActions.tapGuestWifiNameCard();
      await wifiActions.inputGuestWifiName('');
      wifiActions.checkErrorMessage(loc(context).theNameMustNotBeEmpty);
      await wifiActions.inputGuestWifiName(' spaceInHead');
      wifiActions
          .checkErrorMessage(loc(context).routerPasswordRuleStartEndWithSpace);
      await wifiActions.inputGuestWifiName('spaceInTheEnd ');
      wifiActions
          .checkErrorMessage(loc(context).routerPasswordRuleStartEndWithSpace);
      await wifiActions.inputGuestWifiName('veryLoooooooooooooooooooooongSSID');
      wifiActions.checkErrorMessage(loc(context).wifiSSIDLengthLimit);
      await wifiActions.inputGuestWifiName(wifiName);
      await wifiActions.tapTextSaveBtn();
      wifiActions.checkGuestWifiName(wifiName);
    }

    Future testGuestWifiPassword(
        TestIncredibleWifiActions wifiActions, String wifiPassword) async {
      // Test wifi password
      await wifiActions.tapGuestWifiPasswordCard();
      await wifiActions.tapPasswordVisibilityOnAlert();
      await wifiActions.inputGuestWifiPassword('');
      wifiActions.infoIconFinder();
      await wifiActions.inputGuestWifiPassword('short');
      wifiActions.closeIconFinder();
      await wifiActions.inputGuestWifiPassword(
          'veryLooooooooooooooooooooooooooooooooooooooooooooooooooongPassword');
      wifiActions.closeIconFinder();
      await wifiActions.inputGuestWifiPassword(' spaceInHead');
      wifiActions.closeIconFinder();
      await wifiActions.inputGuestWifiPassword('spaceInTheEnd ');
      wifiActions.closeIconFinder();
      await wifiActions.inputGuestWifiPassword('withInvalidChar🥲');
      wifiActions.closeIconFinder();
      await wifiActions.inputGuestWifiPassword(wifiPassword);
      await wifiActions.tapTextSaveBtn();
      await wifiActions.tapGuestPasswordVisibility();
      wifiActions.checkGuestWifiPassword(wifiPassword);
      await wifiActions.tapGuestPasswordVisibilityOff();
    }

    // Start testing
    for (final band in IntegrationTestConfig.wifiBands.split(',')) {
      final wifiActions = TestIncredibleWifiActions(tester, wifiBand: band);
      if (band == '2.4') {
        await wifiActions.tapSwitch();
        await wifiActions.tapSwitch();
        await testWifiName(wifiActions, newWifiName);
        await testWifiPassword(wifiActions, newWifiPassword);
      } else if (band == '5') {
        await wifiActions.tapSwitch();
        await wifiActions.tapSwitch();
        await testWifiName(wifiActions, newWifiName);
        await testWifiPassword(wifiActions, newWifiPassword);
      } else if (band == '6') {
        await wifiActions.tapSwitch();
        await wifiActions.tapSwitch();
        await testWifiName(wifiActions, newWifiName);
        await testWifiPassword(wifiActions, newWifiPassword);
      } else if (band == 'guest') {
        await wifiActions.tapSwitch();
        await testGuestWifiName(wifiActions, newGuestWifiName);
        await testGuestWifiPassword(wifiActions, newGuestWifiPassword);
      }
    }

    // Save wifi name and password
    await wifiActions.tapSaveBtn();
    for (final band in IntegrationTestConfig.wifiBands.split(',')) {
      final wifiActions = TestIncredibleWifiActions(tester, wifiBand: band);
      if (band == '2.4') {
        wifiActions.checkNewSettingWifiName(newWifiName);
        wifiActions.checkNewSettingWifiPassword(newWifiPassword);
      } else if (band == '5') {
        wifiActions.checkNewSettingWifiName(newWifiName);
        wifiActions.checkNewSettingWifiPassword(newWifiPassword);
      } else if (band == '6') {
        wifiActions.checkNewSettingWifiName(newWifiName);
        wifiActions.checkNewSettingWifiPassword(newWifiPassword);
      } else if (band == 'guest') {
        wifiActions.checkNewSettingWifiName(newGuestWifiName);
        wifiActions.checkNewSettingWifiPassword(newGuestWifiPassword);
      }
    }
    await wifiActions.tapOkButton();
    await tester.pumpAndSettle();

    // Enter the wifi page again to check if data saved
    await wifiActions.tapBackButton();
    await menuActions.enterWifiPage();
    for (final band in IntegrationTestConfig.wifiBands.split(',')) {
      final wifiActions = TestIncredibleWifiActions(tester, wifiBand: band);
      if (band == '2.4') {
        wifiActions.checkWifiName(newWifiName);
        await wifiActions.tapPasswordVisibility();
        wifiActions.checkWifiPassword(newWifiPassword);
        await wifiActions.tapPasswordVisibilityOff();
      } else if (band == '5') {
        wifiActions.checkWifiName(newWifiName);
        await wifiActions.tapPasswordVisibility();
        wifiActions.checkWifiPassword(newWifiPassword);
        await wifiActions.tapPasswordVisibilityOff();
      } else if (band == '6') {
        wifiActions.checkWifiName(newWifiName);
        await wifiActions.tapPasswordVisibility();
        wifiActions.checkWifiPassword(newWifiPassword);
        await wifiActions.tapPasswordVisibilityOff();
      } else if (band == 'guest') {
        wifiActions.checkGuestWifiName(newGuestWifiName);
        await wifiActions.tapGuestPasswordVisibility();
        wifiActions.checkGuestWifiPassword(newGuestWifiPassword);
        await wifiActions.tapGuestPasswordVisibilityOff();
      }
    }
  });
}
