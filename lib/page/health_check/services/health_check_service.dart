import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_event.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/utils.dart';

// --- Service ---

/// Provider for the [SpeedTestService].
final speedTestServiceProvider = Provider<SpeedTestService>((ref) {
  return SpeedTestService(ref.watch(routerRepositoryProvider));
});

/// Service responsible for handling the speed test logic by communicating with the router's JNAP API.
class SpeedTestService {
  final RouterRepository _repo;
  SpeedTestService(this._repo);

  /// Fetches and processes the initial state for the speed test feature,
  /// including historical test results.
  ///
  /// Returns a list of historical tests, sorted with the most recent first.
  Future<List<SpeedTestUIModel>> getInitialSpeedTestState(
      {int count = 5}) async {
    final resultsResponse =
        await getHealthCheckResults(Module.speedtest, count, null, false);

    if (resultsResponse is JNAPSuccess) {
      final healthCheckResults =
          List.from(resultsResponse.output['healthCheckResults'] ?? [])
              .map((e) => HealthCheckResult.fromJson(e))
              .toList();

      if (healthCheckResults.isNotEmpty) {
        final historicalTests = healthCheckResults
            .where((e) => e.speedTestResult?.exitCode == 'Success')
            .map((res) {
          return mapResultToUIModel(res.speedTestResult,
              timestamp: res.timestamp);
        }).toList();
        return historicalTests;
      }
    }
    // Return empty list in case of failure or no results.
    return [];
  }

  /// Orchestrates the health check process, yielding events for progress, success, or failure.
  ///
  /// This method follows a three-step process:
  /// 1. Initiates the speed test on the router.
  /// 2. Polls for progress updates.
  /// 3. Fetches the final result upon completion.
  ///
  /// [targetServerId] - Optional server ID to use for the speed test.
  Stream<SpeedTestStreamEvent> runHealthCheck(Module module,
      {String? targetServerId}) async* {
    if (module != Module.speedtest) return;

    try {
      // 1. Initiate the health check
      await _initiateHealthCheck(module, targetServerId: targetServerId);

      // 2. Poll for progress and yield events
      int? resultId;
      final progressStream = _pollHealthCheckProgress();

      await for (final progressResult in progressStream) {
        // If the health check fails, yield the failure event and return.
        if (progressResult.isErrorExitCode()) {
          yield SpeedTestFailure(progressResult.exitCode);
          return;
        }
        resultId = progressResult.resultID;
        final uiModel = mapResultToUIModel(progressResult, isProgress: true);
        yield SpeedTestProgress(uiModel);
      }

      // 3. Fetch and yield the final result
      if (resultId != null) {
        final finalEvent = await _fetchFinalResult(module, resultId);
        yield finalEvent;
      } else {
        yield SpeedTestFailure(
            'Could not obtain resultID from progress stream.');
      }
    } catch (e) {
      logger.e('[SpeedTest] Failure in runHealthCheck: $e');
      yield SpeedTestFailure(e is JNAPError ? e.result : e.toString());
    }
  }

  /// 1. Sends the initial request to start the health check on the router.
  /// Throws a [JNAPError] or other exception on failure.
  ///
  /// [targetServerId] - Optional server ID to use for the speed test.
  Future<void> _initiateHealthCheck(Module module,
      {String? targetServerId}) async {
    final result = await _repo.send(
      JNAPAction.runHealthCheck,
      data: {
        "runHealthCheckModule": module.value,
        "targetServerID": targetServerId,
      }..removeWhere((key, value) => value == null),
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );

    if (result is JNAPError) throw result;
    if (result.output['resultID'] == null) {
      throw Exception('Empty resultID from runHealthCheck');
    }
  }

  /// 2. Polls the router for health check status and returns a stream of progress results.
  /// The stream continues until the test is no longer in the 'Unavailable' state.
  /// Throws an exception if a [JNAPError] occurs during polling.
  Stream<SpeedTestResult> _pollHealthCheckProgress() {
    final stream = _repo.scheduledCommand(
      action: JNAPAction.getHealthCheckStatus,
      auth: true,
      firstDelayInMilliSec: 0,
      retryDelayInMilliSec: 100,
      maxRetry: -1, // Poll indefinitely until condition is met
      condition: (result) =>
          (result is JNAPSuccess &&
              result.output['speedTestResult']?['exitCode'] != 'Unavailable') ||
          result is JNAPError,
    );

    return stream.map((result) {
      logger.d('[SpeedTest] Polling result: $result');
      if (result is JNAPError) throw result;

      final jnapSuccess = result as JNAPSuccess;
      return SpeedTestResult.fromJson(jnapSuccess.output['speedTestResult']);
    });
  }

