import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';

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

  void resetState() {
    state = HealthCheckState.init().copyWith(
      servers: state.servers,
      // selectedServer: null, // Clear selection to force user to choose
    );
  }

  Future<void> runHealthCheck(Module module, {int? serverId}) async {
    if (module == Module.speedtest) {
      state = HealthCheckState.init().copyWith(
        servers: state.servers, // Preserve servers
        selectedServer: state.selectedServer,
      );
      final repo = ref.read(routerRepositoryProvider);

      final targetServerId = serverId ??
          (state.selectedServer?.serverID != null
              ? int.tryParse(state.selectedServer!.serverID)
              : null);

      final result = await repo.send(
        JNAPAction.runHealthCheck,
        data: {
          "runHealthCheckModule": module.value,
          "targetServerID": '$targetServerId',
        }..removeWhere((key, value) => value == null),
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
              retryDelayInMilliSec: 100,
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
                  final speedtestTempResult = state.result
                      .firstWhereOrNull((e) => e.timestamp == state.timestamp)
                      ?.speedTestResult;

                  if (speedtestTempResult?.exitCode != 'Success' &&
                      speedtestTempResult?.exitCode != 'Unavailable') {
                    state = state.copyWith(
                      step: 'error',
                      status: 'COMPLETE',
                      error: JNAPError(
                          result:
                              speedtestTempResult?.exitCode ?? 'Unknown Error'),
                    );
                    return;
                  }

                  state = state.copyWith(
                      step: 'success',
                      status: 'COMPLETE',
                      meterValue:
                          speedtestTempResult?.uploadBandwidth?.toDouble() ??
                              0.0);
                  ref.read(pollingProvider.notifier).forcePolling();
                } else if (result is JNAPError) {
                  state = state.copyWith(step: 'error', status: 'COMPLETE');
                }
              })
          .listen((result) {
        logger.d('[SpeedTest] Get Health Check Result - $result');
        if (result is JNAPError) {
          state = state.copyWith(error: result);
          return;
        }
        if (_getErrorCode(result)) {
          state = state.copyWith(
            step: 'error',
            status: 'COMPLETE',
            error: JNAPError(
                result: (result as JNAPSuccess)
                        .output['speedTestResult']?['exitCode']
                        ?.toString() ??
                    'Unknown Error'),
          );
          return;
        }
        final step = _getCurrentStep(result);
        if (step.isNotEmpty) {
          final randomValue = _randomDouble(-3, 15) * 1000;
          final speedtestTempResult = SpeedTestResult.fromJson(
              (result as JNAPSuccess).output['speedTestResult']);
          var meterValue = 0.0;
          if (step == 'latency') {
            // Enter to collect latency
            meterValue = 0.0;
          } else if (step == 'downloadBandwidth' && state.step == 'latency') {
            // Enter to collect download bandwidth
            meterValue = 0.0;
          } else if (step == 'uploadBandwidth' &&
              state.step == 'downloadBandwidth') {
            // Enter to collect upload bandwidth, show download bandwidth and reset to 0 after 1 second
            meterValue =
                speedtestTempResult.downloadBandwidth?.toDouble() ?? 0.0;
            Future.delayed(const Duration(milliseconds: 1000), () {
              state = state.copyWith(meterValue: 0.0);
            });
          } else {
            meterValue = state.meterValue + randomValue;
          }
          state = state.copyWith(
            step: step,
            status: 'RUNNING',
            meterValue: meterValue < 0 ? 0 : meterValue,
            randomValue: randomValue,
          );
          Future.delayed(const Duration(milliseconds: 400), () {
            state = state.copyWith(
              result: [
                HealthCheckResult(
                  resultID: speedtestTempResult.resultID,
                  timestamp: '',
                  healthCheckModulesRequested: const ['SpeedTest'],
                  speedTestResult: speedtestTempResult,
                ),
              ],
            );
          });
        }
      });
    }
  }

  // void updateMeterValue(double meterValue) {
  //   state = state.copyWith(
  //     meterValue: meterValue,
  //   );
  // }

  // void updateRandomValue(double randomValue) {
  //   state = state.copyWith(
  //     randomValue: randomValue,
  //   );
  // }

  double _randomDouble(double min, double max) {
    return (Random().nextDouble() * (max - min) + min);
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

  Future<List<HealthCheckServer>> updateServers() async {
    final repo = ref.read(routerRepositoryProvider);
    try {
      // Fetch from repository (which uses polling cache)
      final result = await repo.send(
        JNAPAction.getCloseHealthCheckServers,
        auth: true,
        fetchRemote: false, // Rely on polling/cache
        cacheLevel: CacheLevel.localCached,
      );

      // ignore: unnecessary_type_check
      if (result is JNAPSuccess) {
        final List<dynamic> serverList = result.output['healthCheckServers'];
        final servers = serverList
            .map((e) => HealthCheckServer.fromJson(e as Map<String, dynamic>))
            .toList();

        // Update state with cached servers
        state = state.copyWith(servers: servers);
        return servers;
      }
    } catch (e) {
      logger.d('Failed to update health check servers from cache: $e');
    }
    // If fail or empty, ensure state reflects that (or keep old? keeping empty for now)
    state = state.copyWith(servers: []);
    return [];
  }

  void setSelectedServer(HealthCheckServer? server) {
    state = state.copyWith(selectedServer: server);
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
      if (_getErrorCode(result)) {
        return 'error';
      }
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
