// View ID: STV
// Reference: lib/page/health_check/views/speed_test_view.dart
//
// ## Test Cases
//
// | Test ID         | Description                                      |
// |-----------------|--------------------------------------------------|
// | STV-INIT-01     | Verify the initial idle state of the speed test. |
// | STV-PING-01     | Verify the UI during the ping phase.             |
// | STV-DOWNLOAD-01 | Verify the UI during the download phase.         |
// | STV-UPLOAD-01   | Verify the UI during the upload phase.           |
// | STV-SUCCESS-01  | Verify the UI for a successful result (Ultra).   |
// | STV-SUCCESS-02  | Verify the UI for a successful result (Optimal). |
// | STV-SUCCESS-03  | Verify the UI for a successful result (Good).    |
// | STV-SUCCESS-04  | Verify the UI for a successful result (Okay).    |
// | STV-ERROR-01    | Verify the UI when a configuration error occurs. |
// | STV-HISTORY-01  | Verify the history panel displays records.       |
// | STV-ACTION-01   | Verify tapping 'Go' button starts the test.      |
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/health_check_state_data.dart';

void main() {
  final testHelper = TestHelper();
  final screens = [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: e.height + 500)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: e.height + 100))
  ];

  setUp(() {
    testHelper.setup();
    // Default mock for runHealthCheck to avoid errors in interaction tests
    when(testHelper.mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {});
  });

  // Test ID: STV-INIT-01
  testLocalizationsV2(
    'Verify the initial idle state of the speed test.',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckInitState));

      final context = await testHelper.pumpView(
        tester,
        child: const SpeedTestView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await precacheImage(
            CustomTheme.of(context).images.speedtestPowered, context);
        await tester.pumpAndSettle();
      });

      expect(find.text(testHelper.loc(context).speedTest), findsOneWidget);
      expect(find.text(testHelper.loc(context).go), findsOneWidget);
      expect(
          find.text(testHelper.loc(context).speedTestHistory), findsOneWidget);
      expect(find.text(testHelper.loc(context).speedTestNoRecordsFound),
          findsOneWidget);
    },
    goldenFilename: 'STV-INIT-01-initial_state',
    helper: testHelper,
    screens: screens,
  );

  // Test ID: STV-PING-01
  testLocalizationsV2(
    'Verify the UI during the ping phase.',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckStatePing));

      await testHelper.pumpView(
        tester,
        child: const SpeedTestView(),
        locale: screen.locale,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('13 ms'), findsNWidgets(2));
    },
    goldenFilename: 'STV-PING-01-ping_phase',
    helper: testHelper,
    screens: screens,
  );

  // Test ID: STV-DOWNLOAD-01
  testLocalizationsV2(
    'Verify the UI during the download phase.',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckStateDownload));

      await testHelper.pumpView(
        tester,
        child: const SpeedTestView(),
        locale: screen.locale,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('567.8'), findsOneWidget);
    },
    goldenFilename: 'STV-DOWNLOAD-01-download_phase',
    helper: testHelper,
    screens: screens,
  );

  // Test ID: STV-UPLOAD-01
  testLocalizationsV2(
    'Verify the UI during the upload phase.',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckStateUpload));

      await testHelper.pumpView(
        tester,
        child: const SpeedTestView(),
        locale: screen.locale,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('12.3'), findsOneWidget);
    },
    goldenFilename: 'STV-UPLOAD-01-upload_phase',
    helper: testHelper,
    screens: screens,
  );

  group('Speedtest - success results', () {
    // Test ID: STV-SUCCESS-01
    testLocalizationsV2(
      'Verify the UI for a successful result (Ultra).',
      (tester, screen) async {
        when(testHelper.mockHealthCheckProvider.build()).thenReturn(
            HealthCheckState.fromJson(healthCheckStateSuccessUltra));
        final context = await testHelper.pumpView(
          tester,
          child: const SpeedTestView(),
          locale: screen.locale,
        );
        await tester.pump(const Duration(seconds: 2));
        // The following line will fail if `speedTestResultUltra` is not in your localization files.
        expect(find.text(testHelper.loc(context).speedUltraDescription),
            findsOneWidget);
        expect(
            find.widgetWithText(
                AppTextButton, testHelper.loc(context).testAgain),
            findsOneWidget);
      },
      goldenFilename: 'STV-SUCCESS-01-ultra',
      helper: testHelper,
      screens: screens,
    );

    // Test ID: STV-SUCCESS-02
    testLocalizationsV2(
      'Verify the UI for a successful result (Optimal).',
      (tester, screen) async {
        when(testHelper.mockHealthCheckProvider.build()).thenReturn(
            HealthCheckState.fromJson(healthCheckStateSuccessOptimal));
        final context = await testHelper.pumpView(
          tester,
          child: const SpeedTestView(),
          locale: screen.locale,
        );
        await tester.pump(const Duration(seconds: 2));

        // The following line will fail if `speedTestResultOptimal` is not in your localization files.
        expect(find.text(testHelper.loc(context).speedOptimalDescription),
            findsOneWidget);
      },
      goldenFilename: 'STV-SUCCESS-02-optimal',
      helper: testHelper,
      screens: screens,
    );

    // Test ID: STV-SUCCESS-03
    testLocalizationsV2(
      'Verify the UI for a successful result (Good).',
      (tester, screen) async {
        when(testHelper.mockHealthCheckProvider.build())
            .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessGood));
        final context = await testHelper.pumpView(
          tester,
          child: const SpeedTestView(),
          locale: screen.locale,
        );
        await tester.pump(const Duration(seconds: 2));

        // The following line will fail if `speedTestResultGood` is not in your localization files.
        expect(find.text(testHelper.loc(context).speedGoodDescription),
            findsOneWidget);
      },
      goldenFilename: 'STV-SUCCESS-03-good',
      helper: testHelper,
      screens: screens,
    );

    // Test ID: STV-SUCCESS-04
    testLocalizationsV2(
      'Verify the UI for a successful result (Okay).',
      (tester, screen) async {
        when(testHelper.mockHealthCheckProvider.build())
            .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessOkay));
        final context = await testHelper.pumpView(
          tester,
          child: const SpeedTestView(),
          locale: screen.locale,
        );
        await tester.pump(const Duration(seconds: 2));

        // The following line will fail if `speedTestResultOkay` is not in your localization files.
        expect(find.text(testHelper.loc(context).speedOkayDescription),
            findsOneWidget);
      },
      goldenFilename: 'STV-SUCCESS-04-okay',
      helper: testHelper,
      screens: screens,
    );
  });

  // Test ID: STV-ERROR-01
  testLocalizationsV2(
    'Verify the UI when a configuration error occurs.',
    (tester, screen) async {
      // Mock a state with a specific error code
      const errorState = HealthCheckState(
        status: HealthCheckStatus.complete,
        step: HealthCheckStep.error,
        errorCode: SpeedTestError.configuration,
      );
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(errorState);

      final context = await testHelper.pumpView(
        tester,
        child: const SpeedTestView(),
        locale: screen.locale,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text(testHelper.loc(context).speedTestConfigurationError),
          findsOneWidget);
      expect(
          find.widgetWithText(AppTextButton, testHelper.loc(context).testAgain),
          findsOneWidget);
    },
    goldenFilename: 'STV-ERROR-01-error_state',
    helper: testHelper,
    screens: screens,
  );

  // Test ID: STV-HISTORY-01
  testLocalizationsV2(
    'Verify the history panel displays records.',
    (tester, screen) async {
      // Mock a state with historical data
      final historyState =
          HealthCheckState.fromJson(healthCheckInitState).copyWith(
        historicalSpeedTests: [
          SpeedTestUIModel(
            timestamp: '2024-01-01 10:00 AM',
            downloadSpeed: '940.1',
            downloadUnit: 'Mb',
            uploadSpeed: '35.5',
            uploadUnit: 'Mb',
            latency: '5',
            serverId: '12345',
          ),
        ],
      );
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(historyState);

      final context = await testHelper.pumpView(
        tester,
        child: const SpeedTestView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      expect(
          find.text(testHelper.loc(context).speedTestHistory), findsOneWidget);
      expect(find.text(testHelper.loc(context).speedTestNoRecordsFound),
          findsNothing);
      // Verify the history item is displayed
      expect(find.text('940.1 Mbps'), findsOneWidget);
      expect(find.text('35.5 Mbps'), findsOneWidget);
    },
    goldenFilename: 'STV-HISTORY-01-with_history',
    helper: testHelper,
    screens: screens,
  );

  // Test ID: STV-ACTION-01
  testLocalizationsV2(
    'Verify tapping "Go" button starts the test.',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
          HealthCheckState.fromJson(healthCheckInitState)
              .copyWith(healthCheckModules: ['SpeedTest']));
      await testHelper.pumpView(
        tester,
        child: const SpeedTestView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      final runButton = find.byKey(const Key('goBtn'));
      expect(runButton, findsOneWidget);
      await tester.tap(runButton);
      await tester.pump();

      verify(testHelper.mockHealthCheckProvider
              .runHealthCheck(Module.speedtest))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
  );
}
