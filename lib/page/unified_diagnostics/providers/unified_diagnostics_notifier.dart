import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/speed_test/models/speed_test_state.dart';
import 'package:privacy_gui/page/speed_test/providers/speed_test_notifier.dart';

import '../models/diagnostic_result.dart';
import '../models/diagnostic_state.dart';
import '../services/unified_diagnostics_service.dart';

final unifiedDiagnosticsProvider =
    NotifierProvider<UnifiedDiagnosticsNotifier, UnifiedDiagnosticsState>(
  UnifiedDiagnosticsNotifier.new,
);

/// State machine for unified network diagnostics.
///
/// Orchestrates diagnostic flows for:
/// - Scenario A: No Internet (WAN → DHCP → Gateway → DNS → Internet ping)
/// - Scenario B: Slow Network (Speed Test → WiFi → Devices → Traceroute)
class UnifiedDiagnosticsNotifier extends Notifier<UnifiedDiagnosticsState> {
  UnifiedDiagnosticsService? get _svc =>
      ref.read(unifiedDiagnosticsServiceProvider);

  @override
  UnifiedDiagnosticsState build() => const UnifiedDiagnosticsState();

  /// Start diagnostic flow — show problem selector.
  void start() {
    logger.i('[Diagnostics] Starting — show problem selector');
    state = const UnifiedDiagnosticsState(step: DiagnosticStep.selectProblem);
  }

  /// User selects problem type — run appropriate diagnostic flow.
  Future<void> selectProblem(ProblemType type) async {
    logger.i('[Diagnostics] Problem selected: $type');
    // Full reset with new problem type
    state = UnifiedDiagnosticsState(
      step: DiagnosticStep.idle,
      problemType: type,
    );

    if (type == ProblemType.noInternet) {
      await _runNoInternetDiagnostics();
    } else {
      await _runSlowNetworkDiagnostics();
    }
  }

  /// Cancel and reset to idle.
  Future<void> cancel() async {
    logger.d('[Diagnostics] Cancelled');
    // Cleanup any active session
    try {
      await _svc?.endSession();
    } catch (e) {
      logger.w('[Diagnostics] Failed to cleanup session on cancel: $e');
    }
    state = const UnifiedDiagnosticsState();
  }

  /// Restart diagnostics with same problem type.
  Future<void> restart() async {
    final problemType = state.problemType;
    logger.i('[Diagnostics] Restart requested, problemType=$problemType');
    if (problemType == null) {
      start();
      return;
    }
    await selectProblem(problemType);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Scenario A: No Internet
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runNoInternetDiagnostics() async {
    final svc = _svc;
    if (svc == null) {
      _setError('Diagnostics service not available');
      return;
    }

    final results = <DiagnosticStepResult>[];

    // Step 1: Check WAN status
    state = state.copyWith(step: DiagnosticStep.checkingWanStatus);
    WanStatusCheckResult? wanResult;
    try {
      final wan = await svc.checkWanStatus();
      wanResult = _evaluateWanStatus(wan);
      results.add(wanResult);
      state = state.copyWith(results: List.from(results));

      if (wanResult.isError) {
        await _analyzeAndShowResults(results);
        return;
      }
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingWanStatus, e));
      state = state.copyWith(results: List.from(results));
      await _analyzeAndShowResults(results);
      return;
    }

    // Step 2: Check DHCP (skip if static IP)
    state = state.copyWith(step: DiagnosticStep.checkingDhcp);
    if (wanResult.addressingType != 'Static') {
      final dhcpResult = _evaluateDhcp(wanResult);
      results.add(dhcpResult);
      state = state.copyWith(results: List.from(results));

      if (dhcpResult.isError) {
        await _analyzeAndShowResults(results);
        return;
      }
    } else {
      results.add(DiagnosticStepResult(
        step: DiagnosticStep.checkingDhcp,
        severity: DiagnosticSeverity.skipped,
        titleKey: 'diagnostics_dhcp_skipped',
        descriptionKey: 'diagnostics_dhcp_static_ip',
      ));
      state = state.copyWith(results: List.from(results));
    }

    // Start shared session for all ping operations
    try {
      await svc.startSession();
    } catch (e) {
      logger.e('[Diagnostics] Failed to start session: $e');
    }

