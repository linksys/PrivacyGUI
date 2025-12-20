import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_advanced_mode_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_simple_mode_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/_index.dart';
import '../../../../common/test_helper.dart';
import '../../../../test_data/_index.dart';
import 'wifi_main_view_test.dart';

// View ID: IWWL
/// Implementation file under test: lib/page/wifi_settings/views/wifi_list_view.dart
///
/// This file contains screenshot tests for the `WiFiListView`, which handles the
/// display and configuration of WiFi networks in both "Quick Setup" (Simple) and
/// "Advanced" modes.
///
/// **Covered Test Scenarios:**
///
/// - **`IWWL-QUICK_SETUP`**: Verifies the wifi list view in quick setup mode.
/// - **`IWWL-QUICK_SETUP_GUEST`**: Verifies the wifi list view in quick setup mode with guest wifi enabled.
/// - **`IWWL-ADV_INIT`**: Verifies the wifi list view in advanced mode.
/// - **`IWWL-ADV_INIT_GUEST`**: Verifies the wifi list view in advanced mode with guest wifi enabled.
/// - **`IWWL-SSID`**: Verifies SSID name input and validation.
/// - **`IWWL-PASSWORD`**: Verifies password input and validation.
/// - **`IWWL-SECURITY`**: Verifies security mode selection.
/// - **`IWWL-WIFI_MODE`**: Verifies wifi mode selection.
/// - **`IWWL-CHANNEL_WID`**: Verifies channel width selection.
/// - **`IWWL-CHANNEL`**: Verifies channel selection.
/// - **`IWWL-DISCARD`**: Verifies the discard changes modal.
/// - **`IWWL-SAVE_CONFIRM`**: Verifies the save confirmation modal.
/// - **`IWWL-WIFI_MODE_INVALID`**: Verifies the behavior with an invalid wifi mode value.
/// - **`IWWL-CHANNEL_WID_UNAVAIL`**: Verifies the behavior with an unavailable channel width.
/// - **`IWWL-SAVE_CONFIRM_DISABLE_BAND`**: Verifies the save confirmation modal with a disable band warning.
/// - **`IWWL-SAVE_CONFIRM_MLO`**: Verifies the save confirmation modal with an MLO warning.
/// - **`IWWL-NO_GUEST`**: Verifies the wifi list view when guest wifi is not supported.

