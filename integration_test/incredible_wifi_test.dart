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
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_term_titles.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'actions/base_actions.dart';
import 'config/integration_test_config.dart';
import 'extensions/extensions.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const newWifiName = IntegrationTestConfig.newWifiName;
  const newWifiPassword = IntegrationTestConfig.newWifiPassword;
  const newGuestWifiName = IntegrationTestConfig.newGuestWifiName;
  const newGuestWifiPassword = IntegrationTestConfig.newGuestWifiPassword;
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

  group('Incredible Wifi - Test Wifi tab', () {
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

    testWidgets('Incredible Wifi - Test 2.4 GHz wifi name ande password',
        (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('2.4')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '2.4');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        await wifiActions.tapBandSwitch();
        await wifiActions.tapBandSwitch();
        await testWifiName(wifiActions, newWifiName);
        await testWifiPassword(wifiActions, newWifiPassword);
        // Save wifi name and password
        await wifiActions.tapSaveBtn();
        wifiActions.checkNewSettingWifiName(newWifiName);
        wifiActions.checkNewSettingWifiPassword(newWifiPassword);
        await wifiActions.tapOkButton();
        await tester.pumpAndSettle();
        // Enter the wifi page again to check if data saved
        await wifiActions.tapBackButton();
        await menuActions.enterWifiPage();
        wifiActions.checkWifiName(newWifiName);
        await wifiActions.tapPasswordVisibility();
        wifiActions.checkWifiPassword(newWifiPassword);
        await wifiActions.tapPasswordVisibilityOff();
      }
    });

    testWidgets('Incredible Wifi - Test 5 GHz wifi name ande password',
        (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('5')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '5');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        await wifiActions.tapBandSwitch();
        await wifiActions.tapBandSwitch();
        await testWifiName(wifiActions, newWifiName);
        await testWifiPassword(wifiActions, newWifiPassword);
        // Save wifi name and password
        await wifiActions.tapSaveBtn();
        wifiActions.checkNewSettingWifiName(newWifiName);
        wifiActions.checkNewSettingWifiPassword(newWifiPassword);
        await wifiActions.tapOkButton();
        await tester.pumpAndSettle();
        // Enter the wifi page again to check if data saved
        await wifiActions.tapBackButton();
        await menuActions.enterWifiPage();
        wifiActions.checkWifiName(newWifiName);
        await wifiActions.tapPasswordVisibility();
        wifiActions.checkWifiPassword(newWifiPassword);
        await wifiActions.tapPasswordVisibilityOff();
      }
    });

    testWidgets('Incredible Wifi - Test 6 GHz wifi name ande password',
        (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('6')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '6');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        await wifiActions.tapBandSwitch();
        await wifiActions.tapBandSwitch();
        await testWifiName(wifiActions, newWifiName);
        await testWifiPassword(wifiActions, newWifiPassword);
        // Save wifi name and password
        await wifiActions.tapSaveBtn();
        wifiActions.checkNewSettingWifiName(newWifiName);
        wifiActions.checkNewSettingWifiPassword(newWifiPassword);
        await wifiActions.tapOkButton();
        await tester.pumpAndSettle();
        // Enter the wifi page again to check if data saved
        await wifiActions.tapBackButton();
        await menuActions.enterWifiPage();
        wifiActions.checkWifiName(newWifiName);
        await wifiActions.tapPasswordVisibility();
        wifiActions.checkWifiPassword(newWifiPassword);
        await wifiActions.tapPasswordVisibilityOff();
      }
    });

    testWidgets('Incredible Wifi - Test guest wifi name ande password',
        (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('guest')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions =
            TestIncredibleWifiActions(tester, wifiBand: 'guest');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        await wifiActions.tapBandSwitch();
        await testGuestWifiName(wifiActions, newGuestWifiName);
        await testGuestWifiPassword(wifiActions, newGuestWifiPassword);
        // Save wifi name and password
        await wifiActions.tapSaveBtn();
        wifiActions.checkNewSettingWifiName(newGuestWifiName);
        wifiActions.checkNewSettingWifiPassword(newGuestWifiPassword);
        await wifiActions.tapOkButton();
        await tester.pumpAndSettle();
        // Enter the wifi page again to check if data saved
        await wifiActions.tapBackButton();
        await menuActions.enterWifiPage();
        wifiActions.checkGuestWifiName(newGuestWifiName);
        await wifiActions.tapGuestPasswordVisibility();
        wifiActions.checkGuestWifiPassword(newGuestWifiPassword);
        await wifiActions.tapGuestPasswordVisibilityOff();
      }
    });

    testWidgets('Incredible Wifi - Test 2.4 GHz wifi settings', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('2.4')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '2.4');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        // Test security mode
        await wifiActions.tapSecurityModeCard();
        await wifiActions.tapEnhancedOpenOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test wifi mode
        await wifiActions.tapWifiModeCard();
        await wifiActions.tap80211bgnOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test broadcast ssid
        await wifiActions.tapCheckbox();
        // Test channel width
        await wifiActions.tapChannelWidthCard();
        await wifiActions.tap20MHzOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test channel
        await wifiActions.tapChannelCard();
        await wifiActions.tap6ChannelOption();
        await wifiActions.tapAlertOkBtn();
        // Save settings
        await wifiActions.tapSaveBtn();
        wifiActions.checkNewSettingSecurityMode(
            WifiSecurityType.enhancedOpenOnly.value);
        await wifiActions.tapOkButton();
        await tester.pumpAndSettle();
        // Enter the wifi page again to check if data saved
        await wifiActions.tapBackButton();
        await menuActions.enterWifiPage();
        wifiActions.checkSecurityMode(getWifiSecurityTypeTitle(
            wifiActions.getContext(), WifiSecurityType.enhancedOpenOnly));
        wifiActions.checkWifiMode(getWifiWirelessModeTitle(
          wifiActions.getContext(),
          WifiWirelessMode.bgn,
          null,
        ));
        wifiActions.checkBroadcastSSIDDisable();
        wifiActions.checkChannelWidth(getWifiChannelWidthTitle(
            wifiActions.getContext(), WifiChannelWidth.wide20));
        wifiActions.checkChannel(getWifiChannelTitle(
            wifiActions.getContext(), 6, WifiRadioBand.radio_24));
      }
    });

    testWidgets('Incredible Wifi - Test 5 GHz wifi settings', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('5')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '5');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        // Test security mode
        await wifiActions.tapSecurityModeCard();
        await wifiActions.tapEnhancedOpenOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test wifi mode
        await wifiActions.tapWifiModeCard();
        await wifiActions.tap80211anacOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test broadcast ssid
        await wifiActions.tapCheckbox();
        // Test channel width
        await wifiActions.tapChannelWidthCard();
        await wifiActions.tap20MHzOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test channel
        await wifiActions.tapChannelCard();
        await wifiActions.tap40ChannelOption();
        await wifiActions.tapAlertOkBtn();
        // Save settings
        await wifiActions.tapSaveBtn();
        wifiActions.checkNewSettingSecurityMode(
            WifiSecurityType.enhancedOpenOnly.value);
        await wifiActions.tapOkButton();
        await tester.pumpAndSettle();
        // Enter the wifi page again to check if data saved
        await wifiActions.tapBackButton();
        await menuActions.enterWifiPage();
        wifiActions.checkSecurityMode(getWifiSecurityTypeTitle(
            wifiActions.getContext(), WifiSecurityType.enhancedOpenOnly));
        wifiActions.checkWifiMode(getWifiWirelessModeTitle(
          wifiActions.getContext(),
          WifiWirelessMode.anac,
          null,
        ));
        wifiActions.checkBroadcastSSIDDisable();
        wifiActions.checkChannelWidth(getWifiChannelWidthTitle(
            wifiActions.getContext(), WifiChannelWidth.wide20));
        wifiActions.checkChannel(getWifiChannelTitle(
            wifiActions.getContext(), 40, WifiRadioBand.radio_5_1));
      }
    });

    testWidgets('Incredible Wifi - Test 6 GHz wifi settings', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('6')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions = TestIncredibleWifiActions(tester, wifiBand: '6');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        // Test security mode
        await wifiActions.tapSecurityModeCard();
        await wifiActions.tapEnhancedOpenOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test wifi mode
        await wifiActions.tapWifiModeCard();
        await wifiActions.tap80211axOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test broadcast ssid
        await wifiActions.tapCheckbox();
        // Test channel width
        await wifiActions.tapChannelWidthCard();
        await wifiActions.tap20MHzOnlyOption();
        await wifiActions.tapAlertOkBtn();
        // Test channel
        await wifiActions.tapChannelCard();
        await wifiActions.tap29ChannelOption();
        await wifiActions.tapAlertOkBtn();
        // Save settings
        await wifiActions.tapSaveBtn();
        wifiActions.checkNewSettingSecurityMode(
            WifiSecurityType.enhancedOpenOnly.value);
        await wifiActions.tapOkButton();
        await tester.pumpAndSettle();
        // Enter the wifi page again to check if data saved
        await wifiActions.tapBackButton();
        await menuActions.enterWifiPage();
        wifiActions.checkSecurityMode(getWifiSecurityTypeTitle(
            wifiActions.getContext(), WifiSecurityType.enhancedOpenOnly));
        wifiActions.checkWifiMode(getWifiWirelessModeTitle(
          wifiActions.getContext(),
          WifiWirelessMode.ax,
          null,
        ));
        wifiActions.checkBroadcastSSIDDisable();
        wifiActions.checkChannelWidth(getWifiChannelWidthTitle(
            wifiActions.getContext(), WifiChannelWidth.wide20));
        wifiActions.checkChannel(getWifiChannelTitle(
            wifiActions.getContext(), 29, WifiRadioBand.radio_24));
      }
    });

    testWidgets('Incredible Wifi - Test guest wifi warning', (tester) async {
      // Load app widget.
      await tester.pumpFrames(app(), Duration(seconds: 5));
      if (wifiBands.contains('guest')) {
        // Enter the menu page
        final topbarActions = TestTopbarActions(tester);
        await topbarActions.tapMenuButton();
        // Enter the wifi page
        final menuActions = TestMenuActions(tester);
        await menuActions.enterWifiPage();
        final wifiActions =
            TestIncredibleWifiActions(tester, wifiBand: 'guest');
        await wifiActions.checkTitle(wifiActions.title);
        // Start testing
        // Disable other wifi
        if (wifiBands.contains('2.4')) {
          final wifiActions =
            TestIncredibleWifiActions(tester, wifiBand: '2.4');
          await wifiActions.tapBandSwitch();
        }
        if (wifiBands.contains('5')) {
          final wifiActions =
            TestIncredibleWifiActions(tester, wifiBand: '5');
          await wifiActions.tapBandSwitch();
        }
        if (wifiBands.contains('6')) {
          final wifiActions =
            TestIncredibleWifiActions(tester, wifiBand: '6');
          await wifiActions.tapBandSwitch();
        }
        // Check the warning exist
        await wifiActions.tapSaveBtn();
        if (wifiBands.contains('2.4')) {
          wifiActions.checkNewSettingGuestWarning(WifiRadioBand.radio_24);
        }
        if (wifiBands.contains('5')) {
          wifiActions.checkNewSettingGuestWarning(WifiRadioBand.radio_5_1);
        }
        if (wifiBands.contains('6')) {
          wifiActions.checkNewSettingGuestWarning(WifiRadioBand.radio_6);
        }
      }
    });
  });
}

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
  await wifiActions.tapAlertSaveBtn();
  wifiActions.checkWifiName(wifiName);
}