  /// 3. Fetches the final health check result from the router using the [resultId].
  Future<SpeedTestStreamEvent> _fetchFinalResult(
      Module module, int resultId) async {
    final finalResult = await getHealthCheckResults(module, 1, resultId, true);

    if (finalResult is JNAPSuccess) {
      final healthCheckResults =
          List.from(finalResult.output['healthCheckResults'])
              .map((e) => HealthCheckResult.fromJson(e))
              .toList();

      if (healthCheckResults.isNotEmpty) {
        final healthCheckResult = healthCheckResults.first;
        final speedTestResult = healthCheckResult.speedTestResult;
        final uiModel = mapResultToUIModel(speedTestResult,
            timestamp: healthCheckResult.timestamp);
        return SpeedTestSuccess(uiModel);
      } else {
        return SpeedTestFailure('NoResultsFound');
      }
    } else if (finalResult is JNAPError) {
      return SpeedTestFailure(finalResult.result);
    }
    // This case should ideally not be reached.
    return SpeedTestFailure('UnknownErrorFetchingFinalResult');
  }

  /// Maps a [SpeedTestResult] from the API to a [SpeedTestUIModel] for the UI.
  /// Can be tested in isolation.
  SpeedTestUIModel mapResultToUIModel(
    SpeedTestResult? speedTestResult, {
    String? timestamp,
    bool isProgress = false,
  }) {
    if (speedTestResult == null) {
      return SpeedTestUIModel.empty();
    }
    final download = NetworkUtils.formatBitsWithUnit(
      (speedTestResult.downloadBandwidth ?? 0) * 1000,
      decimals: 1,
    );
    final upload = NetworkUtils.formatBitsWithUnit(
      (speedTestResult.uploadBandwidth ?? 0) * 1000,
      decimals: 1,
    );
    final (formattedTimestamp, _) = _formatTimestamp(timestamp ?? '');

    return SpeedTestUIModel(
      downloadSpeed:
          isProgress && download.value == '0' ? '--' : download.value,
      downloadUnit: download.unit,
      uploadSpeed: isProgress && upload.value == '0' ? '--' : upload.value,
      uploadUnit: upload.unit,
      latency: speedTestResult.latency?.toString() ?? '--',
      timestamp: formattedTimestamp,
      serverId: speedTestResult.serverID ?? '--',
      downloadBandwidthKbps: speedTestResult.downloadBandwidth,
      uploadBandwidthKbps: speedTestResult.uploadBandwidth,
    );
  }

  /// Retrieves supported health check modules from the router.
  Future<List<String>> getSupportedHealthCheckModules() async {
    try {
      final result = await _repo.send(
        JNAPAction.getSupportedHealthCheckModules,
        auth: true,
      );
      final modules =
          List<String>.from(result.output['supportedHealthCheckModules']);
      return modules;
    } catch (e) {
      return [];
    }
  }

  /// Retrieves historical health check results from the router.
  Future<JNAPResult> getHealthCheckResults(
    Module module,
    int numberOfMostRecentResults,
    int? resultId,
    bool force,
  ) async {
    try {
      final result = await _repo.send(
        JNAPAction.getHealthCheckResults,
        data: {
          "includeModuleResults": true,
          "healthCheckModule": module.value,
          "lastNumberOfResults": numberOfMostRecentResults,
          'resultIDs': resultId != null ? [resultId] : null,
        }..removeWhere((key, value) => value == null),
        auth: true,
        fetchRemote: force,
      );
      return result;
    } on JNAPError catch (e) {
      return e;
    } on TimeoutException {
      return JNAPError(result: 'TimeoutException');
    } catch (e) {
      return JNAPError(
        result: 'UNKNOWN',
        error: e.runtimeType.toString(),
      );
    }
  }

  /// Sends a command to the router to stop the ongoing health check.
  Future<void> stopHealthCheck() async {
    await _repo.send(
      JNAPAction.stopHealthCheck,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );
  }

  /// Fetches the list of available speed test servers from the router.
  Future<List<HealthCheckServer>> getHealthCheckServers() async {
    try {
      final result = await _repo.send(
        JNAPAction.getCloseHealthCheckServers,
        auth: true,
        fetchRemote: false,
        cacheLevel: CacheLevel.localCached,
      );

      final List<dynamic> serverList =
          result.output['healthCheckServers'] ?? [];
      return serverList
          .map((e) => HealthCheckServer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.d('Failed to fetch health check servers: $e');
    }
    return [];
  }

  /// Formats an ISO 8601 timestamp string into a more readable format (e.g., "Jan 1, 2023, 12:00 PM").
  /// Returns the formatted string and the epoch timestamp.
  (String, int?) _formatTimestamp(String timestamp) {
    try {
      final parsedDate =
          DateFormat("yyyy-MM-ddThh:mm:ssZ").parse(timestamp, true);
      final formatted = DateFormat.yMMMd().add_jm().format(parsedDate);
      return (formatted, parsedDate.millisecondsSinceEpoch);
    } catch (e) {
      return ('--', null);
    }
  }
}