final _wifiListScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
];

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  group('Incredible-WiFi - Wifi list view - Quick Setup', () {
    // Test ID: IWWL-QUICK_SETUP
    testLocalizationsV2(
      'Verify wifi list view in quick setup mode',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        expect(find.byType(WiFiMainView), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).incredibleWiFi), findsOneWidget);
        expect(find.byType(SimpleModeView), findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-QUICK_SETUP-01-initial_state',
    );

    // Test ID: IWWL-QUICK_SETUP_GUEST
    testLocalizationsV2(
      'Verify wifi list view in quick setup mode with guest wifi on',
      (tester, screen) async {
        final wifiBundleTestStateInitialState = getWifiBundleTestState(
            wifiListTestData: wifiListGuestEnabledTestState);
        when(testHelper.mockWiFiBundleNotifier.build())
            .thenReturn(wifiBundleTestStateInitialState);
        when(testHelper.mockWiFiBundleNotifier.state)
            .thenReturn(wifiBundleTestStateInitialState);
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        expect(find.byType(WiFiMainView), findsOneWidget);
        expect(find.text(testHelper.loc(context).guest), findsOneWidget);
        final guestSwitchFinder = find.byKey(Key('WiFiGuestSwitch'));
        final AppSwitch guestSwitchValue = tester.widget(guestSwitchFinder);
        expect(guestSwitchValue.value, true);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-QUICK_SETUP_GUEST-01-initial_state',
    );
  });

  group('Incredible-WiFi - Wifi list view - Advanced Mode', () {
    setUp(() {
      final wifiBundleTestStateInitialState = getWifiBundleTestState(
          wifiListTestData: wifiListAdvancedModeTestState);
      when(testHelper.mockWiFiBundleNotifier.build())
          .thenReturn(wifiBundleTestStateInitialState);
    });

    // Test ID: IWWL-ADV_INIT
    testLocalizationsV2(
      'Verify wifi list view in advanced mode',
      (tester, screen) async {
        await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        expect(find.byType(AdvancedModeView), findsOneWidget);
        expect(find.byKey(const ValueKey('WiFiCard-RADIO_2.4GHz')),
            findsOneWidget);
        expect(
            find.byKey(const ValueKey('WiFiCard-RADIO_5GHz')), findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-ADV_INIT-01-initial_state',
    );

    // Test ID: IWWL-ADV_INIT_GUEST
    testLocalizationsV2(
      'Verify wifi list view in advanced mode with guest wifi on',
      (tester, screen) async {
        final wifiBundleTestStateInitialState = getWifiBundleTestState(
            wifiListTestData: wifiListAdvancedModeGuestEnableTestState);
        when(testHelper.mockWiFiBundleNotifier.build())
            .thenReturn(wifiBundleTestStateInitialState);

        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();
        expect(find.byType(AdvancedModeView), findsOneWidget);
        expect(find.text(testHelper.loc(context).guest), findsOneWidget);
        final guestSwitchFinder = find.byKey(Key('WiFiGuestSwitch'));
        final AppSwitch guestSwitchValue = tester.widget(guestSwitchFinder);
        expect(guestSwitchValue.value, true);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-ADV_INIT_GUEST-01-initial_state',
    );

    // Test ID: IWWL-SSID
    testLocalizationsV2(
      'Verify SSID name input and validation',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        final wifiCard24GHzFinder =
            find.byKey(const ValueKey('WiFiCard-RADIO_2.4GHz'));
        final wifiNameFinder = find.descendant(
            of: wifiCard24GHzFinder,
            matching: find.byKey(const ValueKey('wifiNameCard-RADIO_2.4GHz')));
        expect(wifiNameFinder, findsOneWidget);
        await scrollAndTap(tester, wifiNameFinder);
        await testHelper.takeScreenshot(tester, 'IWWL-SSID-01-edit_dialog');

        final wifiNameInputFinder = find.bySemanticsLabel('wifi name');
        expect(wifiNameInputFinder, findsOneWidget);
        await tester.tap(wifiNameInputFinder);
        await tester.enterText(wifiNameInputFinder, '');
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).theNameMustNotBeEmpty),
            findsOneWidget);
        await testHelper.takeScreenshot(tester, 'IWWL-SSID-02-empty_error');

        await tester.tap(wifiNameInputFinder);
        await tester.enterText(wifiNameInputFinder, ' surround space error ');
        await tester.pumpAndSettle();
        expect(
            find.text(
                testHelper.loc(context).routerPasswordRuleStartEndWithSpace),
            findsOneWidget);
        await testHelper.takeScreenshot(
            tester, 'IWWL-SSID-03-surround_space_error');

        await tester.tap(wifiNameInputFinder);
        await tester.enterText(wifiNameInputFinder,
            'This is a looooooooooooooooooooooooooooooooooooooooooooong wifi name');
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).wifiSSIDLengthLimit),
            findsOneWidget);
        await testHelper.takeScreenshot(tester, 'IWWL-SSID-04-length_error');
      },
      helper: testHelper,
      screens: _wifiListScreens,
    );

    // Test ID: IWWL-PASSWORD
    testLocalizationsV2(
      'Verify password input and validation',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        final wifiCard5GHzFinder = find.byKey(ValueKey('WiFiCard-RADIO_5GHz'));
        final wifiPasswordFinder = find.descendant(
            of: wifiCard5GHzFinder,
            matching: find.byKey(ValueKey('wifiPasswordCard-RADIO_5GHz')));

        final passWidget = tester.widget<AppCard>(wifiPasswordFinder);
        expect(passWidget.onTap, isNotNull);

        expect(wifiPasswordFinder, findsOneWidget);
        await scrollAndTap(tester, wifiPasswordFinder);
        await testHelper.takeScreenshot(tester, 'IWWL-PASSWORD-01-edit_dialog');

        final wifiPasswordInputFinder =
            find.byKey(ValueKey('wifi password input'));
        expect(wifiPasswordInputFinder, findsOneWidget);
        await scrollAndTap(tester, wifiPasswordInputFinder);
        await tester.enterText(wifiPasswordInputFinder, ' 嗨');
        await tester.pumpAndSettle();
        expect(find.byIcon(AppFontIcons.close), findsExactly(3));
        await testHelper.takeScreenshot(
            tester, 'IWWL-PASSWORD-02-invalid_char_error');
      },
      helper: testHelper,
      screens: _wifiListScreens,
    );

    // Test ID: IWWL-SECURITY
    testLocalizationsV2(
      'Verify security mode selection',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        final wifiCard24GHzFinder =
            find.byKey(const ValueKey('WiFiCard-RADIO_2.4GHz'));
        final securityModeFinder = find.descendant(
            of: wifiCard24GHzFinder,
            matching:
                find.byKey(const ValueKey('wifiSecurityCard-RADIO_2.4GHz')));
        expect(securityModeFinder, findsOneWidget);
        await scrollAndTap(tester, securityModeFinder);
        await tester.pumpAndSettle();
        final alertFinder = find.byType(AppDialog);
        expect(alertFinder, findsOneWidget);
        final securityModeDialogFinder = find.descendant(
            of: alertFinder,
            matching: find.text(testHelper.loc(context).securityMode));
        expect(securityModeDialogFinder, findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-SECURITY-01-selection_dialog',
    );

    // Test ID: IWWL-WIFI_MODE
    testLocalizationsV2(
      'Verify wifi mode selection',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        final wifiCard24GHzFinder =
            find.byKey(const ValueKey('WiFiCard-RADIO_2.4GHz'));
        final wifiModeFinder = find.descendant(
            of: wifiCard24GHzFinder,
            matching: find
                .byKey(const ValueKey('wifiWirelessModeCard-RADIO_2.4GHz')));
        await scrollAndTap(tester, wifiModeFinder);
        await tester.pumpAndSettle();
        final alertFinder = find.byType(AppDialog);
        expect(alertFinder, findsOneWidget);
        final wifiModeDialogFinder = find.descendant(
            of: alertFinder,
            matching: find.text(testHelper.loc(context).wifiMode));
        expect(wifiModeDialogFinder, findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-WIFI_MODE-01-selection_dialog',
    );

    // Test ID: IWWL-CHANNEL_WID
    testLocalizationsV2(
      'Verify channel width selection',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        final wifiCard24GHzFinder =
            find.byKey(const ValueKey('WiFiCard-RADIO_2.4GHz'));
        final channelWidthFinder = find.descendant(
            of: wifiCard24GHzFinder,
            matching: find
                .byKey(const ValueKey('wifiChannelWidthCard-RADIO_2.4GHz')));
        await scrollAndTap(tester, channelWidthFinder);
        await tester.pumpAndSettle();
        final alertFinder = find.byType(AppDialog);
        expect(alertFinder, findsOneWidget);
        final channelWidthDialogFinder = find.descendant(
            of: alertFinder,
            matching: find.text(testHelper.loc(context).channelWidth));
        expect(channelWidthDialogFinder, findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-CHANNEL_WID-01-selection_dialog',
    );

    // Test ID: IWWL-CHANNEL
    testLocalizationsV2(
      'Verify channel selection',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();

        final wifiCard24GHzFinder =
            find.byKey(const ValueKey('WiFiCard-RADIO_2.4GHz'));
        final channelFinder = find.descendant(
            of: wifiCard24GHzFinder,
            matching:
                find.byKey(const ValueKey('wifiChannelCard-RADIO_2.4GHz')));
        await scrollAndTap(tester, channelFinder);
        await tester.pumpAndSettle();
        final alertFinder = find.byType(AppDialog);
        expect(alertFinder, findsOneWidget);
        final channelDialogFinder = find.descendant(
            of: alertFinder,
            matching: find.text(testHelper.loc(context).channel));
        expect(channelDialogFinder, findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-CHANNEL-01-selection_dialog',
    );

    // Test ID: IWWL-DISCARD
    testLocalizationsV2(
      'Verify discard changes modal',
      (tester, screen) async {
        when(testHelper.mockWiFiBundleNotifier.isDirty()).thenReturn(true);

        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();
        final advancedTabFinder = find.text(testHelper.loc(context).advanced);
        await tester.tap(advancedTabFinder);
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).unsavedChangesTitle),
            findsOneWidget);
        expect(
            find.text(testHelper.loc(context).discardChanges), findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-DISCARD-01-modal_shown',
    );

    // Test ID: IWWL-SAVE_CONFIRM
    testLocalizationsV2(
      'Verify save confirmation modal',
      (tester, screen) async {
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester.pumpAndSettle();
        await tester
            .tap(find.widgetWithText(AppButton, testHelper.loc(context).save));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).wifiListSaveModalTitle),
            findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-SAVE_CONFIRM-01-modal_shown',
    );

    // Test ID: IWWL-WIFI_MODE_INVALID
    testLocalizationsV2(
      'Verify wifi mode with invalid value',
      (tester, screen) async {
        final wifiBundleTestStateInitialState = getWifiBundleTestState(
            wifiListTestData: wifiListInvalidWirelessModeTestState);
        when(testHelper.mockWiFiBundleNotifier.build())
            .thenReturn(wifiBundleTestStateInitialState);
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );
        final wifiCard24GHzFinder =
            find.byKey(const ValueKey('WiFiCard-RADIO_2.4GHz'));
        final wifiModeFinder = find.descendant(
            of: wifiCard24GHzFinder,
            matching: find
                .byKey(const ValueKey('wifiWirelessModeCard-RADIO_2.4GHz')));
        await scrollAndTap(tester, wifiModeFinder);
        await tester.pumpAndSettle();

        final alertFinder = find.byType(AppDialog);
        expect(alertFinder, findsOneWidget);
        final wifiModeAlertFinder = find.descendant(
            of: alertFinder,
            matching: find.text(testHelper.loc(context).wifiMode));

        expect(wifiModeAlertFinder, findsOneWidget);
        expect(find.text(testHelper.loc(context).wifiModeNotAvailable),
            findsAtLeast(1));
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-WIFI_MODE_INVALID-01-dialog_shown',
    );

    // Test ID: IWWL-CHANNEL_WID_UNAVAIL
    testLocalizationsV2(
      'Verify channel width with unavailable value',
      (tester, screen) async {
        final wifiBundleTestStateInitialState = getWifiBundleTestState(
            wifiListTestData: wifiListUnavailableChannelWidthTestState);
        when(testHelper.mockWiFiBundleNotifier.build())
            .thenReturn(wifiBundleTestStateInitialState);
        when(testHelper.mockWiFiBundleNotifier.state)
            .thenReturn(wifiBundleTestStateInitialState);
        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );
        final wifiCardFinder =
            find.byKey(const ValueKey('WiFiCard-RADIO_5GHz'));

        final channelWidthFinder = find.descendant(
            of: wifiCardFinder,
            matching:
                find.byKey(const ValueKey('wifiChannelWidthCard-RADIO_5GHz')));
        await scrollAndTap(tester, channelWidthFinder);
        await tester.pumpAndSettle();

        final alertFinder = find.byType(AppDialog);
        expect(alertFinder, findsOneWidget);
        final channelWidthAlertFinder = find.descendant(
            of: alertFinder,
            matching: find.text(testHelper.loc(context).channelWidth));

        expect(channelWidthAlertFinder, findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-CHANNEL_WID_UNAVAIL-01-dialog_shown',
    );

    // Test ID: IWWL-SAVE_CONFIRM_DISABLE_BAND
    testLocalizationsV2(
      'Verify save confirmation modal with disable band warning',
      (tester, screen) async {
        final wifiBundleTestStateInitialState = getWifiBundleTestState(
            wifiListTestData: wifiListAdvancedModeGuestEnableTestState);
        final wifiState =
            WiFiListSettings.fromMap(wifiListAdvancedModeGuestEnableTestState);
        final changedMainWiFi =
            List<WiFiItem>.from(wifiState.mainWiFi).map((e) {
          if (e.radioID == WifiRadioBand.radio_24) {
            return e.copyWith(isEnabled: false);
          }
          return e;
        }).toList();
        final updatedWifiState = wifiState.copyWith(mainWiFi: changedMainWiFi);
        final updatedWifiBundleTestStateInitialState =
            wifiBundleTestStateInitialState.copyWith(
          settings: Preservable(
            original: wifiBundleTestStateInitialState.settings.original,
            current: wifiBundleTestStateInitialState.settings.current
                .copyWith(wifiList: updatedWifiState),
          ),
        );

        when(testHelper.mockWiFiBundleNotifier.build())
            .thenReturn(updatedWifiBundleTestStateInitialState);

        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        // After UI Kit migration, pageBottomPositiveButton key no longer exists
        // Use widgetWithText to find save button
        await tester
            .tap(find.widgetWithText(AppButton, testHelper.loc(context).save));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).wifiListSaveModalTitle),
            findsOneWidget);
        expect(
            find.text(testHelper
                .loc(context)
                .disableBandWarning(WifiRadioBand.radio_24.bandName)),
            findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-SAVE_CONFIRM_DISABLE_BAND-01-warning_shown',
    );

    // Test ID: IWWL-SAVE_CONFIRM_MLO
    testLocalizationsV2(
      'Verify save confirmation modal with MLO warning',
      (tester, screen) async {
        when(testHelper.mockWiFiBundleNotifier.checkingMLOSettingsConflicts(any,
                isMloEnabled: anyNamed('isMloEnabled')))
            .thenReturn(true);

        final context = await testHelper.pumpShellView(
          tester,
          child: const WiFiMainView(),
          locale: screen.locale,
        );

        await tester
            .tap(find.widgetWithText(AppButton, testHelper.loc(context).save));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).wifiListSaveModalTitle),
            findsOneWidget);
        expect(find.text(testHelper.loc(context).mloWarning), findsOneWidget);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-SAVE_CONFIRM_MLO-01-warning_shown',
    );

    // Test ID: IWWL-NO_GUEST
    testLocalizationsV2(
      'Verify wifi list view when guest wifi is not supported',
      (tester, screen) async {
        when(testHelper.mockServiceHelper.isSupportGuestNetwork())
            .thenReturn(false);
        when(testHelper.mockServiceHelper.isSupportLedMode()).thenReturn(false);
        final wifiBundleTestStateInitialState = getWifiBundleTestState(
            wifiListTestData: wifiListGuestEnabledTestState);
        when(testHelper.mockWiFiBundleNotifier.build())
            .thenReturn(wifiBundleTestStateInitialState);
        when(testHelper.mockWiFiBundleNotifier.state)
            .thenReturn(wifiBundleTestStateInitialState);

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const WiFiMainView(),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('WiFiGuestCard')), findsNothing);
      },
      helper: testHelper,
      screens: _wifiListScreens,
      goldenFilename: 'IWWL-NO_GUEST-01-initial_state',
    );
  });
}
