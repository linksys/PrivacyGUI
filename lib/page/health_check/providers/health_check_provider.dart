import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/health_check/providers/health_check_state.dart';

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
      final repo = ref.read(routerRepositoryProvider);
      final result = await repo.send(JNAPAction.runHealthCheck,
          data: {"runHealthCheckModule": module.value},
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache);
      if (result.output['resultID'] == null) {
        // error handling
        return;
      }
      _streamSubscription?.cancel();
      _streamSubscription = repo
          .scheduledCommand(
              action: JNAPAction.getHealthCheckStatus,
              firstDelayInMilliSec: 0,
              retryDelayInMilliSec: 1,
              maxRetry: -1,
              condition: (result) {
                return result is JNAPSuccess &&
                        result.output['speedTestResult']['exitCode'] !=
                            'Unavailable' ||
                    result is JNAPError;
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
          state = state.copyWith(result: [
            HealthCheckResult(
                resultID: 0,
                timestamp: '',
                healthCheckModulesRequested: const ['SpeedTest'],
                speedTestResult: speedtestTempResult)
          ], step: step);
        }
        // getHealthCheckResults(module, 1);
      });
    }
  }

  Future<void> getHealthCheckResults(
      Module module, int numberOfMostRecentResults) async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.getHealthCheckResults,
        data: {
          "includeModuleResults": true,
          "healthCheckModule": module.value,
          "lastNumberOfResults": numberOfMostRecentResults
        },
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache);
    final healthCheckResults = List.from(result.output['healthCheckResults'])
        .map((e) => HealthCheckResult.fromJson(e))
        .toList();
    _handleHealthCheckResults(healthCheckResults);
  }

  _handleHealthCheckResults(List<HealthCheckResult> healthCheckResults) {
    state = state.copyWith(result: healthCheckResults);
  }

  Future<void> stopHealthCheck() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.stopHealthCheck,
        fetchRemote: true, cacheLevel: CacheLevel.noCache);
  }

  Future<JNAPResult> _getHealthCheckStatus() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.getHealthCheckStatus,
        fetchRemote: true, cacheLevel: CacheLevel.noCache);
    return result;
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
      if (result.output['healthCheckModuleCurrentlyRunning'] == 'SpeedTest' &&
          speedTestResult.downloadBandwidth != null &&
          speedTestResult.downloadBandwidth != 0) {
        return 'uploadBandwidth';
      } else if (result.output['healthCheckModuleCurrentlyRunning'] ==
              'SpeedTest' &&
          speedTestResult.latency != null &&
          speedTestResult.latency != 0) {
        return 'downloadBandwidth';
      } else if (result.output['healthCheckModuleCurrentlyRunning'] ==
          'SpeedTest') {
        return 'latency';
      } else {
        return '';
      }
    } else {
      return '';
    }
  }
}
