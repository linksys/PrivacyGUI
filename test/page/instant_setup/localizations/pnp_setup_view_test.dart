import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_stepper.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/config.dart';
import '../../../common/test_helper_v2.dart';
import '../../../common/test_responsive_widget.dart';

class FakePnpNotifier extends BasePnpNotifier {
  final PnpState _initialState;
  FakePnpNotifier(this._initialState);

  @override
  PnpState build() {
    return _initialState;
  }

  @override
  void setStepData(PnpStepId stepId, {required Map<String, dynamic> data}) {
    final newStepStateList =
        Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    final currentStepState = newStepStateList[stepId] ??
        const PnpStepState(status: StepViewStatus.data, data: {});
    final newData = Map<String, dynamic>.from(currentStepState.data);
    newData.addAll(data);
    newStepStateList[stepId] = currentStepState.copyWith(data: newData);
    state = state.copyWith(stepStateList: newStepStateList);
  }

  @override
  Future<void> savePnpSettings() async {
    state = state.copyWith(status: PnpFlowStatus.wizardSaving);
    await Future.delayed(const Duration(milliseconds: 50));
    state = state.copyWith(status: PnpFlowStatus.wizardConfiguring);
  }

  @override
  void validateStep(PnpStep step) {
    final data = step.getValidationData();
    bool hasError = false;
    Map<String, String?> errors = {};

    if (step.stepId == PnpStepId.personalWifi ||
        step.stepId == PnpStepId.guestWifi) {
      if (data['ssid'] == null || data['ssid'] == '') {
        hasError = true;
        errors['ssid'] = 'Required';
      } else if ((data['ssid'] as String).length > 32) {
        hasError = true;
        errors['ssid'] = 'Too long';
      }

      if (data['password'] == null || data['password'] == '') {
        hasError = true;
        errors['password'] = 'Required';
      } else if ((data['password'] as String).length < 8) {
        hasError = true;
        errors['password'] = 'Too short';
      } else if ((data['password'] as String).length > 64) {
        hasError = true;
        errors['password'] = 'Too long';
      }
    }

    final currentStepState = getStepState(step.stepId);
    final newStepState = currentStepState.copyWith(
      status: hasError ? StepViewStatus.error : StepViewStatus.data,
      error: hasError ? errors : null,
    );
    setStepState(step.stepId, newStepState);
  }

  @override
  Future<void> startPnpFlow(String? password) async {}
  @override
  Future<void> submitPassword(String password) async {}
  @override
  Future<void> continueFromUnconfigured() async {}
  @override
  Future<void> initializeWizard() async {}
  @override
  Future<void> testPnpReconnect() async {}
  @override
  Future<void> completeFwCheck() async {}
  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {}
  @override
  Future checkAdminPassword(String? password) async {}
  @override
  Future checkInternetConnection([int retries = 1]) async {}
  @override
  Future<ConfigurationResult> checkRouterConfigured() async =>
      ConfigurationResult(status: ConfigStatus.configured);
  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() async => null;
  @override
  Future<bool> isRouterPasswordSet() async => true;
  @override
  Future testConnectionReconnected() async {}
  @override
  Future fetchDevices() async {}
  @override
  void setForceLogin(bool force) {}
  @override
  void setAttachedPassword(String? password) {}
  @override
  ({
    String name,
    String password,
    String security
  }) getDefaultWiFiNameAndPassphrase() =>
      (name: 'MyTestWiFi', password: 'MyTestPassword123', security: '');
  @override
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() =>
      (name: 'MyGuestWiFi', password: 'MyGuestPassword');
}

