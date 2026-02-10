import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/_index.dart';
import '../../../../common/test_helper.dart';
import '../../../../test_data/_index.dart';

// Tall screens for tests that require bottom bar visibility (Pattern 0)
final _tallScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
];

// View ID: WIFIS
/// Implementation file under test: lib/page/wifi_settings/views/wifi_main_view.dart
///
/// This file contains screenshot tests for the `WiFiMainView`, which serves as the
/// main container for "Incredible WiFi" settings, including the main WiFi list,
/// advanced settings, and MAC filtering, organized by tabs.
///
/// **Covered Test Scenarios:**
///
/// - **`WIFIS-ADV_VIEW`**: Verifies the "Advanced Settings" tab renders correctly.
/// - **`WIFIS-MLO_WARN`**: Verifies the MLO warning is displayed in the advanced settings view.
/// - **`WIFIS-DFS_WARN`**: Verifies the DFS warning modal is displayed when saving advanced settings.
/// - **`WIFIS-MAC_VIEW`**: Verifies the "MAC Filtering" tab renders correctly.
/// - **`WIFIS-MAC_ENABLED`**: Verifies the MAC filtering view in an enabled state.
/// - **`WIFIS-MAC_ON_ALERT`**: Verifies the alert when turning on MAC filtering.
/// - **`WIFIS-MAC_OFF_ALERT`**: Verifies the alert when turning off MAC filtering.
/// - **`WIFIS-IP_DIS_WARN`**: Verifies the warning when Instant Privacy is disabled.
/// - **`WIFIS-MAC_DEV_VIEW`**: Verifies the MAC filtering devices view renders correctly.
/// - **`WIFIS-MAC_ADD_MAN`**: Verifies the dialog for manually adding a MAC address.
/// - **`WIFIS-MAC_SEL_DEV`**: Verifies the view for selecting devices for MAC filtering.
/// - **`WIFIS-MAIN_VIEW`**: Verifies the main view shell, including the title and the presence of three tabs.
/// - **`WIFIS-DIRTY_STATE`**: Verifies the save button is enabled when the state is dirty.

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    // Enable animations for Tab switching
    testHelper.disableAnimations = false;

    final wifiBundleTestStateInitialState =
        getWifiBundleTestState(wifiListTestData: wifiListAdvancedModeTestState);
    when(testHelper.mockWiFiBundleNotifier.build())
        .thenReturn(wifiBundleTestStateInitialState);
  });

  group('Incredible-WiFi - WiFi Advanced settings view', () {
    // Test ID: WIFIS-ADV_VIEW
    testThemeLocalizations('It should render the advanced settings view correctly',
        (tester, screen) async {
      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.byType(Tab);
      expect(tabFinder, findsNWidgets(3));

      await tester.tap(find.byKey(const Key('advancedTab')));
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).advanced), findsOneWidget);
      expect(find.byKey(Key('clientSteering')), findsOneWidget);
      expect(find.byKey(Key('nodeSteering')), findsOneWidget);
      expect(find.byKey(Key('dfs')), findsOneWidget);
      expect(find.byKey(Key('mlo')), findsOneWidget);
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ], goldenFilename: 'WIFIS-ADV_VIEW-01-initial_state');

    // Test ID: WIFIS-MLO_WARN
    testThemeLocalizations(
        'It should display the MLO warning in the advanced settings view',
        (tester, screen) async {
      when(testHelper.mockWiFiBundleNotifier.checkingMLOSettingsConflicts(any,
              isMloEnabled: anyNamed('isMloEnabled')))
          .thenReturn(true);

      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('advancedTab')));
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).mloWarning), findsOneWidget);
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ], goldenFilename: 'WIFIS-MLO_WARN-01-warning_shown');

    // Test ID: WIFIS-DFS_WARN
    testThemeLocalizations(
        'It should display the DFS warning modal when saving advanced settings',
        (tester, screen) async {
      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('advancedTab')));
      await tester.pumpAndSettle();

      final saveButtonFinder =
          find.byKey(const Key('pageBottomPositiveButton'));
      await tester.scrollUntilVisible(saveButtonFinder, 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).modalDFSDesc), findsOneWidget);
    }, screens: _tallScreens, goldenFilename: 'WIFIS-DFS_WARN-01-modal_shown');
  });

  group('Incredible-WiFi - MAC Filtering view', () {
    // Test ID: WIFIS-MAC_VIEW
    testThemeLocalizations('It should render the MAC filtering view correctly',
        (tester, screen) async {
      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('macFilteringTab')));
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).macFiltering), findsOneWidget);
      expect(find.byKey(const Key('macFilteringEnableTile')), findsOneWidget);
    },
        screens: [...responsiveMobileScreens, ...responsiveDesktopScreens],
        goldenFilename: 'WIFIS-MAC_VIEW-01-initial_state');

    // Test ID: WIFIS-MAC_ENABLED
    testThemeLocalizations(
        'It should render the MAC filtering view in an enabled state',
        (tester, screen) async {
      final wifiBundleTestStateInitialState =
          getWifiBundleTestState(privacyTestData: instantPrivacyDenyTestState);
      when(testHelper.mockWiFiBundleNotifier.build())
          .thenReturn(wifiBundleTestStateInitialState);

      await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('macFilteringTab')));
      await tester.pumpAndSettle();

      final enableSwitchFinder =
          find.byKey(const Key('macFilteringEnableSwitch'));
      expect(enableSwitchFinder, findsOneWidget);
      expect(tester.widget<AppSwitch>(enableSwitchFinder).value, true);
    },
        screens: [...responsiveMobileScreens, ...responsiveDesktopScreens],
        goldenFilename: 'WIFIS-MAC_ENABLED-01-initial_state');

    // Test ID: WIFIS-MAC_ON_ALERT
    testThemeLocalizations(
        'It should display an alert when turning on MAC filtering',
        (tester, screen) async {
      final wifiBundleTestStateInitialState =
          getWifiBundleTestState(privacyTestData: instantPrivacyDenyTestState);
      when(testHelper.mockWiFiBundleNotifier.build())
          .thenReturn(wifiBundleTestStateInitialState);

      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('macFilteringTab')));
      await tester.pumpAndSettle();

      final saveButtonFinder =
          find.widgetWithText(AppButton, testHelper.loc(context).save);
      await tester.scrollUntilVisible(saveButtonFinder, 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).turnOnMacFilteringDesc),
          findsOneWidget);
    },
        screens: _tallScreens,
        goldenFilename: 'WIFIS-MAC_ON_ALERT-01-alert_shown');

    // Test ID: WIFIS-MAC_OFF_ALERT
    testThemeLocalizations(
        'It should display an alert when turning off MAC filtering',
        (tester, screen) async {
      final wifiBundleTestStateInitialState =
          getWifiBundleTestState(privacyTestData: instantPrivacyTestState);
      when(testHelper.mockWiFiBundleNotifier.build())
          .thenReturn(wifiBundleTestStateInitialState);

      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('macFilteringTab')));
      await tester.pumpAndSettle();

      final saveButtonFinder =
          find.widgetWithText(AppButton, testHelper.loc(context).save);
      await tester.scrollUntilVisible(saveButtonFinder, 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).turnOffMacFilteringDesc),
          findsOneWidget);
    },
        screens: _tallScreens,
        goldenFilename: 'WIFIS-MAC_OFF_ALERT-01-alert_shown');

    // Test ID: WIFIS-IP_DIS_WARN
    testThemeLocalizations(
        'It should display a warning when Instant Privacy is disabled',
        (tester, screen) async {
      final wifiBundleTestStateInitialState = getWifiBundleTestState(
          privacyTestData: instantPrivacyEnabledTestState);
      when(testHelper.mockWiFiBundleNotifier.build())
          .thenReturn(wifiBundleTestStateInitialState);

      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('macFilteringTab')));
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).instantPrivacyDisableWarning),
          findsOneWidget);
    },
        screens: [...responsiveMobileScreens, ...responsiveDesktopScreens],
        goldenFilename: 'WIFIS-IP_DIS_WARN-01-warning_shown');

    // Test ID: WIFIS-MAC_DEV_VIEW
    testThemeLocalizations(
        'It should render the MAC filtering devices view correctly',
        (tester, screen) async {
      when(testHelper.mockInstantPrivacyNotifier.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));

      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const FilteredDevicesView(),
      );
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).selectFromMyDeviceList),
          findsOneWidget);
      expect(
          find.text(testHelper.loc(context).manuallyAddDevice), findsOneWidget);
    },
        screens: [...responsiveMobileScreens, ...responsiveDesktopScreens],
        goldenFilename: 'WIFIS-MAC_DEV_VIEW-01-initial_state');

    // Test ID: WIFIS-MAC_ADD_MAN
    testThemeLocalizations('It should allow manually adding a MAC address',
        (tester, screen) async {
      await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const FilteredDevicesView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manuallyAddDevice')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('macAddressTextField')), findsOneWidget);
    },
        screens: [...responsiveMobileScreens, ...responsiveDesktopScreens],
        goldenFilename: 'WIFIS-MAC_ADD_MAN-01-dialog_shown');

    // Test ID: WIFIS-MAC_SEL_DEV
    testThemeLocalizations('It should allow selecting devices for MAC filtering',
        (tester, screen) async {
      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: SelectDeviceView(
          args: const {
            'type': 'mac',
            'connection': 'wireless',
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).onlineDevices), findsOneWidget);
    },
        screens: [...responsiveMobileScreens, ...responsiveDesktopScreens],
        goldenFilename: 'WIFIS-MAC_SEL_DEV-01-initial_state');
  });

  group('Incredible-WiFi Views', () {
    // Test ID: WIFIS-MAIN_VIEW
    testThemeLocalizations('It should render the main view with tabs correctly',
        (tester, screen) async {
      final context = await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      // Verify that the main view and tabs are rendered
      expect(find.byType(WiFiMainView), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
      expect(find.text(testHelper.loc(context).incredibleWiFi), findsOneWidget);
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ], goldenFilename: 'WIFIS-MAIN_VIEW-01-initial_state');

    // Test ID: WIFIS-DIRTY_STATE
    testThemeLocalizations(
        'It should mark the state as dirty when a setting is edited',
        (tester, screen) async {
      final dirtyState = getWifiBundleTestState(
          wifiListTestData: wifiListAdvancedModeTestState);
      when(testHelper.mockWiFiBundleNotifier.build()).thenReturn(dirtyState);

      await testHelper.pumpShellView(
        tester,
        locale: screen.locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      // Verify that the save button is enabled
      final saveButtonFinder = find.byType(AppButton);
      expect(saveButtonFinder, findsOneWidget);
      final AppButton button = tester.widget(saveButtonFinder);
      expect(button.onTap, isNotNull);
    }, goldenFilename: 'WIFIS-DIRTY_STATE-01-save_button_enabled');
  });
}

WifiBundleState getWifiBundleTestState(
    {Map<String, Object> wifiListTestData = wifiListTestState,
    Map<String, Map<String, Object>> privacyTestData = instantPrivacyTestState,
    Map<String, bool?> advancedTestData = wifiAdvancedSettingsTestState}) {
  final wifiBundleTestState = {
    'settings': {
      'wifiList': WiFiListSettings.fromMap(wifiListTestData).toMap(),
      'advanced': WifiAdvancedSettingsState.fromMap(advancedTestData).toMap(),
      'privacy': InstantPrivacySettings.fromMap(
              privacyTestData['settings']?['original'] as Map<String, dynamic>)
          .toMap(),
    },
    'status': {
      'wifiList': WiFiListStatus.fromMap(
              {'canDisableMainWiFi': wifiListTestData['canDisableMainWiFi']})
          .toMap(),
      'privacy': InstantPrivacyStatus.fromMap(
              privacyTestData['status'] as Map<String, dynamic>)
          .toMap(),
    }
  };
  final wifiBundleTestStateSettings = WifiBundleSettings.fromMap(
      wifiBundleTestState['settings'] as Map<String, dynamic>);
  final wifiBundleTestStateStatus = WifiBundleStatus.fromMap(
      wifiBundleTestState['status'] as Map<String, dynamic>);

  // Make dirty
  final wifiListState = WiFiListSettings.fromMap(wifiListTestData);
  final changedMainWiFi = List<WiFiItem>.from(wifiListState.mainWiFi).map((e) {
    if (e.radioID == WifiRadioBand.radio_24) {
      return e.copyWith(ssid: '$e-1');
    }
    return e;
  }).toList();
  final updatedWifiListState =
      wifiListState.copyWith(mainWiFi: changedMainWiFi);

  final privacyState = InstantPrivacySettings.fromMap(
      privacyTestData['settings']?['original'] as Map<String, dynamic>);
  final updatedPrivacyState = privacyState.copyWith(myMac: '00:00:00:00:00:00');

  final updatedWifiBundleTestStateSettings = wifiBundleTestStateSettings
      .copyWith(wifiList: updatedWifiListState, privacy: updatedPrivacyState);

  return WifiBundleState(
    settings: Preservable(
        original: updatedWifiBundleTestStateSettings,
        current: wifiBundleTestStateSettings),
    status: wifiBundleTestStateStatus,
  );
}
