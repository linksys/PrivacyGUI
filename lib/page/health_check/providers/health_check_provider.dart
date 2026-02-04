import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_event.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/health_check/services/health_check_service.dart';

/// Defines the modules available for health checks.
enum Module {
  speedtest(value: "SpeedTest");

  const Module({required this.value});
  final String value;
}

/// Provider for managing the state of the health check feature.
final healthCheckProvider =
    NotifierProvider<HealthCheckProvider, HealthCheckState>(
        HealthCheckProvider.new);

/// Manages both the transient state of a running test and the persistent state
/// of historical results and supported modules for the health check feature.
class HealthCheckProvider extends Notifier<HealthCheckState> {
  StreamSubscription? _streamSubscription;
  late final Random _random;

  HealthCheckProvider({Random? random}) {
    _random = random ?? Random();
  }

  @override
  HealthCheckState build() {
    ref.onDispose(() {
      _streamSubscription?.cancel();
    });
    // Asynchronously load persistent data when the provider is first initialized.
    loadData();
    // Return the default initial state. The UI will update once data is loaded.
    return HealthCheckState.init();
  }

  /// Loads persistent data like historical tests, supported modules, and servers.
  Future<void> loadData() async {
    final service = ref.read(speedTestServiceProvider);
    final historical = await service.getInitialSpeedTestState();
    final latest = historical.isNotEmpty ? historical.first : null;

    final supportedModules = await service.getSupportedHealthCheckModules();

    // Only load servers if HealthCheckManager2 is supported
    final servers = serviceHelper.isSupportHealthCheckManager2()
        ? await service.getHealthCheckServers()
        : <HealthCheckServer>[];

    state = state.copyWith(
      historicalSpeedTests: historical,
      latestSpeedTest: () => latest,
      healthCheckModules: supportedModules,
      servers: servers,
    );
  }

  /// Loads the list of available speed test servers.
  /// Only loads if HealthCheckManager2 is supported.
  Future<void> loadServers() async {
    if (!serviceHelper.isSupportHealthCheckManager2()) {
      return;
    }
    final service = ref.read(speedTestServiceProvider);
    final servers = await service.getHealthCheckServers();
    state = state.copyWith(servers: servers);
  }

  /// Sets the selected server for speed tests.
  void setSelectedServer(HealthCheckServer? server) {
    state = state.copyWith(selectedServer: () => server);
  }

  /// Starts the health check process for a given [module].
  ///
  /// [serverId] - Optional server ID to use. If not provided, uses the selected server.
  Future<void> runHealthCheck(Module module, {int? serverId}) async {
    if (module != Module.speedtest) return;

    _streamSubscription?.cancel();

    // Reset only the transient state for the new test run,
    // preserving the persistent historical data.
    state = state.copyWith(
      status: HealthCheckStatus.running,
      step: HealthCheckStep.latency,
      meterValue: 0.0,
      result: () => null,
      errorCode: () => null,
    );

    final service = ref.read(speedTestServiceProvider);

    // Use the provided serverId, or fall back to the selected server's ID
    final targetServerId = serverId?.toString() ??
        (state.selectedServer?.serverID != null
            ? state.selectedServer!.serverID
            : null);

    _streamSubscription = service
        .runHealthCheck(module, targetServerId: targetServerId)
        .listen((event) {
      _handleStreamEvent(event);
    });
  }

  /// Handles events from the [SpeedTestService] stream.
  void _handleStreamEvent(SpeedTestStreamEvent event) {
    switch (event) {
      case SpeedTestProgress():
        _updateProgress(event.partialResult);
        break;
      case SpeedTestSuccess():
        _updateSuccess(event.finalResult);
        break;
      case SpeedTestFailure():
        _updateFailure(event.error);
        break;
    }
  }

