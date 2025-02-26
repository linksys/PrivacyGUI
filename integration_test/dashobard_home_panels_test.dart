import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacy_gui/page/dashboard/views/components/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'app_test.dart';

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

  testWidgets('Dashboard home view: operate over panels', (tester) async {
    await doLogin(tester);
    final dashboardHomeActions = TestDashboardHomeActions(tester);
    await dashboardHomeActions.checkTopologyPage();
    await dashboardHomeActions.checkDeviceDetailPage();
    await dashboardHomeActions.checkNodeDetailPage();
    await dashboardHomeActions.hoverToNightModeInfoIcon();
    await dashboardHomeActions.toggleNightMode();
    await dashboardHomeActions.hoverToInstantPrivacyInfoIcon();
    await dashboardHomeActions.toggleInstantPrivacy();
    await dashboardHomeActions.checkInstantPrivacyPage();
    await dashboardHomeActions.hoverTo24gWifiQrIcon();
    //await dashboardHomeActions.toggle24gWifi(); // cannot turn off all wifi
    await dashboardHomeActions.check24gWifiPage();
    await dashboardHomeActions.hoverTo5gWifiQrIcon();
    await dashboardHomeActions.toggle5gWifi();
    await dashboardHomeActions.check5gWifiPage();
    await dashboardHomeActions.hoverToGuestWifiQrIcon();
    await dashboardHomeActions.toggleGuestWifi();
    await dashboardHomeActions.checkGuestWifiPage();
  });
}

Future<void> doLogin(WidgetTester tester) async {
  await tester.pumpFrames(app(), Duration(seconds: 3));
  final login = TestLocalLoginActions(tester);
  await login.inputPassword('Belkin123!');
  expect('Belkin123!', tester.getText(find.byType(AppPasswordField)));
  await login.tapLoginButton();
}

class TestDashboardHomeActions {
  final WidgetTester tester;

  TestDashboardHomeActions(this.tester);

