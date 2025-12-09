import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/_providers.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';
import '../../../../../../common/config.dart';
import '../../../../../../common/test_helper.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';

// View ID: PNP-PPPOE
// Reference to Implementation File: lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart

/// File-Level Summary:
/// This file contains screenshot tests for the PnpPPPOEView.
///
/// Covered Test Cases:
/// - PNP-PPPOE_UI-FLOW: Verifies the initial UI and VLAN toggle functionality.
/// - PNP-PPPOE_SAVE-ERROR-GENERIC: Verifies the UI for a generic JNAPError during save.
/// - PNP-PPPOE_SAVE-ERROR-SPECIFIC-JNAP: Verifies the UI for a specific JNAPError during save.
/// - PNP-PPPOE_SAVE-ERROR-NO-INTERNET: Verifies the UI for no internet connection error during save.
/// - PNP-PPPOE_SAVE-ERROR-SIDE-EFFECT-SUCCESS: Verifies the UI for JNAPSideEffectError with JNAPSuccess during save.
/// - PNP-PPPOE_SAVE-ERROR-SIDE-EFFECT-OTHER: Verifies the UI for JNAPSideEffectError without JNAPSuccess during save.
/// - PNP-PPPOE_SAVE-PROGRESS: Verifies UI updates during the save and verify progress states.

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    final mockInternetSettingsState =
        InternetSettingsState.fromJson(internetSettingsStateData);
    when(testHelper.mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(testHelper.mockInternetSettingsNotifier
            .fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      return mockInternetSettingsState;
    });
    // Default successful save for the UI flow test
    when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
        .thenAnswer((_) async {});
  });

  // Test ID: PNP-PPPOE_UI-FLOW
  testLocalizationsV2(
    'Verify PPPoE view UI flow (initial and VLAN toggle)',
    (tester, localizedScreen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const PnpPPPOEView(),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Verify initial UI elements
      expect(find.text(testHelper.loc(context).pnpPppoeTitle), findsOneWidget);
      expect(
          find.text(testHelper.loc(context).pnpPppoeAddVlan), findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNP-PPPOE_UI-FLOW_01_initial_state');

      // Show VLAN ID field
      await tester.tap(find.text(testHelper.loc(context).pnpPppoeAddVlan));
      await tester.pumpAndSettle();
      expect(
          find.widgetWithText(
              AppTextField, testHelper.loc(context).vlanIdOptional),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpPppoeRemoveVlan),
          findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-PPPOE_UI-FLOW_02_with_vlan',
  );

  // Test ID: PNP-PPPOE_SAVE-ERROR-GENERIC
  testLocalizationsV2(
    'Verify generic JNAPError during PPPoE save',
    (tester, localizedScreen) async {
      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpPPPOEView(),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap next button to trigger the loading state
      await tester.tap(find.byType(AppFilledButton));
      await tester.pump(); // Rebuild the widget to show the spinner.

      // Verify the spinner is displayed
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);

      // Complete the future with a generic JNAPError
      completer.completeError(JNAPError(result: '', error: 'generic error'));
      await tester.pumpAndSettle(); // Let the UI handle the error and rebuild.

      // Verify error message is displayed and spinner is gone
      expect(find.byType(AppFullScreenSpinner), findsNothing);
      expect(
          find.text(testHelper.loc(context).pnpErrorForPppoe), findsOneWidget);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-PPPOE_SAVE-ERROR-GENERIC_01_error_message',
  );

  // Test ID: PNP-PPPOE_SAVE-ERROR-SPECIFIC-JNAP
  testLocalizationsV2(
    'Verify specific JNAPError during PPPoE save',
    (tester, localizedScreen) async {
      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpPPPOEView(),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap next button to trigger the loading state
      await tester.tap(find.byType(AppFilledButton));
      await tester.pump(); // Rebuild the widget to show the spinner.

      // Verify the spinner is displayed
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);

      // Complete the future with a specific JNAPError
      completer.completeError(
          JNAPError(result: errorInvalidGateway, error: 'specific error'));
      await tester.pumpAndSettle(); // Let the UI handle the error and rebuild.

      // Verify error message is displayed and spinner is gone
      expect(find.byType(AppFullScreenSpinner), findsNothing);
      expect(find.text(testHelper.loc(context).invalidGatewayIpAddress),
          findsOneWidget);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-PPPOE_SAVE-ERROR-SPECIFIC-JNAP_01_error_message',
  );

  // Test ID: PNP-PPPOE_SAVE-ERROR-NO-INTERNET
  testLocalizationsV2(
    'Verify no internet connection error during PPPoE save',
    (tester, localizedScreen) async {
      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpPPPOEView(),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap next button to trigger the loading state
      await tester.tap(find.byType(AppFilledButton));
      await tester.pump(); // Rebuild the widget to show the spinner.

      // Verify the spinner is displayed
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);

      // Complete the future with ExceptionNoInternetConnection
      completer.completeError(ExceptionNoInternetConnection());
      await tester.pumpAndSettle(); // Let the UI handle the error and rebuild.

      // Verify error message is displayed and spinner is gone
      expect(find.byType(AppFullScreenSpinner), findsNothing);
      expect(
          find.text(testHelper.loc(context).pnpErrorForPppoe), findsOneWidget);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-PPPOE_SAVE-ERROR-NO-INTERNET_01_error_message',
  );

  // Test ID: PNP-PPPOE_SAVE-ERROR-SIDE-EFFECT-SUCCESS
  testLocalizationsV2(
    'Verify JNAPSideEffectError with JNAPSuccess during PPPoE save',
    (tester, localizedScreen) async {
      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpPPPOEView(),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap next button to trigger the loading state
      await tester.tap(find.byType(AppFilledButton));
      await tester.pump(); // Rebuild the widget to show the spinner.

      // Verify the spinner is displayed
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);

      // Complete the future with JNAPSideEffectError with JNAPSuccess
      completer.completeError(JNAPSideEffectError(
          const JNAPSuccess(output: {}, result: 'Success'),
          const JNAPSuccess(output: {}, result: 'Success')));
      await tester.pumpAndSettle(); // Let the UI handle the error and rebuild.

      // Verify error message is displayed and spinner is gone
      expect(find.byType(AppFullScreenSpinner), findsNothing);
      expect(
          find.text(testHelper.loc(context).pnpErrorForPppoe), findsOneWidget);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-PPPOE_SAVE-ERROR-SIDE-EFFECT-SUCCESS_01_error_message',
  );

  // Test ID: PNP-PPPOE_SAVE-ERROR-SIDE-EFFECT-OTHER
  testLocalizationsV2(
    'Verify JNAPSideEffectError without JNAPSuccess during PPPoE save',
    (tester, localizedScreen) async {
      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpPPPOEView(),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap next button to trigger the loading state
      await tester.tap(find.byType(AppFilledButton));
      await tester.pump(); // Rebuild the widget to show the spinner.

      // Verify the spinner is displayed
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);

      // Complete the future with JNAPSideEffectError without JNAPSuccess
      completer.completeError(JNAPSideEffectError(
          const JNAPSuccess(output: {}, result: 'Success')));
      await tester.pumpAndSettle(); // Hide spinner, trigger navigation

      expect(find.byType(AppFullScreenSpinner), findsNothing);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename:
        'PNP-PPPOE_SAVE-ERROR-SIDE-EFFECT-OTHER_01_router_not_found_alert',
  );

  // Test ID: PNP-PPPOE_SAVE-PROGRESS
  testLocalizationsV2(
    'Verify UI updates during save and verify progress',
    (tester, localizedScreen) async {
      // 1. Setup completers to control the flow
      final saveCompleter = Completer<void>();
      final verifySettingsCompleter = Completer<bool>();
      final checkInternetCompleter = Completer<bool>();

      // 2. Mock dependencies of the real PnpIspSettingsNotifier
      when(testHelper.mockInternetSettingsNotifier.savePnpIpv4(any))
          .thenAnswer((_) => saveCompleter.future);
      when(testHelper.mockPnpIspService.verifyNewSettings(any))
          .thenAnswer((_) => verifySettingsCompleter.future);
      when(testHelper.mockPnpService.checkInternetConnection(any))
          .thenAnswer((_) => checkInternetCompleter.future);

      await testHelper.pumpView(
        tester,
        child: const PnpPPPOEView(),
        locale: localizedScreen.locale,
        overrides: [
          pnpIspServiceProvider.overrideWithValue(testHelper.mockPnpIspService),
          pnpServiceProvider.overrideWithValue(testHelper.mockPnpService),
          internetSettingsProvider
              .overrideWith(() => testHelper.mockInternetSettingsNotifier),
        ],
        forceOverride: true,
      );
      await tester.pumpAndSettle();

      // 3. Trigger the save process
      await tester.tap(find.byType(AppFilledButton));
      await tester.pump(); // Let the state change to 'saving'

      // 4. Verify 'saving' state
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNP-PPPOE_SAVE-PROGRESS_01_saving');

      // 5. Move to 'checkSettings' state
      saveCompleter.complete();
      await tester.pump(); // Let the state change to 'checkSettings'
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNP-PPPOE_SAVE-PROGRESS_02_checking_settings');

      // 6. Move to 'checkInternetConnection' state
      verifySettingsCompleter.complete(true);
      await tester.pump(); // Let the state change to 'checkInternetConnection'
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNP-PPPOE_SAVE-PROGRESS_03_checking_internet');

      // 7. Complete the flow
      checkInternetCompleter.complete(true);
      await tester.pumpAndSettle(); // Let the UI handle success

      // Verify the spinner is gone
      expect(find.byType(AppFullScreenSpinner), findsNothing);
    },
    helper: testHelper,
    screens: screens,
  );
}
