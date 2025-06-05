import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';

import '../../../core/jnap/actions/better_action.dart';
import '../../../core/jnap/models/health_check_result.dart';
import '../../../core/jnap/router_repository.dart';

const int delayHealthCheckMonitor = 3;

enum Module {
  speedtest(value: "SpeedTest");

  const Module({required this.value});
  final String value;
}

final healthCheckProvider =
    NotifierProvider<HealthCheckProvider, HealthCheckState>(
        () => HealthCheckProvider());

class HealthCheckProvider extends Notifier<HealthCheckState> {
  StreamSubscription? _streamSubscription;

  @override
  HealthCheckState build() => HealthCheckState.init();

  Future<void> runHealthCheck(Module module) async {
    if (module == Module.speedtest) {
      // Reset state
      state = HealthCheckState.init();
      final repo = ref.read(routerRepositoryProvider);
      final result = await repo.send(
        JNAPAction.runHealthCheck,
        data: {"runHealthCheckModule": module.value},
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
      if (result.output['resultID'] == null) {
        state = state.copyWith(
          step: 'error',
          error: const JNAPError(result: 'Empty resultID'),
        );
        return;
      }
      _streamSubscription?.cancel();
      _streamSubscription = repo
          .scheduledCommand(
              action: JNAPAction.getHealthCheckStatus,
              auth: true,
              firstDelayInMilliSec: 0,
              retryDelayInMilliSec: 200,
              maxRetry: -1,
              condition: (result) {
                return result is JNAPSuccess &&
                        result.output['speedTestResult']['exitCode'] !=
                            'Unavailable' ||
                    result is JNAPError;
              },
              onCompleted: (_) async {
                final resultId = state.result.firstOrNull?.resultID;
                // Get health check result with resultId
                final result = await getHealthCheckResults(module, 1, resultId);
                // Set state
                if (result is JNAPSuccess) {
                  state = state.copyWith(step: 'success');
                  ref.read(pollingProvider.notifier).forcePolling();
                } else if (result is JNAPError) {
                  state = state.copyWith(step: 'error');
                }
              })
          .listen((result) {
        logger.d('[SpeedTest] Get Health Check Result - $result');
        if (result is JNAPError) {
          state = state.copyWith(error: result);
          return;
        }
        final step = _getCurrentStep(result);
        if (step.isNotEmpty) {
          final speedtestTempResult = SpeedTestResult.fromJson(
              (result as JNAPSuccess).output['speedTestResult']);
          state = state.copyWith(
            result: [
              HealthCheckResult(
                resultID: speedtestTempResult.resultID,
                timestamp: '',
                healthCheckModulesRequested: const ['SpeedTest'],
                speedTestResult: speedtestTempResult,
              ),
            ],
            step: step,
          );
        }
      });
    }
  }

  Future<JNAPResult> getHealthCheckResults(
    Module module,
    int numberOfMostRecentResults,
    int? resultId,
  ) async {
    final repo = ref.read(routerRepositoryProvider);
    late JNAPResult result;
    try {
      result = await repo.send(
        JNAPAction.getHealthCheckResults,
        data: {
          "includeModuleResults": true,
          "healthCheckModule": module.value,
          "lastNumberOfResults": numberOfMostRecentResults,
          'resultIDs': resultId != null ? [resultId] : null,
        }..removeWhere((key, value) => value == null),
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
    } on JNAPError catch (e) {
      // JNAP error
      result = e;
    } on TimeoutException catch (e) {
      // Timeout exception
      result = JNAPError(result: e.runtimeType.toString());
    } catch (e) {
      // Unknown Exception
      result = JNAPError(
        result: 'UNKNOWN',
        error: e.runtimeType.toString(),
      );
    }

    if (result is JNAPSuccess) {
      final healthCheckResults = List.from(result.output['healthCheckResults'])
          .map((e) => HealthCheckResult.fromJson(e))
          .toList();
      _handleHealthCheckResults(healthCheckResults);
    } else if (result is JNAPError) {
      state = state.copyWith(error: result);
    }
    return result;
  }

  _handleHealthCheckResults(List<HealthCheckResult> healthCheckResults) {
    final timestamp = healthCheckResults.firstOrNull?.timestamp;
    state = state.copyWith(result: healthCheckResults, timestamp: timestamp);
  }

  Future<void> stopHealthCheck() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      JNAPAction.stopHealthCheck,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );
  }

  bool _getErrorCode(JNAPResult result) {
    if (result.result != "OK") {
      return true;
    } else if (result is JNAPSuccess &&
        result.output['speedTestResult'] != null &&
        result.output['speedTestResult']['exitCode'] != 'Success' &&
        result.output['speedTestResult']['exitCode'] != 'Unavailable') {
      return true;
    } else {
      return false;
    }
  }

  bool _isHealthCheckDone(JNAPResult result) {
    if (result is JNAPError) {
      return true;
    } else {
      return !(result as JNAPSuccess)
              .output['healthCheckModuleCurrentlyRunning'] ||
          _getErrorCode(result);
    }
  }

  String _getCurrentStep(JNAPResult result) {
    if (result is JNAPSuccess) {
      final speedTestResult =
          SpeedTestResult.fromJson(result.output['speedTestResult']);
      if (result.output['healthCheckModuleCurrentlyRunning'] == 'SpeedTest') {
        // SpeedTest
        final latency = speedTestResult.latency;
        final downloadBandwidth = speedTestResult.downloadBandwidth;
        if (downloadBandwidth != null && downloadBandwidth != 0) {
          return 'uploadBandwidth';
        } else if (latency != null && latency != 0) {
          return 'downloadBandwidth';
        } else {
          return 'latency';
        }
      } else {
        // TODO: Others module
        return '';
      }
    } else {
      return '';
    }
  }
}