Future testWifiPassword(
    TestIncredibleWifiActions wifiActions, String wifiPassword) async {
  // Test wifi password
  await wifiActions.tapWifiPasswordCard();
  await wifiActions.tapPasswordVisibilityOnAlert();
  await wifiActions.inputWifiPassword('');
  wifiActions.passwordValidatorInfoIconFinder();
  await wifiActions.inputWifiPassword('short');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputWifiPassword(
      'veryLooooooooooooooooooooooooooooooooooooooooooooooooooongPassword');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputWifiPassword(' spaceInHead');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputWifiPassword('spaceInTheEnd ');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputWifiPassword('withInvalidChar🥲');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputWifiPassword(wifiPassword);
  await wifiActions.tapAlertSaveBtn();
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
  await wifiActions.tapAlertSaveBtn();
  wifiActions.checkGuestWifiName(wifiName);
}

Future testGuestWifiPassword(
    TestIncredibleWifiActions wifiActions, String wifiPassword) async {
  // Test wifi password
  await wifiActions.tapGuestWifiPasswordCard();
  await wifiActions.tapPasswordVisibilityOnAlert();
  await wifiActions.inputGuestWifiPassword('');
  wifiActions.passwordValidatorInfoIconFinder();
  await wifiActions.inputGuestWifiPassword('short');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputGuestWifiPassword(
      'veryLooooooooooooooooooooooooooooooooooooooooooooooooooongPassword');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputGuestWifiPassword(' spaceInHead');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputGuestWifiPassword('spaceInTheEnd ');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputGuestWifiPassword('withInvalidChar🥲');
  wifiActions.passwordValidatorCloseIconFinder();
  await wifiActions.inputGuestWifiPassword(wifiPassword);
  await wifiActions.tapAlertSaveBtn();
  await wifiActions.tapGuestPasswordVisibility();
  wifiActions.checkGuestWifiPassword(wifiPassword);
  await wifiActions.tapGuestPasswordVisibilityOff();
}
