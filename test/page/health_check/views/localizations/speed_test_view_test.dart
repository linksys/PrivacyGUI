import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/dashboard_home_notifier_mocks.dart';
import '../../../../test_data/dashboard_home_test_state.dart';
import '../../../../test_data/health_check_state_data.dart';
import '../../../../mocks/health_check_provider_mocks.dart';

Future<void> main() async {
  late HealthCheckProvider mockHealthCheckProvider;
  late DashboardHomeNotifier mockDashboardHomeNotifier;

  mockDependencyRegister();
  setUp(() {
    mockHealthCheckProvider = MockHealthCheckProvider();
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
  });

  testLocalizations('Speedtest - init', (tester, locale) async {
    when(mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckInitState));

    final widget = testableSingleRoute(
      overrides: [
        healthCheckProvider.overrideWith(() => mockHealthCheckProvider),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('Speedtest - init with Ookla logo', (tester, locale) async {
    when(mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckInitState));
    when(mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
            .copyWith(healthCheckModule: () => 'Ookla'));

    final widget = testableSingleRoute(
      overrides: [
        healthCheckProvider.overrideWith(() => mockHealthCheckProvider),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );
    await tester.pumpWidget(widget);

    await tester.runAsync(() async {
      final context = tester.element(find.byType(SpeedTestView));
      await precacheImage(
          CustomTheme.of(context).images.speedtestPowered, context);
      await tester.pumpAndSettle();
    });
  });

  testLocalizations('Speedtest - ping init', (tester, locale) async {
    when(mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStatePingInit));
    when(mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 5));
    });

    final widget = testableSingleRoute(
      overrides: [
        healthCheckProvider.overrideWith(() => mockHealthCheckProvider),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Speedtest - ping finished', (tester, locale) async {
    when(mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStatePing));
    when(mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 5));
    });

    final widget = testableSingleRoute(
      overrides: [
        healthCheckProvider.overrideWith(() => mockHealthCheckProvider),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );
    await tester.pumpWidget(widget);

    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Speedtest - download', (tester, locale) async {
    when(mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStateDownload));
    when(mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    final widget = testableSingleRoute(
      overrides: [
        healthCheckProvider.overrideWith(() => mockHealthCheckProvider),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );
    await tester.pumpWidget(widget);

    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Speedtest - upload', (tester, locale) async {
    when(mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStateUpload));
    when(mockHealthCheckProvider.runHealthCheck(Module.speedtest))
        .thenAnswer((_) async {});

    final widget = testableSingleRoute(
      overrides: [
        healthCheckProvider.overrideWith(() => mockHealthCheckProvider),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );
    await tester.pumpWidget(widget);

    await tester.pump(const Duration(seconds: 2));
  });

  group('Speedtest - success', () {
    testLocalizations('Speedtest - success ultra', (tester, locale) async {
      final healthCheckSuccessUltraProvider = HealthCheckSuccessUltraProvider();
      final widget = testableSingleRoute(
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessUltraProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );
      await tester.pumpWidget(widget);

      await tester.pump(const Duration(seconds: 2));
    });

    testLocalizations('Speedtest - success optimal', (tester, locale) async {
      final healthCheckSuccessOptimalProvider =
          HealthCheckSuccessOptimalProvider();
      final widget = testableSingleRoute(
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessOptimalProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );
      await tester.pumpWidget(widget);

      await tester.pump(const Duration(seconds: 2));
    });

    testLocalizations('Speedtest - success good', (tester, locale) async {
      final healthCheckSuccessGoodProvider = HealthCheckSuccessGoodProvider();
      final widget = testableSingleRoute(
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessGoodProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );
      await tester.pumpWidget(widget);

      await tester.pump(const Duration(seconds: 2));
    });

    testLocalizations('Speedtest - success okay', (tester, locale) async {
      final healthCheckSuccessOkayProvider = HealthCheckSuccessOkayProvider();
      final widget = testableSingleRoute(
        overrides: [
          healthCheckProvider
              .overrideWith(() => healthCheckSuccessOkayProvider),
        ],
        locale: locale,
        child: const SpeedTestView(),
      );
      await tester.pumpWidget(widget);

      await tester.pump(const Duration(seconds: 2));
    });
  });

  testLocalizations('Speedtest - error', (tester, locale) async {
    final healthCheckErrorProvider = HealthCheckErrorProvider();
    final widget = testableSingleRoute(
      overrides: [
        healthCheckProvider.overrideWith(() => healthCheckErrorProvider),
      ],
      locale: locale,
      child: const SpeedTestView(),
    );
    await tester.pumpWidget(widget);

    await tester.pump(const Duration(seconds: 2));
  });
}

class MockHealthCheckSuccessProvider extends HealthCheckProvider with Mock {
  @override
  HealthCheckState build() =>
      HealthCheckState.fromJson(healthCheckStateSuccessUltra);

  @override
  Future runHealthCheck(Module module, {int? serverId}) async {
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
  Future runHealthCheck(Module module, {int? serverId}) async {
    await Future.delayed(const Duration(seconds: 1));
    state = HealthCheckState.fromJson(healthCheckStateError);
  }
}