  Future<void> checkTopologyPage() async {
    // Find topology card
    final networkCardFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(AppCard),
    );
    expect(networkCardFinder, findsNWidgets(4));
    final topologyCard = networkCardFinder.at(1);
    // Scroll the screen
    await _scrollUntil(topologyCard);
    // Tap the topology
    await tester.tap(topologyCard);
    await tester.pumpAndSettle();
    await _tapBackButton();
  }

  Future<void> checkDeviceDetailPage() async {
    // Find device detail card
    final networkCardFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(AppCard),
    );
    expect(networkCardFinder, findsNWidgets(4));
    final deviceCard = networkCardFinder.at(2);
    // Tap the device detail
    await tester.tap(deviceCard);
    await tester.pumpAndSettle();
    await _tapBackButton();
  }

  Future<void> checkNodeDetailPage() async {
    // Find node detail tappable area
    final nodeDetailFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(SimpleTreeNodeItem),
    );
    expect(nodeDetailFinder, findsOneWidget);
    // Scroll the screen
    await _scrollUntil(nodeDetailFinder);
    // Tap the node detail
    await tester.tap(nodeDetailFinder);
    await tester.pumpAndSettle();
    await _tapBackButton();
  }

  Future<void> hoverToNightModeInfoIcon() async {
    // Find night mode info icon
    final iconFinder = find.descendant(
      of: find.byType(DashboardQuickPanel),
      matching: find.byType(Icon),
    );
    expect(iconFinder, findsNWidgets(2));
    // scroll the screen
    await _scrollUntil(iconFinder.last);
    await _hoverToCenter(iconFinder.last);
    expect(
      find.byTooltip(
        'When enabled, the LED light will turn off between 8:00 PM and 8:00 AM.',
      ),
      findsOneWidget,
    );
    await tester.pumpFrames(app(), Duration(seconds: 1));
  }

  Future<void> toggleNightMode() async {
    // Find night mode switch
    final nightModeSwitchFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(AppSwitch),
        )
        .last;
    expect(nightModeSwitchFinder, findsOneWidget);
    // Tap the switch
    await tester.tap(nightModeSwitchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hoverToInstantPrivacyInfoIcon() async {
    // Find instant privacy info icon
    final iconFinder = find.descendant(
      of: find.byType(DashboardQuickPanel),
      matching: find.byType(Icon),
    );
    expect(iconFinder, findsNWidgets(2));
    await _hoverToCenter(iconFinder.first);
    expect(
      find.byTooltip(
        'Enabling Instant-Privacy prevents new devices from connecting to your network. To add a new device, disable Instant-Privacy, then re-enable it for enhanced security.',
      ),
      findsOneWidget,
    );
    await tester.pumpFrames(app(), Duration(seconds: 1));
  }

  Future<void> toggleInstantPrivacy() async {
    // Find instant privacy switch
    final instantPrivacySwitchFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(AppSwitch),
        )
        .first;
    expect(instantPrivacySwitchFinder, findsOneWidget);
    // Tap the switch
    await tester.tap(instantPrivacySwitchFinder);
    await tester.pumpAndSettle();
    // Tap cancel button
    await _tapCancelOnInstantPrivacyDialog();
    // Again, tap the switch
    await tester.tap(instantPrivacySwitchFinder);
    await tester.pumpAndSettle();
    await _tapOkOnInstantPrivacyDialog();
  }

  Future<void> checkInstantPrivacyPage() async {
    // Find tappable area of instant privacy
    final instantPrivacyFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(InkWell),
        )
        .first;
    expect(instantPrivacyFinder, findsOneWidget);
    // Tap the instant privacy
    await tester.tap(instantPrivacyFinder);
    await tester.pumpAndSettle();
    await _tapBackButton();
  }

  Future<void> hoverTo24gWifiQrIcon() async {
    // Find 2.4G Wifi QR code icon
    final tipFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(SuperTooltip),
    );
    expect(tipFinder, findsNWidgets(3));
    final wifi24gTipFinder = tipFinder.at(0);
    // scroll the screen
    await _scrollUntil(wifi24gTipFinder);
    await _hoverToCenter(wifi24gTipFinder);
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.pumpAndSettle();
  }

  Future<void> toggle24gWifi() async {
    // Find 2.4G Wifi switch
    final wifiSwitchFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppSwitch),
    );
    expect(wifiSwitchFinder, findsNWidgets(3));
    final wifi24gSwitch = wifiSwitchFinder.at(0);
    // Tap the switch
    await tester.tap(wifi24gSwitch);
    await tester.pumpAndSettle();
  }

  Future<void> check24gWifiPage() async {
    // Find 2.4G Wifi card
    final wifiCardFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsNWidgets(3));
    // Tap the card
    await tester.tap(wifiCardFinder.at(0));
    await tester.pumpAndSettle();
    await _tapBackButton();
  }

  Future<void> hoverTo5gWifiQrIcon() async {
    // Find 5G Wifi switch
    final tipFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(SuperTooltip),
    );
    expect(tipFinder, findsNWidgets(3));
    final wifi5gTipFinder = tipFinder.at(1);
    // scroll the screen
    await _scrollUntil(wifi5gTipFinder);
    await _hoverToCenter(wifi5gTipFinder);
    // If 5g wifi is disabled, there will be no QR code image
    expect(find.byType(QrImageView), findsAtLeastNWidgets(0));
    await tester.pumpAndSettle();
  }

  Future<void> toggle5gWifi() async {
    // Find 5G Wifi switch
    final wifiSwitchFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppSwitch),
    );
    expect(wifiSwitchFinder, findsNWidgets(3));
    final wifi5gSwitch = wifiSwitchFinder.at(1);
    // Tap the switch
    await tester.tap(wifi5gSwitch);
    await tester.pumpAndSettle();
  }

  Future<void> check5gWifiPage() async {
    // Find 5G Wifi card
    final wifiCardFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsNWidgets(3));
    // Tap the card
    await tester.tap(wifiCardFinder.at(1));
    await tester.pumpAndSettle();
    await _tapBackButton();
  }

  Future<void> hoverToGuestWifiQrIcon() async {
    // Find guest Wifi QR code icon
    final tipFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(SuperTooltip),
    );
    expect(tipFinder, findsNWidgets(3));
    final wifiGuestTipFinder = tipFinder.at(2);
    // scroll the screen
    await _scrollUntil(wifiGuestTipFinder);
    await _hoverToCenter(wifiGuestTipFinder);
    // If guest wifi is disabled, there will be no QR code image
    expect(find.byType(QrImageView), findsAtLeastNWidgets(0));
    await tester.pumpAndSettle();
  }

  Future<void> toggleGuestWifi() async {
    // Find guest Wifi switch
    final wifiSwitchFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppSwitch),
    );
    expect(wifiSwitchFinder, findsNWidgets(3));
    final wifiGuestSwitch = wifiSwitchFinder.at(2);
    // Tap the switch
    await tester.tap(wifiGuestSwitch);
    await tester.pumpAndSettle();
  }

  Future<void> checkGuestWifiPage() async {
    // Find guest Wifi card
    final wifiCardFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsNWidgets(3));
    // Tap the card
    await tester.tap(wifiCardFinder.at(2));
    await tester.pumpAndSettle();
    await _tapBackButton();
  }

  Future<void> _tapCancelOnInstantPrivacyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the cancel button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the cancel button
    await tester.tap(dialogButtonFinder.first);
    await tester.pumpAndSettle();
  }

  Future<void> _tapOkOnInstantPrivacyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the Ok button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the Ok button
    await tester.tap(dialogButtonFinder.last);
    await tester.pumpAndSettle();
  }

  Future<void> _hoverToCenter(Finder finder) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    // Explicitly remove the pointer after the hover action
    await gesture.removePointer();
  }

  Future<void> _tapBackButton() async {
    // Find back button
    final backButtonFinder = find.descendant(
      of: find.byType(LinksysAppBar),
      matching: find.byType(AppIconButton),
    );
    expect(backButtonFinder, findsOneWidget);
    // Tap the back button
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> _scrollUntil(Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
}