  /// Updates the state to reflect the progress of the speed test.
  void _updateProgress(SpeedTestUIModel partialResult) {
    final step = _getCurrentStep(partialResult);
    double meterValue = state.meterValue;

    // Logic to control the animated meter's value based on the current step.
    if (step == HealthCheckStep.latency) {
      meterValue = 0.0;
    } else if (step == HealthCheckStep.downloadBandwidth &&
        state.step == HealthCheckStep.latency) {
      // Reset meter when moving from latency to download.
      meterValue = 0.0;
    } else if (step == HealthCheckStep.uploadBandwidth &&
        state.step == HealthCheckStep.downloadBandwidth) {
      // Set meter to final download speed before resetting for upload.
      meterValue = (partialResult.downloadBandwidthKbps ?? 0).toDouble();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (state.status == HealthCheckStatus.running) {
          state = state.copyWith(meterValue: 0.0);
        }
      });
    } else {
      // Add a random value to simulate a fluctuating meter during tests.
      final randomValue = (_random.nextDouble() * (15 - (-3)) + (-3)) * 1024;
      meterValue += randomValue;
    }

    state = state.copyWith(
      step: step,
      status: HealthCheckStatus.running,
      meterValue: meterValue < 0 ? 0 : meterValue,
      result: () => partialResult,
      errorCode: () => null,
    );
  }

  /// Updates the state to reflect the successful completion of the speed test.
  void _updateSuccess(SpeedTestUIModel finalResult) {
    // Prepend the new result to the historical list.
    final newHistory = [finalResult, ...state.historicalSpeedTests];
    // Ensure the history list doesn't grow indefinitely.
    if (newHistory.length > 5) {
      newHistory.removeLast();
    }

    state = state.copyWith(
      // Transient state
      status: HealthCheckStatus.complete,
      step: HealthCheckStep.success,
      result: () => finalResult,
      meterValue: (finalResult.uploadBandwidthKbps ?? 0).toDouble(),
      errorCode: () => null,
      // Persistent state
      latestSpeedTest: () => finalResult,
      historicalSpeedTests: newHistory,
    );

    // Force a refresh of other dashboard data if needed.
    ref.read(pollingProvider.notifier).forcePolling();
  }

  /// Updates the state to reflect a failure in the speed test.
  void _updateFailure(String error) {
    state = state.copyWith(
      status: HealthCheckStatus.complete,
      step: HealthCheckStep.error,
      errorCode: () => _mapStringToError(error),
    );
  }

  /// Determines the current step of the test based on the available data in [result].
  HealthCheckStep _getCurrentStep(SpeedTestUIModel result) {
    if (result.downloadSpeed != '--' && result.downloadSpeed != '0.0') {
      return HealthCheckStep.uploadBandwidth;
    } else if (result.latency != '--' && result.latency != '0') {
      return HealthCheckStep.downloadBandwidth;
    } else {
      return HealthCheckStep.latency;
    }
  }

  /// Maps an error string from the JNAP response to a [SpeedTestError] enum.
  SpeedTestError? _mapStringToError(String? errorCode) {
    return switch (errorCode) {
      'Success' => null,
      'Unavailable' => null,
      'SpeedTestConfigurationError' => SpeedTestError.configuration,
      'SpeedTestLicenseError' => SpeedTestError.license,
      'SpeedTestExecutionError' => SpeedTestError.execution,
      'AbortedByUser' => SpeedTestError.aborted,
      'DBError' => SpeedTestError.dbError,
      'TimeoutException' => SpeedTestError.timeout,
      'Empty resultID' => SpeedTestError.emptyResultId,
      'NoSpeedTestResultInResponse' => SpeedTestError.unknown,
      _ => SpeedTestError.unknown,
    };
  }

  /// Stops the health check process and resets the transient state.
  Future<void> stopHealthCheck() async {
    await ref.read(speedTestServiceProvider).stopHealthCheck();
    _streamSubscription?.cancel();
    state = state.copyWith(
      status: HealthCheckStatus.idle,
      step: HealthCheckStep.latency,
      meterValue: 0.0,
      result: () => null,
      errorCode: () => null,
    );
  }
}
