import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_event.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/health_check/services/health_check_service.dart';

import '../../../mocks/health_check_service_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../mocks/random_mocks.dart';

void main() {
  late MockSpeedTestService mockSpeedTestService;
  late MockPollingNotifier mockPollingNotifier;
  late MockRandom mockRandom;
  late ProviderContainer container;

  setUp(() {
    mockSpeedTestService = MockSpeedTestService();
    mockPollingNotifier = MockPollingNotifier();
    mockRandom = MockRandom();

    container = ProviderContainer(
      overrides: [
        speedTestServiceProvider.overrideWithValue(mockSpeedTestService),
        pollingProvider.overrideWith(() => mockPollingNotifier),
        healthCheckProvider.overrideWith(
          () => HealthCheckProvider(random: mockRandom),
        ),
      ],
    );

    // Mock the forcePolling method to avoid errors
    when(mockPollingNotifier.forcePolling()).thenAnswer((_) async {});
    // Mock random to return a predictable value (e.g., 0.5, which results in a positive randomValue)
    when(mockRandom.nextDouble()).thenReturn(0.5);
  });

  tearDown(() {
    container.dispose();
  });

  group('HealthCheckProvider', () {
    test('build() should initialize with default state and load data',
        () async {
      // Arrange
      final initialHistorical = [
        const SpeedTestUIModel(
          downloadSpeed: '100',
          downloadUnit: 'Mbps',
          uploadSpeed: '50',
          uploadUnit: 'Mbps',
          latency: '10',
          timestamp: 'now',
          serverId: '1',
        )
      ];
      const supportedModules = ['SpeedTest'];

      when(mockSpeedTestService.getInitialSpeedTestState())
          .thenAnswer((_) async => initialHistorical);
      when(mockSpeedTestService.getSupportedHealthCheckModules())
          .thenAnswer((_) async => supportedModules);

      // Act
      container.read(healthCheckProvider.notifier);
      // Initial state from build() before loadData completes
      expect(container.read(healthCheckProvider), HealthCheckState.init());

      // Allow loadData to complete by waiting for the next frame.
      await Future.delayed(Duration.zero);

      // Assert after loadData completes
      final state = container.read(healthCheckProvider);
      expect(state.historicalSpeedTests, initialHistorical);
      expect(state.latestSpeedTest, initialHistorical.first);
      expect(state.healthCheckModules, supportedModules);
    });

    group('runHealthCheck', () {
      late StreamController<SpeedTestStreamEvent> streamController;

      setUp(() {
        streamController = StreamController<SpeedTestStreamEvent>.broadcast();
        when(mockSpeedTestService.runHealthCheck(any))
            .thenAnswer((_) => streamController.stream);
      });

      tearDown(() {
        streamController.close();
      });

      test('should reset transient state and listen to service stream',
          () async {
        // Arrange
        final provider = container.read(healthCheckProvider.notifier);
        // Simulate some previous state
        provider.state = provider.state.copyWith(
          status: HealthCheckStatus.complete,
          step: HealthCheckStep.success,
          result: () => SpeedTestUIModel.empty(),
          errorCode: () => SpeedTestError.unknown,
        );

        // Act
        await provider.runHealthCheck(Module.speedtest);
        await Future.delayed(
            Duration.zero); // Allow state update to be processed

        // Assert
        verify(mockSpeedTestService.runHealthCheck(Module.speedtest)).called(1);
        final state = container.read(healthCheckProvider);
        expect(state.status, HealthCheckStatus.running);
        expect(state.step, HealthCheckStep.latency);
        expect(state.result, isNull);
        expect(state.errorCode, isNull);
      });

      test('should update state on SpeedTestProgress event (Latency)',
          () async {
        // Arrange
        final provider = container.read(healthCheckProvider.notifier);
        await provider.runHealthCheck(Module.speedtest);

        final partialResult = SpeedTestUIModel.empty();

        // Act
        streamController.add(SpeedTestProgress(partialResult));
        await Future.delayed(Duration.zero); // Allow state update to complete

        // Assert
        final state = container.read(healthCheckProvider);
        expect(state.status, HealthCheckStatus.running);
        expect(state.result, partialResult);
        expect(state.step, HealthCheckStep.latency);
        expect(state.meterValue, 0.0);
      });

      test('should update state on SpeedTestProgress event (Download)',
          () async {
        // Arrange
        final provider = container.read(healthCheckProvider.notifier);
        await provider.runHealthCheck(Module.speedtest);
        // Simulate starting from Latency step
        provider.state = provider.state.copyWith(step: HealthCheckStep.latency);

        final partialResult = SpeedTestUIModel(
          downloadSpeed: '--',
          downloadUnit: 'Mbps',
          uploadSpeed: '--',
          uploadUnit: 'Mbps',
          latency: '20',
          timestamp: 'now',
          serverId: '1',
          downloadBandwidthKbps: 0,
        );

        // Act
        streamController.add(SpeedTestProgress(partialResult));
        await Future.delayed(Duration.zero); // Allow state update to complete

        // Assert
        final state = container.read(healthCheckProvider);
        expect(state.status, HealthCheckStatus.running);
        expect(state.result, partialResult);
        expect(state.step, HealthCheckStep.downloadBandwidth);
        expect(state.meterValue,
            0.0); // Should reset to 0.0 from latency to download
      });

      test(
          'should update state on SpeedTestProgress event (Upload) with meter value transition',
          () {
        fakeAsync((async) {
          // Arrange
          final provider = container.read(healthCheckProvider.notifier);
          provider.runHealthCheck(Module.speedtest);
          async.flushMicrotasks();
          // Simulate starting from Download step
          provider.state =
              provider.state.copyWith(step: HealthCheckStep.downloadBandwidth);

          final partialResult = SpeedTestUIModel(
            downloadSpeed: '100',
            downloadUnit: 'Mbps',
            uploadSpeed: '5',
            uploadUnit: 'Mbps',
            latency: '20',
            timestamp: 'now',
            serverId: '1',
            downloadBandwidthKbps: 100000,
            uploadBandwidthKbps: 5000,
          );

          // Act
          streamController.add(SpeedTestProgress(partialResult));
          async.flushMicrotasks();

          // Assert - meterValue should be set to final download speed first
          var state = container.read(healthCheckProvider);
          expect(state.status, HealthCheckStatus.running);
          expect(state.result, partialResult);
          expect(state.step, HealthCheckStep.uploadBandwidth);
          expect(state.meterValue, 100000.0);

          // Advance time to trigger Future.delayed
          async.elapse(const Duration(milliseconds: 1000));
          async.flushMicrotasks();

          // Assert - meterValue should reset to 0.0 after delay
          state = container.read(healthCheckProvider);
          expect(state.meterValue, 0.0);
        });
      });

      test(
          'should update state on SpeedTestProgress event (Random meter value)',
          () async {
        // Arrange
        final provider = container.read(healthCheckProvider.notifier);
        await provider.runHealthCheck(Module.speedtest);
        // Simulate starting from Upload step
        provider.state =
            provider.state.copyWith(step: HealthCheckStep.uploadBandwidth);

        final partialResult = SpeedTestUIModel(
          downloadSpeed: '100',
          downloadUnit: 'Mbps',
          uploadSpeed: '50',
          uploadUnit: 'Mbps',
          latency: '20',
          timestamp: 'now',
          serverId: '1',
          downloadBandwidthKbps: 100000,
          uploadBandwidthKbps: 50000,
        );

        // Act
        streamController.add(SpeedTestProgress(partialResult));
        await Future.delayed(Duration.zero); // Allow state update to complete

        // Assert
        final state = container.read(healthCheckProvider);
        expect(state.status, HealthCheckStatus.running);
        expect(state.result, partialResult);
        expect(state.step, HealthCheckStep.uploadBandwidth);
        // Meter value should have changed from 0.0 (initial) to a predictable non-zero value
        final expectedRandomValue = (0.5 * (15 - (-3)) + (-3)) * 1024;
        expect(state.meterValue, expectedRandomValue);
      });

      test('should update state on SpeedTestSuccess event', () async {
        // Arrange
        final provider = container.read(healthCheckProvider.notifier);
        await provider.runHealthCheck(Module.speedtest);

        final finalResult = SpeedTestUIModel(
          downloadSpeed: '100',
          downloadUnit: 'Mbps',
          uploadSpeed: '50',
          uploadUnit: 'Mbps',
          latency: '10',
          timestamp: 'now',
          serverId: '1',
          downloadBandwidthKbps: 100000,
          uploadBandwidthKbps: 50000,
        );

        // Act
        streamController.add(SpeedTestSuccess(finalResult));
        await Future.delayed(Duration.zero); // Allow state update to complete

        // Assert
        final state = container.read(healthCheckProvider);
        expect(state.status, HealthCheckStatus.complete);
        expect(state.step, HealthCheckStep.success);
        expect(state.result, finalResult);
        expect(state.latestSpeedTest, finalResult);
        expect(state.historicalSpeedTests, contains(finalResult));
        verify(mockPollingNotifier.forcePolling()).called(1);
      });

      test('should update state on SpeedTestFailure event', () async {
        // Arrange
        final provider = container.read(healthCheckProvider.notifier);
        await provider.runHealthCheck(Module.speedtest);

        // Act
        streamController.add(SpeedTestFailure('SpeedTestExecutionError'));
        await Future.delayed(Duration.zero); // Allow state update to complete

        // Assert
        final state = container.read(healthCheckProvider);
        expect(state.status, HealthCheckStatus.complete);
        expect(state.step, HealthCheckStep.error);
        expect(state.errorCode, SpeedTestError.execution);
      });

      test('should map various error strings to SpeedTestError enum', () async {
        final provider = container.read(healthCheckProvider.notifier);
        await provider.runHealthCheck(Module.speedtest);

        // Test each error code mapping
        streamController.add(SpeedTestFailure('SpeedTestConfigurationError'));
        await Future.delayed(Duration.zero);
        expect(container.read(healthCheckProvider).errorCode,
            SpeedTestError.configuration);

        streamController.add(SpeedTestFailure('SpeedTestLicenseError'));
        await Future.delayed(Duration.zero);
        expect(container.read(healthCheckProvider).errorCode,
            SpeedTestError.license);

        streamController.add(SpeedTestFailure('AbortedByUser'));
        await Future.delayed(Duration.zero);
        expect(container.read(healthCheckProvider).errorCode,
            SpeedTestError.aborted);

        streamController.add(SpeedTestFailure('DBError'));
        await Future.delayed(Duration.zero);
        expect(container.read(healthCheckProvider).errorCode,
            SpeedTestError.dbError);

        streamController.add(SpeedTestFailure('TimeoutException'));
        await Future.delayed(Duration.zero);
        expect(container.read(healthCheckProvider).errorCode,
            SpeedTestError.timeout);

        streamController.add(SpeedTestFailure('Empty resultID'));
        await Future.delayed(Duration.zero);
        expect(container.read(healthCheckProvider).errorCode,
            SpeedTestError.emptyResultId);

        streamController.add(SpeedTestFailure('UnknownError')); // Unknown
        await Future.delayed(Duration.zero);
        expect(container.read(healthCheckProvider).errorCode,
            SpeedTestError.unknown);
      });
    });

    group('stopHealthCheck', () {
      test('should call service.stopHealthCheck and reset state', () async {
        // Arrange
        final provider = container.read(healthCheckProvider.notifier);
        // Simulate a running test
        provider.state = provider.state.copyWith(
          status: HealthCheckStatus.running,
          step: HealthCheckStep.downloadBandwidth,
          result: () => SpeedTestUIModel.empty(),
        );
        when(mockSpeedTestService.stopHealthCheck())
            .thenAnswer((_) async => Future.value());

        // Act
        await provider.stopHealthCheck();
        await Future.delayed(Duration.zero);

        // Assert
        verify(mockSpeedTestService.stopHealthCheck()).called(1);
        final state = container.read(healthCheckProvider);
        expect(state.status, HealthCheckStatus.idle);
        expect(state.step, HealthCheckStep.latency);
        expect(state.result, isNull);
        expect(state.errorCode, isNull);
      });
    });
  });
}