    try {
      // Step 3: Ping gateway
      state = state.copyWith(step: DiagnosticStep.pingGateway);
      try {
        final ping = await svc.pingGateway();
        final pingResult = _evaluatePing(DiagnosticStep.pingGateway, ping);
        results.add(pingResult);
        state = state.copyWith(results: List.from(results));
      } catch (e) {
        results.add(_errorResult(DiagnosticStep.pingGateway, e));
        state = state.copyWith(results: List.from(results));
      }

      // Step 4: Ping DNS
      state = state.copyWith(step: DiagnosticStep.pingDns);
      try {
        final ping = await svc.pingDns();
        final pingResult = _evaluatePing(DiagnosticStep.pingDns, ping);
        results.add(pingResult);
        state = state.copyWith(results: List.from(results));
      } catch (e) {
        results.add(_errorResult(DiagnosticStep.pingDns, e));
        state = state.copyWith(results: List.from(results));
      }

      // Step 5: Ping internet
      state = state.copyWith(step: DiagnosticStep.pingInternet);
      try {
        final ping = await svc.pingInternet();
        final pingResult = _evaluatePing(DiagnosticStep.pingInternet, ping);
        results.add(pingResult);
        state = state.copyWith(results: List.from(results));
      } catch (e) {
        results.add(_errorResult(DiagnosticStep.pingInternet, e));
        state = state.copyWith(results: List.from(results));
      }
    } finally {
      // Always cleanup session
      try {
        await svc.endSession();
      } catch (e) {
        logger.w('[Diagnostics] Failed to end session: $e');
      }
    }

    await _analyzeAndShowResults(results);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shared Speed Test
  // ══════════════════════════════════════════════════════════════════════════