void main() {
  final testHelper = TestHelperV2();
  final screens = responsiveAllScreens;

  final _tallDesktopScreens = responsiveDesktopScreens
      .map((screen) => screen.copyWith(height: 1080))
      .toList();
  final _tallScreens = [
    ...responsiveMobileScreens,
    ..._tallDesktopScreens,
  ];

  PnpState getDefaultPnpState(PnpFlowStatus status,
      {bool isUnconfigured = false,
      bool forceLogin = false,
      List<PnpChildNodeUIModel>? childNodes}) {
    return PnpState(
      status: status,
      deviceInfo: PnpDeviceInfoUIModel(
        modelName: 'LN16',
        image: 'routerLn12',
        serialNumber: 'serialNumber',
        firmwareVersion: 'firmwareVersion',
      ),
      capabilities: const PnpDeviceCapabilitiesUIModel(
        isGuestWiFiSupported: true,
        isNightModeSupported: true,
      ),
      isUnconfigured: isUnconfigured,
      forceLogin: forceLogin,
      childNodes: childNodes ?? [],
      stepStateList: const {
        PnpStepId.personalWifi: PnpStepState(
          status: StepViewStatus.data,
          data: {'ssid': 'MyTestWiFi', 'password': 'MyTestPassword123'},
        ),
        PnpStepId.guestWifi:
            PnpStepState(status: StepViewStatus.data, data: {}),
        PnpStepId.nightMode:
            PnpStepState(status: StepViewStatus.data, data: {}),
        PnpStepId.yourNetwork:
            PnpStepState(status: StepViewStatus.data, data: {}),
      },
    );
  }

  setUp(() {
    testHelper.setup();
  });

  group('PnpSetupView screenshot tests based on PnpFlowStatus', () {
    // Test ID: PNPS-WIZ_INIT
    testLocalizationsV3(
      'Verify the initial loading screen of the wizard',
      (tester, screen) async {
        final fakeNotifier = FakePnpNotifier(
            getDefaultPnpState(PnpFlowStatus.wizardInitializing));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );
        await tester.pump();

        expect(find.text(testHelper.loc(context).processing), findsOneWidget);
        expect(find.byKey(const Key('pnp_loading_spinner')), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_INIT_01-initial_state',
      helper: testHelper,
    );

    group('status: wizardConfiguring', () {
      // Test ID: PNPS-STEP1_WIFI
      testLocalizationsV3(
        'Verify interactions on the "Personal WiFi" step',
        (tester, screen) async {
          final fakeNotifier = FakePnpNotifier(
              getDefaultPnpState(PnpFlowStatus.wizardConfiguring));

          await testHelper.pumpView(
            tester,
            child: const PnpSetupView(),
            config: LinksysRouteConfig(
                column: ColumnGrid(column: 6, centered: true),
                noNaviRail: true),
            locale: screen.locale,
            overrides: [
              pnpProvider.overrideWith(() => fakeNotifier),
            ],
          );
          await tester.pumpAndSettle();

          final infoButton = find.byIcon(AppFontIcons.infoCircle);
          expect(infoButton, findsOneWidget);
          await tester.tap(infoButton);
          await tester.pumpAndSettle();
          await testHelper.takeScreenshot(
              tester, 'PNPS-STEP1_WIFI_01-info_dialog');
          final closeButton =
              find.byKey(const Key('pnp_wifi_info_close_button'));
          expect(closeButton, findsOneWidget);
          await tester.tap(closeButton);
          await tester.pumpAndSettle();

          final ssidField = find.byType(WiFiSSIDField);
          expect(ssidField, findsOneWidget);
          await tester.enterText(ssidField, '');
          await tester.pumpAndSettle();
          await testHelper.takeScreenshot(
              tester, 'PNPS-STEP1_WIFI_02-ssid_error');

          final passwordField = find.byType(WiFiPasswordField);
          expect(passwordField, findsOneWidget);
          await tester.enterText(passwordField, '123');
          await tester.pumpAndSettle();
          await testHelper.takeScreenshot(
              tester, 'PNPS-STEP1_WIFI_03-password_error');

          await tester.enterText(ssidField, 'MyTestWiFi');
          await tester.enterText(passwordField, 'MyTestPassword123');
          await tester.pumpAndSettle();
        },
        screens: _tallScreens,
        goldenFilename: 'PNPS-STEP1_WIFI_04-final_state',
        helper: testHelper,
      );

      // Test ID: PNPS-STEP2_GST
      testLocalizationsV3(
        'Verify interactions on the "Guest WiFi" step',
        (tester, screen) async {
          final fakeNotifier = FakePnpNotifier(
              getDefaultPnpState(PnpFlowStatus.wizardConfiguring));

          await testHelper.pumpView(
            tester,
            child: const PnpSetupView(),
            config: LinksysRouteConfig(
                column: ColumnGrid(column: 6, centered: true),
                noNaviRail: true),
            locale: screen.locale,
            overrides: [
              pnpProvider.overrideWith(() => fakeNotifier),
            ],
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();

          final guestSwitch = find.byType(AppSwitch);
          expect(guestSwitch, findsOneWidget);
          await tester.tap(guestSwitch);
          await tester.pumpAndSettle();
          await testHelper.takeScreenshot(
              tester, 'PNPS-STEP2_GST_01-switch_on');

          final guestSsidField = find.byType(WiFiSSIDField);
          expect(guestSsidField, findsOneWidget);
          await tester.enterText(guestSsidField, '');
          await tester.pumpAndSettle();
          await testHelper.takeScreenshot(
              tester, 'PNPS-STEP2_GST_02-ssid_error');

          final guestPasswordField = find.byType(WiFiPasswordField);
          expect(guestPasswordField, findsOneWidget);
          await tester.enterText(guestPasswordField, '123');
          await tester.pumpAndSettle();
          await testHelper.takeScreenshot(
              tester, 'PNPS-STEP2_GST_03-password_error');

          await tester.enterText(guestSsidField, 'MyGuestWiFi');
          await tester.enterText(guestPasswordField, 'MyGuestPassword');
          await tester.pumpAndSettle();

          await tester.tap(guestSwitch);
          await tester.pumpAndSettle();
        },
        screens: _tallScreens,
        goldenFilename: 'PNPS-STEP2_GST_04-final_state',
        helper: testHelper,
      );

      // Test ID: PNPS-STEP3_NIT
      testLocalizationsV3(
        'Verify interactions on the "Night Mode" step',
        (tester, screen) async {
          final fakeNotifier = FakePnpNotifier(
              getDefaultPnpState(PnpFlowStatus.wizardConfiguring));

          await testHelper.pumpView(
            tester,
            child: const PnpSetupView(),
            config: LinksysRouteConfig(
                column: ColumnGrid(column: 6, centered: true),
                noNaviRail: true),
            locale: screen.locale,
            overrides: [
              pnpProvider.overrideWith(() => fakeNotifier),
            ],
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();

          final nightModeSwitch = find.byType(AppSwitch);
          expect(nightModeSwitch, findsOneWidget);
          await tester.tap(nightModeSwitch);
          await tester.pumpAndSettle();
          await testHelper.takeScreenshot(
              tester, 'PNPS-STEP3_NIT_01-switch_on');

          await tester.tap(nightModeSwitch);
          await tester.pumpAndSettle();
        },
        screens: _tallScreens,
        goldenFilename: 'PNPS-STEP3_NIT_02-final_state',
        helper: testHelper,
      );

      // Test ID: PNPS-STEP4_NET
      testLocalizationsV3(
        'Verify the "Your Network" step with no child nodes',
        (tester, screen) async {
          final initialState = getDefaultPnpState(
              PnpFlowStatus.wizardConfiguring,
              isUnconfigured: true);
          final fakeNotifier = FakePnpNotifier(initialState);

          final context = await testHelper.pumpView(
            tester,
            child: const PnpSetupView(),
            config: LinksysRouteConfig(
                column: ColumnGrid(column: 6, centered: true),
                noNaviRail: true),
            locale: screen.locale,
            overrides: [
              pnpProvider.overrideWith(() => fakeNotifier),
            ],
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();

          expect(find.text(testHelper.loc(context).pnpYourNetworkTitle),
              findsAtLeastNWidgets(1));
          expect(find.widgetWithText(AppButton, testHelper.loc(context).done),
              findsOneWidget);
        },
        screens: _tallScreens,
        goldenFilename: 'PNPS-STEP4_NET_01-final_state',
        helper: testHelper,
      );

      // Test ID: PNPS-NET_CHILD
      testLocalizationsV3(
        'Verify the "Your Network" step with child nodes displayed',
        (tester, screen) async {
          final childNodes = [
            const PnpChildNodeUIModel(
                location: 'Living Room', modelNumber: 'MX5500'),
            const PnpChildNodeUIModel(
                location: 'Bedroom', modelNumber: 'MX4200'),
          ];
          final initialState = getDefaultPnpState(
            PnpFlowStatus.wizardConfiguring,
            isUnconfigured: true,
            childNodes: childNodes,
          );
          final fakeNotifier = FakePnpNotifier(initialState);

          final context = await testHelper.pumpView(
            tester,
            child: const PnpSetupView(),
            config: LinksysRouteConfig(
                column: ColumnGrid(column: 6, centered: true),
                noNaviRail: true),
            locale: screen.locale,
            overrides: [
              pnpProvider.overrideWith(() => fakeNotifier),
            ],
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('pnp_stepper_next_button')));
          await tester.pumpAndSettle();

          expect(find.text(testHelper.loc(context).pnpYourNetworkTitle),
              findsAtLeastNWidgets(1));
          expect(find.text('Living Room'), findsAtLeastNWidgets(1));
          expect(find.text('Bedroom'), findsAtLeastNWidgets(1));
          expect(find.widgetWithText(AppButton, testHelper.loc(context).done),
              findsOneWidget);
        },
        screens: _tallScreens,
        goldenFilename: 'PNPS-NET_CHILD_01-final_state',
        helper: testHelper,
      );
    });

    // Test ID: PNPS-WIZ_SAVE
    testLocalizationsV3(
      'Verify the "Saving" screen',
      (tester, screen) async {
        final fakeNotifier =
            FakePnpNotifier(getDefaultPnpState(PnpFlowStatus.wizardSaving));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );
        await tester.pump();

        expect(find.text(testHelper.loc(context).processing), findsOneWidget);
        expect(find.byKey(const Key('pnp_loading_spinner')), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_SAVE_01-saving_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-WIZ_SAVED
    testLocalizationsV3(
      'Verify the "Saved" confirmation screen',
      (tester, screen) async {
        final fakeNotifier =
            FakePnpNotifier(getDefaultPnpState(PnpFlowStatus.wizardSaved));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byIcon(AppFontIcons.checkCircle), findsOneWidget);
        expect(find.text(testHelper.loc(context).saved), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_SAVED_01-confirmation_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-WIZ_RECONN
    testLocalizationsV3(
      'Verify the "Needs Reconnect" screen',
      (tester, screen) async {
        final fakeNotifier = FakePnpNotifier(
            getDefaultPnpState(PnpFlowStatus.wizardNeedsReconnect));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );

        await tester.pump();

        expect(find.byIcon(AppFontIcons.wifi), findsOneWidget);
        expect(find.text(testHelper.loc(context).pnpReconnectWiFi),
            findsOneWidget);
        expect(
            find.descendant(
              of: find.byKey(const Key('pnp_reconnect_next_button')),
              matching: find.byType(AppButton),
            ),
            findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_RECONN_01-needs_reconnect_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-WIZ_TST_REC
    testLocalizationsV3(
      'Verify the "Testing Reconnect" screen',
      (tester, screen) async {
        final fakeNotifier = FakePnpNotifier(
            getDefaultPnpState(PnpFlowStatus.wizardTestingReconnect));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );
        await tester.pump();

        expect(find.text(testHelper.loc(context).processing), findsOneWidget);
        expect(find.byKey(const Key('pnp_loading_spinner')), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_TST_REC_01-testing_reconnect_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-WIZ_FW_CHK
    testLocalizationsV3(
      'Verify the "Checking Firmware" screen',
      (tester, screen) async {
        final fakeNotifier = FakePnpNotifier(
            getDefaultPnpState(PnpFlowStatus.wizardCheckingFirmware));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );

        await tester.pump();

        expect(find.byKey(const Key('pnp_fw_update_spinner')), findsOneWidget);
        expect(find.text(testHelper.loc(context).pnpFwUpdateTitle),
            findsOneWidget);
        expect(
            find.text(testHelper.loc(context).pnpFwUpdateDesc), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_FW_CHK_01-checking_firmware_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-WIZ_FW_UPD
    testLocalizationsV3(
      'Verify the "Updating Firmware" screen',
      (tester, screen) async {
        final fakeNotifier = FakePnpNotifier(
            getDefaultPnpState(PnpFlowStatus.wizardUpdatingFirmware));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );

        await tester.pump();

        expect(find.byKey(const Key('pnp_fw_update_spinner')), findsOneWidget);
        expect(find.text(testHelper.loc(context).pnpFwUpdateTitle),
            findsOneWidget);
        expect(
            find.text(testHelper.loc(context).pnpFwUpdateDesc), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_FW_UPD_01-updating_firmware_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-WIZ_RDY
    testLocalizationsV3(
      'Verify the "WiFi Ready" screen',
      (tester, screen) async {
        final fakeNotifier =
            FakePnpNotifier(getDefaultPnpState(PnpFlowStatus.wizardWifiReady));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );

        await tester.pump();

        expect(find.byIcon(AppFontIcons.wifi), findsOneWidget);
        expect(find.text(testHelper.loc(context).pnpWiFiReady('MyTestWiFi')),
            findsOneWidget);
        expect(find.widgetWithText(AppButton, testHelper.loc(context).done),
            findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-WIZ_RDY_01-wifi_ready_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-INIT_FAIL
    testLocalizationsV3(
      'Verify the wizard initialization failure screen',
      (tester, screen) async {
        final fakeNotifier =
            FakePnpNotifier(getDefaultPnpState(PnpFlowStatus.wizardInitFailed));

        final context = await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );

        await tester.pump();

        expect(find.text(testHelper.loc(context).generalError), findsOneWidget);
        expect(find.widgetWithText(AppButton, testHelper.loc(context).tryAgain),
            findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-INIT_FAIL_01-failure_screen',
      helper: testHelper,
    );

    // Test ID: PNPS-SAVE_FAIL
    testLocalizationsV3(
      'Verify the wizard save failure screen',
      (tester, screen) async {
        final fakeNotifier =
            FakePnpNotifier(getDefaultPnpState(PnpFlowStatus.wizardSaveFailed));

        await testHelper.pumpView(
          tester,
          child: const PnpSetupView(),
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          locale: screen.locale,
          overrides: [
            pnpProvider.overrideWith(() => fakeNotifier),
          ],
        );
        await tester.pump();

        expect(find.byType(PnpStepper), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'PNPS-SAVE_FAIL_01-failure_screen',
      helper: testHelper,
    );
  });
}