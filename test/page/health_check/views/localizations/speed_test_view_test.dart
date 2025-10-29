import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/dashboard_home_test_state.dart';
import '../../../../test_data/health_check_state_data.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('Speedtest - init', (tester, locale) async {
    when(testHelper.mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckInitState));

    await testHelper.pumpView(
      tester,
      child: const SpeedTestView(),
      locale: locale,
    );
  });

  testLocalizations('Speedtest - init with Ookla logo', (tester, locale) async {
    when(testHelper.mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckInitState));
    when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
            .copyWith(healthCheckModule: () => 'Ookla'));

    await testHelper.pumpView(
      tester,
      child: const SpeedTestView(),
      locale: locale,
    );

    await tester.runAsync(() async {
      final context = tester.element(find.byType(SpeedTestView));
      await precacheImage(
          CustomTheme.of(context).images.speedtestPowered, context);
      await tester.pumpAndSettle();
    });
  });

  testLocalizations('Speedtest - ping init', (tester, locale) async {
    when(testHelper.mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStatePingInit));
    when(testHelper.mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 5));
    });

    await testHelper.pumpView(
      tester,
      child: const SpeedTestView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Speedtest - ping finished', (tester, locale) async {
    when(testHelper.mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStatePing));
    when(testHelper.mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 5));
    });

    await testHelper.pumpView(
      tester,
      child: const SpeedTestView(),
      locale: locale,
    );

    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Speedtest - download', (tester, locale) async {
    when(testHelper.mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStateDownload));
    when(testHelper.mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await testHelper.pumpView(
      tester,
      child: const SpeedTestView(),
      locale: locale,
    );

    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Speedtest - upload', (tester, locale) async {
    when(testHelper.mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStateUpload));
    when(testHelper.mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {});

    await testHelper.pumpView(
      tester,
      child: const SpeedTestView(),
      locale: locale,
    );

    await tester.pump(const Duration(seconds: 2));
  });

  group('Speedtest - success', () {
    testLocalizations('Speedtest - success ultra', (tester, locale) async {
      final healthCheckSuccessUltraProvider = HealthCheckSuccessUltraProvider();
      await testHelper.pumpView(
        tester,
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessUltraProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );

      await tester.pump(const Duration(seconds: 2));
    });

    testLocalizations('Speedtest - success optimal', (tester, locale) async {
      final healthCheckSuccessOptimalProvider =
          HealthCheckSuccessOptimalProvider();
      await testHelper.pumpView(
        tester,
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessOptimalProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );

      await tester.pump(const Duration(seconds: 2));
    });

    testLocalizations('Speedtest - success good', (tester, locale) async {
      final healthCheckSuccessGoodProvider = HealthCheckSuccessGoodProvider();
      await testHelper.pumpView(
        tester,
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessGoodProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );

      await tester.pump(const Duration(seconds: 2));
    });

    testLocalizations('Speedtest - success okay', (tester, locale) async {
      final healthCheckSuccessOkayProvider = HealthCheckSuccessOkayProvider();
      await testHelper.pumpView(
        tester,
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessOkayProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );

      await tester.pump(const Duration(seconds: 2));
    });
  });

  testLocalizations('Speedtest - error', (tester, locale) async {
    final healthCheckErrorProvider = HealthCheckErrorProvider();
    await testHelper.pumpView(
      tester,
      overrides: [
        healthCheckProvider.overrideWith(() => healthCheckErrorProvider),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );

    await tester.pump(const Duration(seconds: 2));
  });
}

class MockHealthCheckSuccessProvider extends HealthCheckProvider with Mock {
  @override
  HealthCheckState build() =>
      HealthCheckState.fromJson(healthCheckStateSuccessUltra);

  @override
  Future runHealthCheck(Module module) async {
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(step: 'success');
  }
}

class HealthCheckSuccessUltraProvider extends MockHealthCheckSuccessProvider {
  @override
  HealthCheckState build() =>
      HealthCheckState.fromJson(healthCheckStateSuccessUltra);
}

class HealthCheckSuccessOptimalProvider extends MockHealthCheckSuccessProvider {
  @override
  HealthCheckState build() =>
      HealthCheckState.fromJson(healthCheckStateSuccessOptimal);
}

class HealthCheckSuccessGoodProvider extends MockHealthCheckSuccessProvider {
  @override
  HealthCheckState build() =>
      HealthCheckState.fromJson(healthCheckStateSuccessGood);
}

class HealthCheckSuccessOkayProvider extends MockHealthCheckSuccessProvider {
  @override
  HealthCheckState build() =>
      HealthCheckState.fromJson(healthCheckStateSuccessOkay);
}

class HealthCheckErrorProvider extends MockHealthCheckSuccessProvider {
  @override
  HealthCheckState build() => HealthCheckState.fromJson(healthCheckStateError);

  @override
  Future runHealthCheck(Module module) async {
    await Future.delayed(const Duration(seconds: 1));
    state = HealthCheckState.fromJson(healthCheckStateError);
  }
}