  /// Run speed test using shared [speedTestProvider] and wait for completion.
  Future<SpeedTestResult?> _runSharedSpeedTest() async {
    logger.d('[Diagnostics] Starting shared speed test');

    // Wait for provider to be ready
    final asyncState = ref.read(speedTestProvider);
    if (asyncState.isLoading) {
      logger.d('[Diagnostics] Waiting for speedTestProvider to initialize');
      await ref.read(speedTestProvider.future);
    }

    // Now start the speed test
    final notifier = ref.read(speedTestProvider.notifier);
    logger.d('[Diagnostics] Calling runSpeedTest()');

    // Don't await - runSpeedTest updates state asynchronously
    unawaited(notifier.runSpeedTest());

    // Wait for completion by polling the provider state
    final completer = Completer<SpeedTestResult?>();

    void checkState() {
      final speedState = ref.read(speedTestProvider).valueOrNull;
      if (speedState == null) return;

      logger.d('[Diagnostics] SpeedTest state: step=${speedState.step}');

      if (speedState.step == SpeedTestStep.completed &&
          speedState.result != null) {
        if (!completer.isCompleted) {
          logger.d('[Diagnostics] SpeedTest completed');
          completer.complete(speedState.result);
        }
      } else if (speedState.step == SpeedTestStep.error) {
        if (!completer.isCompleted) {
          logger.w('[Diagnostics] SpeedTest error: ${speedState.errorMessage}');
          completer.complete(null);
        }
      }
    }

    // Listen for state changes
    final sub = ref.listen(speedTestProvider, (_, __) => checkState());

    // Also check immediately in case it's already done
    checkState();

    // Timeout after 3 minutes
    final result = await completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        logger.w('[Diagnostics] Speed test timed out');
        return null;
      },
    );

    sub.close();
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Scenario B: Slow Network
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runSlowNetworkDiagnostics() async {
    final svc = _svc;
    if (svc == null) {
      _setError('Diagnostics service not available');
      return;
    }

    final results = <DiagnosticStepResult>[];

    // Start shared session for speed test latency ping and traceroute
    try {
      await svc.startSession();
    } catch (e) {
      logger.e('[Diagnostics] Failed to start session: $e');
    }

    try {
      // Step 1: Speed test (using shared speedTestProvider)
      state = state.copyWith(step: DiagnosticStep.runningSpeedTest);
      try {
        final speedTestResult = await _runSharedSpeedTest();
        if (speedTestResult != null) {
          state = state.copyWith(speedTest: speedTestResult);
          final speedResult = _evaluateSpeedTest(speedTestResult);
          results.add(speedResult);
          state = state.copyWith(results: List.from(results));
        } else {
          results.add(_errorResult(
              DiagnosticStep.runningSpeedTest, 'Speed test failed'));
          state = state.copyWith(results: List.from(results));
        }
      } catch (e) {
        results.add(_errorResult(DiagnosticStep.runningSpeedTest, e));
        state = state.copyWith(results: List.from(results));
      }

      // Step 2: Check WiFi signal
      state = state.copyWith(step: DiagnosticStep.checkingWifiSignal);
      try {
        final radios = await svc.checkWifiRadios();
        final wifiResult = _evaluateWifiRadios(radios);
        results.add(wifiResult);
        state = state.copyWith(results: List.from(results));
      } catch (e) {
        results.add(_errorResult(DiagnosticStep.checkingWifiSignal, e));
        state = state.copyWith(results: List.from(results));
      }

      // Step 3: Check connected devices
      state = state.copyWith(step: DiagnosticStep.checkingConnectedDevices);
      try {
        final devices = await svc.checkConnectedDevices();
        final devicesResult = _evaluateConnectedDevices(devices);
        results.add(devicesResult);
        state = state.copyWith(results: List.from(results));
      } catch (e) {
        results.add(_errorResult(DiagnosticStep.checkingConnectedDevices, e));
        state = state.copyWith(results: List.from(results));
      }

      // Step 4: Traceroute (if speed test showed issues)
      final speedTest = state.speedTest;
      if (speedTest != null &&
          (speedTest.isSlowDownload || speedTest.isSlowUpload)) {
        state = state.copyWith(step: DiagnosticStep.runningTraceroute);
        try {
          final traceroute = await svc.traceroute();
          final tracerouteResult = _evaluateTraceroute(traceroute);
          results.add(tracerouteResult);
          state = state.copyWith(results: List.from(results));
        } catch (e) {
          results.add(_errorResult(DiagnosticStep.runningTraceroute, e));
          state = state.copyWith(results: List.from(results));
        }
      }
    } finally {
      // Always cleanup session
      try {
        await svc.endSession();
      } catch (e) {
        logger.w('[Diagnostics] Failed to end session: $e');
      }
    }

    await _analyzeAndShowResults(results);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Analysis & Recommendations
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _analyzeAndShowResults(
      List<DiagnosticStepResult> results) async {
    state = state.copyWith(step: DiagnosticStep.analyzing);

    final recommendations = _generateRecommendations(results);

    state = state.copyWith(
      step: DiagnosticStep.showingResults,
      recommendations: recommendations,
    );
    logger.i(
        '[Diagnostics] Complete — ${recommendations.length} recommendations');
  }

  List<Recommendation> _generateRecommendations(
      List<DiagnosticStepResult> results) {
    final recommendations = <Recommendation>[];

    for (final result in results) {
      if (result.isOk || result.isSkipped) continue;

      switch (result.step) {
        case DiagnosticStep.checkingWanStatus:
          if (result is WanStatusCheckResult) {
            if (!result.isUp) {
              recommendations.add(Recommendation(
                id: 'wan_down',
                titleKey: 'diagnostics_rec_wan_down_title',
                descriptionKey: 'diagnostics_rec_wan_down_desc',
                priority: 0,
                actionId: 'restartModem',
              ));
            } else if (!result.hasIp) {
              recommendations.add(Recommendation(
                id: 'no_ip',
                titleKey: 'diagnostics_rec_no_ip_title',
                descriptionKey: 'diagnostics_rec_no_ip_desc',
                priority: 1,
                actionId: 'renewDhcp',
              ));
            }
          }
        case DiagnosticStep.checkingDhcp:
          recommendations.add(Recommendation(
            id: 'dhcp_fail',
            titleKey: 'diagnostics_rec_dhcp_fail_title',
            descriptionKey: 'diagnostics_rec_dhcp_fail_desc',
            priority: 1,
            actionId: 'renewDhcp',
          ));
        case DiagnosticStep.pingGateway:
          recommendations.add(Recommendation(
            id: 'gateway_unreachable',
            titleKey: 'diagnostics_rec_gateway_title',
            descriptionKey: 'diagnostics_rec_gateway_desc',
            priority: 2,
            actionId: 'checkCable',
          ));
        case DiagnosticStep.pingDns:
          recommendations.add(Recommendation(
            id: 'dns_fail',
            titleKey: 'diagnostics_rec_dns_fail_title',
            descriptionKey: 'diagnostics_rec_dns_fail_desc',
            priority: 3,
            actionId: 'changeDns',
          ));
        case DiagnosticStep.pingInternet:
          recommendations.add(Recommendation(
            id: 'internet_unreachable',
            titleKey: 'diagnostics_rec_internet_title',
            descriptionKey: 'diagnostics_rec_internet_desc',
            priority: 4,
            actionId: 'contactIsp',
          ));
        case DiagnosticStep.runningSpeedTest:
          final speedTest = state.speedTest;
          if (speedTest != null) {
            if (speedTest.isSlowDownload) {
              recommendations.add(Recommendation(
                id: 'slow_download',
                titleKey: 'diagnostics_rec_slow_download_title',
                descriptionKey: 'diagnostics_rec_slow_download_desc',
                priority: 5,
              ));
            }
            if (speedTest.isSlowUpload) {
              recommendations.add(Recommendation(
                id: 'slow_upload',
                titleKey: 'diagnostics_rec_slow_upload_title',
                descriptionKey: 'diagnostics_rec_slow_upload_desc',
                priority: 6,
              ));
            }
          }
        case DiagnosticStep.checkingWifiSignal:
          if (result is WifiSignalCheckResult && result.isWeakSignal) {
            recommendations.add(Recommendation(
              id: 'weak_wifi',
              titleKey: 'diagnostics_rec_weak_wifi_title',
              descriptionKey: 'diagnostics_rec_weak_wifi_desc',
              priority: 7,
              actionId: 'moveCloser',
            ));
          }
        case DiagnosticStep.checkingConnectedDevices:
          if (result is ConnectedDevicesCheckResult) {
            if (result.hasManyDevices) {
              recommendations.add(Recommendation(
                id: 'too_many_devices',
                titleKey: 'diagnostics_rec_many_devices_title',
                descriptionKey: 'diagnostics_rec_many_devices_desc',
                priority: 8,
                actionId: 'reviewDevices',
              ));
            }
            if (result.hasHighBandwidthDevices) {
              recommendations.add(Recommendation(
                id: 'high_bandwidth_devices',
                titleKey: 'diagnostics_rec_bandwidth_hog_title',
                descriptionKey: 'diagnostics_rec_bandwidth_hog_desc',
                priority: 9,
              ));
            }
          }
        case DiagnosticStep.runningTraceroute:
          recommendations.add(Recommendation(
            id: 'network_bottleneck',
            titleKey: 'diagnostics_rec_bottleneck_title',
            descriptionKey: 'diagnostics_rec_bottleneck_desc',
            priority: 10,
          ));
        default:
          break;
      }
    }

    recommendations.sort((a, b) => a.priority.compareTo(b.priority));
    return recommendations;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Evaluation Helpers
  // ══════════════════════════════════════════════════════════════════════════

  WanStatusCheckResult _evaluateWanStatus(WanStatusInfo wan) {
    DiagnosticSeverity severity;
    String titleKey;
    String descriptionKey;

    if (!wan.isUp) {
      severity = DiagnosticSeverity.error;
      titleKey = 'diagnostics_wan_down';
      descriptionKey = 'diagnostics_wan_down_desc';
    } else if (!wan.hasIp) {
      severity = DiagnosticSeverity.error;
      titleKey = 'diagnostics_no_ip';
      descriptionKey = 'diagnostics_no_ip_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_wan_ok';
      descriptionKey = 'diagnostics_wan_ok_desc';
    }

    return WanStatusCheckResult(
      status: wan.status,
      ipAddress: wan.ipAddress,
      addressingType: wan.addressingType,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  DiagnosticStepResult _evaluateDhcp(WanStatusCheckResult wanResult) {
    if (wanResult.hasIp) {
      return DiagnosticStepResult(
        step: DiagnosticStep.checkingDhcp,
        severity: DiagnosticSeverity.ok,
        titleKey: 'diagnostics_dhcp_ok',
        descriptionKey: 'diagnostics_dhcp_ok_desc',
      );
    } else {
      return DiagnosticStepResult(
        step: DiagnosticStep.checkingDhcp,
        severity: DiagnosticSeverity.error,
        titleKey: 'diagnostics_dhcp_fail',
        descriptionKey: 'diagnostics_dhcp_fail_desc',
      );
    }
  }

  PingCheckResult _evaluatePing(DiagnosticStep step, dynamic pingResult) {
    final host = pingResult.host as String;
    final successCount = pingResult.successCount as int;
    final failureCount = pingResult.failureCount as int;
    final avgResponseTime = pingResult.avgResponseTime as int;

    DiagnosticSeverity severity;
    String titleKey;
    String descriptionKey;

    if (successCount == 0) {
      severity = DiagnosticSeverity.error;
      titleKey = 'diagnostics_ping_fail';
      descriptionKey = 'diagnostics_ping_fail_desc';
    } else if (failureCount > 0) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_ping_partial';
      descriptionKey = 'diagnostics_ping_partial_desc';
    } else if (avgResponseTime > 100) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_ping_slow';
      descriptionKey = 'diagnostics_ping_slow_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_ping_ok';
      descriptionKey = 'diagnostics_ping_ok_desc';
    }

    return PingCheckResult(
      step: step,
      host: host,
      successCount: successCount,
      failureCount: failureCount,
      avgResponseTime: avgResponseTime,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  DiagnosticStepResult _evaluateSpeedTest(SpeedTestResult speedTest) {
    DiagnosticSeverity severity;
    String titleKey;
    String descriptionKey;

    if (speedTest.isSlowDownload && speedTest.isSlowUpload) {
      severity = DiagnosticSeverity.error;
      titleKey = 'diagnostics_speed_slow';
      descriptionKey = 'diagnostics_speed_slow_desc';
    } else if (speedTest.isSlowDownload || speedTest.isSlowUpload) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_speed_partial';
      descriptionKey = 'diagnostics_speed_partial_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_speed_ok';
      descriptionKey = 'diagnostics_speed_ok_desc';
    }

    return DiagnosticStepResult(
      step: DiagnosticStep.runningSpeedTest,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      rawData: {
        'downloadMbps': speedTest.downloadMbps,
        'uploadMbps': speedTest.uploadMbps,
      },
    );
  }

  WifiSignalCheckResult _evaluateWifiRadios(List<WiFiRadioInfo> radios) {
    final activeRadios = radios.where((r) => r.status == 'Up').toList();

    if (activeRadios.isEmpty) {
      return WifiSignalCheckResult(
        rssi: 0,
        channel: 0,
        band: 'Unknown',
        connectedDevices: 0,
        severity: DiagnosticSeverity.warning,
        titleKey: 'diagnostics_wifi_no_active',
        descriptionKey: 'diagnostics_wifi_no_active_desc',
      );
    }

    final primaryRadio = activeRadios.first;
    return WifiSignalCheckResult(
      rssi: -50, // TODO: Get actual RSSI from associated devices
      channel: primaryRadio.channel,
      band: primaryRadio.band,
      connectedDevices: 0,
      severity: DiagnosticSeverity.ok,
      titleKey: 'diagnostics_wifi_ok',
      descriptionKey: 'diagnostics_wifi_ok_desc',
    );
  }

  ConnectedDevicesCheckResult _evaluateConnectedDevices(
      ConnectedDevicesInfo devices) {
    DiagnosticSeverity severity;
    String titleKey;
    String descriptionKey;

    if (devices.hasManyDevices) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_devices_many';
      descriptionKey = 'diagnostics_devices_many_desc';
    } else if (devices.hasHighBandwidthDevices) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_devices_bandwidth';
      descriptionKey = 'diagnostics_devices_bandwidth_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_devices_ok';
      descriptionKey = 'diagnostics_devices_ok_desc';
    }

    return ConnectedDevicesCheckResult(
      totalDevices: devices.totalDevices,
      activeDevices: devices.activeDevices,
      highBandwidthDevices: devices.highBandwidthDevices,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  TracerouteCheckResult _evaluateTraceroute(TracerouteResult traceroute) {
    final hopInfos = traceroute.hops
        .map((h) => TracerouteHopInfo(
              hopNumber: h.hopNumber,
              host: h.host,
              hostAddress: h.hostAddress,
              avgRoundTrip: h.avgRoundTrip,
            ))
        .toList();

    final slowHops = hopInfos.where((h) => h.isSlow).toList();

    DiagnosticSeverity severity;
    String titleKey;
    String descriptionKey;

    if (slowHops.isNotEmpty) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_traceroute_slow';
      descriptionKey = 'diagnostics_traceroute_slow_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_traceroute_ok';
      descriptionKey = 'diagnostics_traceroute_ok_desc';
    }

    return TracerouteCheckResult(
      hops: hopInfos,
      targetHost: traceroute.host,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  DiagnosticStepResult _errorResult(DiagnosticStep step, Object error) {
    logger.e('[Diagnostics] Step $step failed: $error');
    return DiagnosticStepResult(
      step: step,
      severity: DiagnosticSeverity.error,
      titleKey: 'diagnostics_step_error',
      descriptionKey: 'diagnostics_step_error_desc',
      rawData: {'error': error.toString()},
    );
  }

  void _setError(String message) {
    logger.e('[Diagnostics] Error: $message');
    state = state.copyWith(
      step: DiagnosticStep.showingResults,
      errorMessage: message,
    );
  }
}
