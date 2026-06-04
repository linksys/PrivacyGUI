import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/speed_test_notifier.dart';

import '../models/diagnostic_result.dart';
import '../models/diagnostic_state.dart';
import '../services/unified_diagnostics_service.dart';

final unifiedDiagnosticsProvider = AutoDisposeNotifierProvider<
    UnifiedDiagnosticsNotifier, UnifiedDiagnosticsState>(
  UnifiedDiagnosticsNotifier.new,
);

/// State machine for unified network diagnostics.
///
/// Orchestrates diagnostic flows for:
/// - Scenario A: No Internet (WAN → DHCP → Gateway → DNS → Internet ping)
/// - Scenario B: Slow Network (Speed Test → WiFi → Devices → Traceroute)
class UnifiedDiagnosticsNotifier
    extends AutoDisposeNotifier<UnifiedDiagnosticsState> {
  UnifiedDiagnosticsService? get _svc =>
      ref.read(unifiedDiagnosticsServiceProvider);

  DiagnosticScope? _scope;
  Future<void>? _runFuture;
  bool _cancelled = false;

  @override
  UnifiedDiagnosticsState build() {
    ref.onDispose(() async {
      final scope = _scope;
      _scope = null;
      if (scope != null) {
        try {
          await scope.release();
        } catch (e) {
          logger.w('[Diagnostics] Failed to release scope on dispose: $e');
        }
      }
    });
    return const UnifiedDiagnosticsState();
  }

  /// Acquire (or reuse) the shared diagnostic scope. Lifecycle is bound to
  /// this notifier — released automatically on dispose.
  Future<DiagnosticScope> _ensureScope() async {
    final existing = _scope;
    if (existing != null && !existing.isReleased) return existing;

    final executor = ref.read(networkDiagnosticsExecutorProvider);
    if (executor == null) {
      throw const ConnectivityError(
          message: 'NetworkDiagnosticsExecutor not available');
    }
    final scope = await executor.acquireScope();
    _scope = scope;
    _svc?.attachScope(scope);
    return scope;
  }

  /// Release the active scope (if any). Used by [cancel] and [goBack] when
  /// the user leaves mid-flow without disposing the notifier.
  Future<void> _releaseScope() async {
    final scope = _scope;
    _scope = null;
    if (scope == null) return;
    try {
      await scope.release();
    } catch (e) {
      logger.w('[Diagnostics] Failed to release scope: $e');
    }
  }

  /// Run full diagnostic — auto-run all checks without user selection.
  Future<void> runFullDiagnostic() async {
    logger.i('[Diagnostics] Running full diagnostic (auto-run)');
    _cancelled = false;
    state =
        const UnifiedDiagnosticsState(step: DiagnosticStep.checkingWanStatus);
    final future = _runFullDiagnosticFlow();
    _runFuture = future;
    try {
      await future;
    } finally {
      if (identical(_runFuture, future)) _runFuture = null;
    }
  }

  /// Switch to the manual ping / traceroute tools view.
  void openManualTools() {
    logger.i('[Diagnostics] Opening manual tools');
    state = const UnifiedDiagnosticsState(step: DiagnosticStep.manualTools);
  }

  /// Start diagnostic flow with pre-qualifier check.
  /// Runs a quick WAN + ping check, then shows flow menu or auto-selects flow.
  Future<void> startWithPreQualifier() async {
    logger.i('[Diagnostics] Starting with pre-qualifier');
    state = const UnifiedDiagnosticsState(step: DiagnosticStep.preQualifying);

    final svc = _svc;
    if (svc == null) {
      logger
          .w('[Diagnostics] Service not available, falling back to flow menu');
      state = state.copyWith(
        step: DiagnosticStep.selectFlow,
        preQualifierResult: PreQualifierResult.internetOk,
      );
      return;
    }

    try {
      // Step 1: Check WAN status
      final wan = await svc.checkWanStatus();
      if (!wan.isUp || !wan.hasIp) {
        logger.i('[Diagnostics] Pre-qualifier: WAN down or no IP');
        state = state.copyWith(
          step: DiagnosticStep.selectFlow,
          preQualifierResult: PreQualifierResult.wanDownNoIp,
        );
        // Auto-select No Internet flow for critical issues
        await selectFlow(DiagnosticFlow.internet);
        return;
      }

      // Step 2: Quick ping to check internet connectivity
      try {
        await _ensureScope();
        final pingResult = await svc.pingInternet(repeatCount: 1);

        if (pingResult.successCount == 0) {
          // Ping failed — could be DNS or internet issue
          logger.i('[Diagnostics] Pre-qualifier: Internet ping failed');
          state = state.copyWith(
            step: DiagnosticStep.selectFlow,
            preQualifierResult: PreQualifierResult.dnsFailure,
          );
        } else if (pingResult.avgResponseTime > 500) {
          // High latency
          logger.i(
              '[Diagnostics] Pre-qualifier: High latency (${pingResult.avgResponseTime}ms)');
          state = state.copyWith(
            step: DiagnosticStep.selectFlow,
            preQualifierResult: PreQualifierResult.internetSlow,
          );
        } else {
          // Internet OK
          logger.i('[Diagnostics] Pre-qualifier: Internet OK');
          state = state.copyWith(
            step: DiagnosticStep.selectFlow,
            preQualifierResult: PreQualifierResult.internetOk,
          );
        }
      } catch (e) {
        logger.w('[Diagnostics] Pre-qualifier ping failed: $e');
        state = state.copyWith(
          step: DiagnosticStep.selectFlow,
          preQualifierResult: PreQualifierResult.dnsFailure,
        );
      }
    } catch (e) {
      logger.w('[Diagnostics] Pre-qualifier failed: $e');
      state = state.copyWith(
        step: DiagnosticStep.selectFlow,
        preQualifierResult: PreQualifierResult.internetOk,
      );
    }
  }

  /// User selects diagnostic flow from menu.
  Future<void> selectFlow(DiagnosticFlow flow) async {
    logger.i('[Diagnostics] Flow selected: $flow');
    _cancelled = false;
    state = state.copyWith(
      flow: flow,
      results: [],
      clearSpeedTest: true,
      clearError: true,
    );

    final future = switch (flow) {
      DiagnosticFlow.internet => _runInternetDiagnostics(),
      DiagnosticFlow.deviceIssues => _runDeviceIssuesDiagnostics(),
      DiagnosticFlow.wifiCoverage => _runWifiCoverageDiagnostics(),
      DiagnosticFlow.meshBackhaul => _runMeshBackhaulDiagnostics(),
      DiagnosticFlow.intermittent => _runIntermittentDiagnostics(),
    };
    _runFuture = future;
    try {
      await future;
    } finally {
      if (identical(_runFuture, future)) _runFuture = null;
    }
  }

  /// Cancel and reset to idle. Awaits any in-flight diagnostic future before
  /// releasing the scope so we don't race with operations still completing.
  Future<void> cancel() async {
    logger.d('[Diagnostics] Cancelled');
    _cancelled = true;
    final inFlight = _runFuture;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }
    await _releaseScope();
    state = const UnifiedDiagnosticsState();
  }

  /// Restart diagnostics — re-run the same flow, or fall back to start screen.
  Future<void> restart() async {
    final flow = state.flow;
    logger.i('[Diagnostics] Restart requested, flow=$flow');

    if (flow != null) {
      await selectFlow(flow);
      return;
    }

    // No prior context — full diagnostic was the entry point.
    await runFullDiagnostic();
  }

  /// Navigate one step back in the diagnostic flow without leaving the page.
  /// Returns true if the back was handled here, false if the caller should
  /// pop the route (back to dashboard).
  bool goBack() {
    switch (state.step) {
      case DiagnosticStep.idle:
        return false;
      case DiagnosticStep.preQualifying:
      case DiagnosticStep.selectFlow:
      case DiagnosticStep.manualTools:
        // Back to start screen
        state = const UnifiedDiagnosticsState();
        return true;
      case DiagnosticStep.showingResults:
      case DiagnosticStep.completed:
        // Back to flow menu if a flow was used, otherwise start screen.
        if (state.flow != null) {
          state = state.copyWith(
            step: DiagnosticStep.selectFlow,
            results: const [],
            recommendations: const [],
            clearSpeedTest: true,
            clearError: true,
            clearFlow: true,
          );
        } else {
          state = const UnifiedDiagnosticsState();
        }
        return true;
      default:
        // Running — mark cancelled, await the in-flight future, then release
        // the scope. Sequencing prevents the linger window from re-entering
        // with a stale scope.
        _cancelled = true;
        unawaited(() async {
          final inFlight = _runFuture;
          if (inFlight != null) {
            try {
              await inFlight;
            } catch (_) {}
          }
          await _releaseScope();
        }());
        if (state.flow != null) {
          state = state.copyWith(
            step: DiagnosticStep.selectFlow,
            results: const [],
            recommendations: const [],
            clearSpeedTest: true,
            clearError: true,
            clearFlow: true,
          );
        } else {
          state = const UnifiedDiagnosticsState();
        }
        return true;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Full Diagnostic (Auto-run all checks)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runFullDiagnosticFlow() async {
    if (_cancelled) return;
    final svc = _svc;
    if (svc == null) {
      _setError(const ConnectivityError(
          message: 'Diagnostics service not available'));
      return;
    }

    final results = <DiagnosticStepUIModel>[];

    // Step 1: Check WAN status
    state = state.copyWith(step: DiagnosticStep.checkingWanStatus);
    WanStatusCheckUIModel? wanResult;
    try {
      final wan = await svc.checkWanStatus();
      wanResult = _evaluateWanStatus(wan);
      results.add(wanResult);
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingWanStatus, e));
      state = state.copyWith(results: List.from(results));
    }

    // Acquire shared scope for all ping and speed test operations.
    // Released on notifier dispose / cancel / back navigation.
    try {
      await _ensureScope();
    } catch (e) {
      logger.e('[Diagnostics] Failed to acquire scope: $e');
    }

    // Step 2: Ping gateway
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

    // Step 3: Ping DNS
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

    // Step 3b: DNS lookup
    state = state.copyWith(step: DiagnosticStep.dnsLookup);
    try {
      final dnsResult = await _runDnsLookup(svc);
      results.add(dnsResult);
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.dnsLookup, e));
      state = state.copyWith(results: List.from(results));
    }

    // Step 4: Ping internet
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

    // Step 5: Speed test
    state = state.copyWith(step: DiagnosticStep.runningSpeedTest);
    try {
      final speedTestResult = await _runSharedSpeedTest();
      if (speedTestResult != null) {
        state = state.copyWith(speedTest: speedTestResult);
        final speedResult = _evaluateSpeedTest(speedTestResult);
        results.add(speedResult);
        state = state.copyWith(results: List.from(results));
      } else {
        results.add(
            _errorResult(DiagnosticStep.runningSpeedTest, 'Speed test failed'));
        state = state.copyWith(results: List.from(results));
      }
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.runningSpeedTest, e));
      state = state.copyWith(results: List.from(results));
    }

    // Step 6: Check WiFi signal (per-radio RSSI)
    state = state.copyWith(step: DiagnosticStep.checkingWifiSignal);
    try {
      final perRadio = await svc.analyzeWifiSignalPerRadio();
      final wifiResult = _evaluateWifiSignal(perRadio);
      results.add(wifiResult);
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingWifiSignal, e));
      state = state.copyWith(results: List.from(results));
    }

    // Step 6b: Check DHCP pool usage
    state = state.copyWith(step: DiagnosticStep.checkingDhcpPool);
    try {
      final pool = await svc.checkDhcpPool();
      final poolResult = _evaluateDhcpPool(pool);
      results.add(poolResult);
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingDhcpPool, e));
      state = state.copyWith(results: List.from(results));
    }

    // Step 6c: Mesh / Backhaul (LAN-only GET — runs even without internet).
    // Skipped silently when only one node exists.
    state = state.copyWith(step: DiagnosticStep.checkingMeshBackhaul);
    try {
      final meshResult = _buildMeshBackhaulResult(
        await svc.checkMeshBackhaul(),
      );
      results.add(meshResult);
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingMeshBackhaul, e));
      state = state.copyWith(results: List.from(results));
    }

    // Step 7: Check connected devices
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

    await _analyzeAndShowResults(results);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Flow 1: Internet (combined connectivity + speed)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runInternetDiagnostics() async {
    if (_cancelled) return;
    final svc = _svc;
    if (svc == null) {
      _setError(const ConnectivityError(
          message: 'Diagnostics service not available'));
      return;
    }

    final results = <DiagnosticStepUIModel>[];
    bool connectivityOk = true;

    // Step 1: Check WAN status
    state = state.copyWith(step: DiagnosticStep.checkingWanStatus);
    try {
      final wan = await svc.checkWanStatus();
      final wanResult = _evaluateWanStatus(wan);
      results.add(wanResult);
      state = state.copyWith(results: List.from(results));
      if (wanResult.isError) connectivityOk = false;
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingWanStatus, e));
      state = state.copyWith(results: List.from(results));
      connectivityOk = false;
    }

    // Step 1b: Check DHCP pool capacity / usage
    state = state.copyWith(step: DiagnosticStep.checkingDhcpPool);
    try {
      final pool = await svc.checkDhcpPool();
      final poolResult = _evaluateDhcpPool(pool);
      results.add(poolResult);
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingDhcpPool, e));
      state = state.copyWith(results: List.from(results));
    }

    try {
      await _ensureScope();
    } catch (e) {
      logger.e('[Diagnostics] Failed to acquire scope: $e');
    }

    // Step 2: Ping gateway
    state = state.copyWith(step: DiagnosticStep.pingGateway);
    try {
      final ping = await svc.pingGateway();
      final pingResult = _evaluatePing(DiagnosticStep.pingGateway, ping);
      results.add(pingResult);
      state = state.copyWith(results: List.from(results));
      if (pingResult.isError) connectivityOk = false;
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.pingGateway, e));
      state = state.copyWith(results: List.from(results));
      connectivityOk = false;
    }

    // Step 3: Ping DNS
    state = state.copyWith(step: DiagnosticStep.pingDns);
    try {
      final ping = await svc.pingDns();
      final pingResult = _evaluatePing(DiagnosticStep.pingDns, ping);
      results.add(pingResult);
      state = state.copyWith(results: List.from(results));
      if (pingResult.isError) connectivityOk = false;
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.pingDns, e));
      state = state.copyWith(results: List.from(results));
      connectivityOk = false;
    }

    // Step 3b: DNS lookup — verify name resolution actually works
    state = state.copyWith(step: DiagnosticStep.dnsLookup);
    try {
      final dnsResult = await _runDnsLookup(svc);
      results.add(dnsResult);
      state = state.copyWith(results: List.from(results));
      if (dnsResult.isError) connectivityOk = false;
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.dnsLookup, e));
      state = state.copyWith(results: List.from(results));
      connectivityOk = false;
    }

    // Step 4: Ping internet
    state = state.copyWith(step: DiagnosticStep.pingInternet);
    try {
      final ping = await svc.pingInternet();
      final pingResult = _evaluatePing(DiagnosticStep.pingInternet, ping);
      results.add(pingResult);
      state = state.copyWith(results: List.from(results));
      if (pingResult.isError) connectivityOk = false;
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.pingInternet, e));
      state = state.copyWith(results: List.from(results));
      connectivityOk = false;
    }

    // Step 5: Speed test (only if connectivity is OK)
    if (connectivityOk) {
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
    }

    await _analyzeAndShowResults(results);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Flow 2: Device Issues
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runDeviceIssuesDiagnostics() async {
    if (_cancelled) return;
    final svc = _svc;
    if (svc == null) {
      _setError(const ConnectivityError(
          message: 'Diagnostics service not available'));
      return;
    }

    logger.i('[Diagnostics] Running Device Issues flow');
    final results = <DiagnosticStepUIModel>[];

    // Step 1: Get all device scores
    state = state.copyWith(step: DiagnosticStep.checkingConnectedDevices);
    try {
      final deviceScores = await svc.getDeviceScores();
      final devicesWithIssues = deviceScores.where((d) => d.hasIssue).toList();

      final severity = devicesWithIssues.isEmpty
          ? DiagnosticSeverity.ok
          : devicesWithIssues.length > 3
              ? DiagnosticSeverity.error
              : DiagnosticSeverity.warning;

      results.add(DeviceIssuesCheckUIModel(
        totalDevices: deviceScores.length,
        devicesWithIssues: devicesWithIssues.length,
        weakSignalDevices: deviceScores
            .where((d) => d.hasWeakSignal)
            .map((d) => d.name)
            .toList(),
        lowDataRateDevices: deviceScores
            .where((d) => d.hasLowDataRate)
            .map((d) => d.name)
            .toList(),
        deviceScores: deviceScores,
        severity: severity,
        titleKey: 'diagnostics_device_issues',
        descriptionKey: 'diagnostics_device_issues_desc',
      ));
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingConnectedDevices, e));
      state = state.copyWith(results: List.from(results));
    }

    await _analyzeAndShowResults(results);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Flow 3: WiFi Coverage
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runWifiCoverageDiagnostics() async {
    if (_cancelled) return;
    final svc = _svc;
    if (svc == null) {
      _setError(const ConnectivityError(
          message: 'Diagnostics service not available'));
      return;
    }

    logger.i('[Diagnostics] Running WiFi Coverage flow');
    final results = <DiagnosticStepUIModel>[];

    // Step 1: Check WiFi radios
    state = state.copyWith(step: DiagnosticStep.checkingWifiSignal);
    try {
      final coverage = await svc.analyzeWifiCoverage();

      final severity = coverage.hasCoverageIssues
          ? DiagnosticSeverity.error
          : coverage.hasWeakSignalDevices
              ? DiagnosticSeverity.warning
              : DiagnosticSeverity.ok;

      results.add(WifiCoverageCheckUIModel(
        totalWirelessDevices: coverage.totalWirelessDevices,
        weakSignalDevices: coverage.weakSignalDevices
            .map((d) => '${d.name} (${d.rssiDbm} dBm)')
            .toList(),
        averageSignalStrength: coverage.averageSignalStrength,
        radios: coverage.radios,
        severity: severity,
        titleKey: 'diagnostics_wifi_coverage',
        descriptionKey: 'diagnostics_wifi_coverage_desc',
      ));
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingWifiSignal, e));
      state = state.copyWith(results: List.from(results));
    }

    await _analyzeAndShowResults(results);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Flow: Mesh / Backhaul
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runMeshBackhaulDiagnostics() async {
    if (_cancelled) return;
    final svc = _svc;
    if (svc == null) {
      _setError(const ConnectivityError(
          message: 'Diagnostics service not available'));
      return;
    }

    logger.i('[Diagnostics] Running Mesh / Backhaul flow');
    final results = <DiagnosticStepUIModel>[];

    state = state.copyWith(step: DiagnosticStep.checkingMeshBackhaul);
    try {
      final records = await svc.checkMeshBackhaul();
      results.add(_buildMeshBackhaulResult(records));
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.checkingMeshBackhaul, e));
      state = state.copyWith(results: List.from(results));
    }

    await _analyzeAndShowResults(results);
  }

  /// Map raw [MeshBackhaulNodeRecord] list to a [MeshBackhaulCheckUIModel],
  /// handling the single-node skip case. Shared by full diagnostic and the
  /// dedicated Mesh / Backhaul flow.
  MeshBackhaulCheckUIModel _buildMeshBackhaulResult(
      List<MeshBackhaulNodeRecord> records) {
    if (records.isEmpty) {
      return MeshBackhaulCheckUIModel(
        nodes: const [],
        severity: DiagnosticSeverity.skipped,
        titleKey: 'diagnostics_mesh_backhaul_single_node',
        descriptionKey: 'diagnostics_mesh_backhaul_single_node_desc',
      );
    }

    final nodes = records
        .map((r) => MeshNodeBackhaulUIModel(
              nodeId: r.nodeId,
              label: r.label,
              mediaType: r.mediaType,
              phyRateMbps: r.phyRateMbps,
              lastUplinkRateMbps: r.lastUplinkRateMbps,
              signalStrengthDbm: r.signalStrengthDbm,
              isController: r.isController,
              severity: switch (r.severity) {
                MeshBackhaulSeverityBucket.healthy =>
                  MeshBackhaulSeverity.healthy,
                MeshBackhaulSeverityBucket.weak => MeshBackhaulSeverity.weak,
                MeshBackhaulSeverityBucket.poor => MeshBackhaulSeverity.poor,
              },
            ))
        .toList();

    final hasPoor = nodes.any((n) => n.severity == MeshBackhaulSeverity.poor);
    final hasWeak = nodes.any((n) => n.severity == MeshBackhaulSeverity.weak);
    final severity = hasPoor
        ? DiagnosticSeverity.error
        : hasWeak
            ? DiagnosticSeverity.warning
            : DiagnosticSeverity.ok;

    return MeshBackhaulCheckUIModel(
      nodes: nodes,
      severity: severity,
      titleKey: 'diagnostics_mesh_backhaul',
      descriptionKey: 'diagnostics_mesh_backhaul_desc',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Flow 4: Intermittent
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _runIntermittentDiagnostics() async {
    if (_cancelled) return;
    final svc = _svc;
    if (svc == null) {
      _setError(const ConnectivityError(
          message: 'Diagnostics service not available'));
      return;
    }

    logger.i('[Diagnostics] Running Intermittent flow');
    final results = <DiagnosticStepUIModel>[];

    try {
      await _ensureScope();
    } catch (e) {
      logger.e('[Diagnostics] Failed to acquire scope: $e');
    }

    // Step 1: Check intermittent issues (uptime + jitter)
    state = state.copyWith(step: DiagnosticStep.pingInternet);
    try {
      final intermittent = await svc.checkIntermittent();

      final severity = intermittent.hasPacketLoss
          ? DiagnosticSeverity.error
          : intermittent.hasHighJitter || intermittent.recentReboot
              ? DiagnosticSeverity.warning
              : DiagnosticSeverity.ok;

      results.add(IntermittentCheckUIModel(
        uptimeSeconds: intermittent.uptimeSeconds,
        uptimeFormatted: intermittent.uptimeFormatted,
        pingSuccessRate: intermittent.pingSuccessRate,
        averageLatencyMs: intermittent.averageLatencyMs,
        jitterMs: intermittent.jitterMs,
        hasHighJitter: intermittent.hasHighJitter,
        hasPacketLoss: intermittent.hasPacketLoss,
        recentReboot: intermittent.recentReboot,
        severity: severity,
        titleKey: 'diagnostics_intermittent',
        descriptionKey: 'diagnostics_intermittent_desc',
      ));
      state = state.copyWith(results: List.from(results));
    } catch (e) {
      results.add(_errorResult(DiagnosticStep.pingInternet, e));
      state = state.copyWith(results: List.from(results));
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
          logger.w('[Diagnostics] SpeedTest error: ${speedState.error}');
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
  // Analysis & Recommendations
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _analyzeAndShowResults(
      List<DiagnosticStepUIModel> results) async {
    state = state.copyWith(step: DiagnosticStep.analyzing);

    final recommendations = _generateRecommendations(results);

    state = state.copyWith(
      step: DiagnosticStep.showingResults,
      recommendations: recommendations,
    );
    logger.i(
        '[Diagnostics] Complete — ${recommendations.length} recommendations');
  }

  List<RecommendationUIModel> _generateRecommendations(
      List<DiagnosticStepUIModel> results) {
    final recommendations = <RecommendationUIModel>[];

    for (final result in results) {
      if (result.isOk || result.isSkipped) continue;

      switch (result.step) {
        case DiagnosticStep.checkingWanStatus:
          if (result is WanStatusCheckUIModel) {
            if (!result.isUp) {
              recommendations.add(RecommendationUIModel(
                id: 'wan_down',
                titleKey: 'diagnostics_rec_wan_down_title',
                descriptionKey: 'diagnostics_rec_wan_down_desc',
                priority: 0,
                actionId: 'restartModem',
              ));
            } else if (!result.hasIp) {
              recommendations.add(RecommendationUIModel(
                id: 'no_ip',
                titleKey: 'diagnostics_rec_no_ip_title',
                descriptionKey: 'diagnostics_rec_no_ip_desc',
                priority: 1,
                actionId: 'renewDhcp',
              ));
            }
          }
        case DiagnosticStep.checkingDhcp:
          recommendations.add(RecommendationUIModel(
            id: 'dhcp_fail',
            titleKey: 'diagnostics_rec_dhcp_fail_title',
            descriptionKey: 'diagnostics_rec_dhcp_fail_desc',
            priority: 1,
            actionId: 'renewDhcp',
          ));
        case DiagnosticStep.checkingDhcpPool:
          if (result is DhcpPoolCheckUIModel) {
            if (result.isExhausted) {
              recommendations.add(RecommendationUIModel(
                id: 'dhcp_pool_exhausted',
                titleKey: 'diagnostics_rec_dhcp_pool_exhausted_title',
                descriptionKey: 'diagnostics_rec_dhcp_pool_exhausted_desc',
                priority: 1,
                actionId: 'expandDhcpPool',
              ));
            } else if (result.isNearCapacity) {
              recommendations.add(RecommendationUIModel(
                id: 'dhcp_pool_near',
                titleKey: 'diagnostics_rec_dhcp_pool_near_title',
                descriptionKey: 'diagnostics_rec_dhcp_pool_near_desc',
                priority: 8,
                actionId: 'expandDhcpPool',
              ));
            }
          }
        case DiagnosticStep.pingGateway:
          recommendations.add(RecommendationUIModel(
            id: 'gateway_unreachable',
            titleKey: 'diagnostics_rec_gateway_title',
            descriptionKey: 'diagnostics_rec_gateway_desc',
            priority: 2,
            actionId: 'checkCable',
          ));
        case DiagnosticStep.pingDns:
          recommendations.add(RecommendationUIModel(
            id: 'dns_fail',
            titleKey: 'diagnostics_rec_dns_fail_title',
            descriptionKey: 'diagnostics_rec_dns_fail_desc',
            priority: 3,
            actionId: 'changeDns',
          ));
        case DiagnosticStep.dnsLookup:
          if (result is DnsLookupCheckUIModel && !result.hasResolved) {
            recommendations.add(RecommendationUIModel(
              id: 'dns_lookup_fail',
              titleKey: 'diagnostics_rec_dns_lookup_fail_title',
              descriptionKey: 'diagnostics_rec_dns_lookup_fail_desc',
              priority: 3,
              actionId: 'changeDns',
            ));
          }
        case DiagnosticStep.pingInternet:
          recommendations.add(RecommendationUIModel(
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
              recommendations.add(RecommendationUIModel(
                id: 'slow_download',
                titleKey: 'diagnostics_rec_slow_download_title',
                descriptionKey: 'diagnostics_rec_slow_download_desc',
                priority: 5,
              ));
            }
            if (speedTest.isSlowUpload) {
              recommendations.add(RecommendationUIModel(
                id: 'slow_upload',
                titleKey: 'diagnostics_rec_slow_upload_title',
                descriptionKey: 'diagnostics_rec_slow_upload_desc',
                priority: 6,
              ));
            }
          }
        case DiagnosticStep.checkingWifiSignal:
          if (result is WifiSignalCheckUIModel && result.isWeakSignal) {
            recommendations.add(RecommendationUIModel(
              id: 'weak_wifi',
              titleKey: 'diagnostics_rec_weak_wifi_title',
              descriptionKey: 'diagnostics_rec_weak_wifi_desc',
              priority: 7,
              actionId: 'moveCloser',
            ));
          }
        case DiagnosticStep.checkingConnectedDevices:
          if (result is ConnectedDevicesCheckUIModel) {
            if (result.hasManyDevices) {
              recommendations.add(RecommendationUIModel(
                id: 'too_many_devices',
                titleKey: 'diagnostics_rec_many_devices_title',
                descriptionKey: 'diagnostics_rec_many_devices_desc',
                priority: 8,
                actionId: 'reviewDevices',
              ));
            }
            if (result.hasHighBandwidthDevices) {
              recommendations.add(RecommendationUIModel(
                id: 'high_bandwidth_devices',
                titleKey: 'diagnostics_rec_bandwidth_hog_title',
                descriptionKey: 'diagnostics_rec_bandwidth_hog_desc',
                priority: 9,
              ));
            }
          }
        case DiagnosticStep.runningTraceroute:
          recommendations.add(RecommendationUIModel(
            id: 'network_bottleneck',
            titleKey: 'diagnostics_rec_bottleneck_title',
            descriptionKey: 'diagnostics_rec_bottleneck_desc',
            priority: 10,
          ));
        case DiagnosticStep.checkingMeshBackhaul:
          if (result is MeshBackhaulCheckUIModel) {
            if (result.poorCount > 0) {
              recommendations.add(RecommendationUIModel(
                id: 'mesh_backhaul_poor',
                titleKey: 'diagnostics_rec_mesh_backhaul_poor_title',
                descriptionKey: 'diagnostics_rec_mesh_backhaul_poor_desc',
                priority: 4,
                actionId: 'meshUseEthernetBackhaul',
              ));
            } else if (result.weakCount > 0) {
              recommendations.add(RecommendationUIModel(
                id: 'mesh_backhaul_weak',
                titleKey: 'diagnostics_rec_mesh_backhaul_weak_title',
                descriptionKey: 'diagnostics_rec_mesh_backhaul_weak_desc',
                priority: 7,
                actionId: 'repositionMeshNode',
              ));
            }
          }
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

  /// Runs an NSLookup against a well-known host and merges configured DNS
  /// servers from `Device.DNS.Client.*` so the result tile shows both
  /// "DNS that the router uses" and "DNS resolution actually works".
  Future<DnsLookupCheckUIModel> _runDnsLookup(
    UnifiedDiagnosticsService svc, {
    String hostName = 'www.google.com',
  }) async {
    final nsResult = await svc.nsLookup(hostName);

    List<String> configuredServers = const [];
    try {
      final dns = await svc.getDnsClient();
      configuredServers = dns.servers
          .where((s) => s.address.isNotEmpty)
          .map((s) => s.address)
          .toList();
    } catch (e) {
      logger.w('[Diagnostics] Failed to fetch DNS client info: $e');
    }

    final firstAnswer = nsResult.answers.isNotEmpty
        ? nsResult.answers
            .firstWhere((a) => a.isOk, orElse: () => nsResult.answers.first)
        : null;
    final resolvedIps = firstAnswer?.ipAddresses ?? const <String>[];
    final dnsServerUsed = firstAnswer?.dnsServerIp ?? '';
    final responseTimeMs = firstAnswer?.responseTimeMs ?? 0;

    DiagnosticSeverity severity;
    String titleKey;
    String descriptionKey;

    if (resolvedIps.isEmpty) {
      severity = DiagnosticSeverity.error;
      titleKey = 'diagnostics_dns_lookup_fail';
      descriptionKey = 'diagnostics_dns_lookup_fail_desc';
    } else if (responseTimeMs > 500) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_dns_lookup_slow';
      descriptionKey = 'diagnostics_dns_lookup_slow_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_dns_lookup_ok';
      descriptionKey = 'diagnostics_dns_lookup_ok_desc';
    }

    return DnsLookupCheckUIModel(
      hostName: hostName,
      resolvedIps: resolvedIps,
      dnsServerUsed: dnsServerUsed,
      responseTimeMs: responseTimeMs,
      configuredDnsServers: configuredServers,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  WanStatusCheckUIModel _evaluateWanStatus(WanStatusUIModel wan) {
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

    return WanStatusCheckUIModel(
      status: wan.status,
      ipAddress: wan.ipAddress,
      addressingType: wan.addressingType,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  PingCheckUIModel _evaluatePing(DiagnosticStep step, PingResult pingResult) {
    final host = pingResult.host;
    final successCount = pingResult.successCount;
    final failureCount = pingResult.failureCount;
    final avgResponseTime = pingResult.avgResponseTime;

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

    return PingCheckUIModel(
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

  DiagnosticStepUIModel _evaluateSpeedTest(SpeedTestResult speedTest) {
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

    return DiagnosticStepUIModel(
      step: DiagnosticStep.runningSpeedTest,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      rawData: {
        'downloadMbps': speedTest.downloadMbps,
        'uploadMbps': speedTest.uploadMbps,
        'hasUpload': speedTest.hasUpload,
        if (speedTest.hasLatency) 'latencyMs': speedTest.latencyMs!,
        if (speedTest.serverHost != null) 'serverHost': speedTest.serverHost!,
      },
    );
  }

  WifiSignalCheckUIModel _evaluateWifiSignal(WifiSignalPerRadioUIModel info) {
    final activeRadios = info.activeRadios;

    if (info.totalClients == 0) {
      // No wireless clients to sample — surface the radios but skip RSSI.
      final firstResolved =
          info.radios.where((r) => r.isResolved).toList().firstOrNull;
      return WifiSignalCheckUIModel(
        rssi: 0,
        channel: firstResolved?.channel ?? 0,
        band: firstResolved?.band ?? 'Unknown',
        connectedDevices: 0,
        radios: info.radios,
        severity: DiagnosticSeverity.ok,
        titleKey: 'diagnostics_wifi_no_clients',
        descriptionKey: 'diagnostics_wifi_no_clients_desc',
      );
    }

    final weighted = info.weightedAverageRssi;
    final hasWeak = info.hasWeakRadio;

    final DiagnosticSeverity severity;
    final String titleKey;
    final String descriptionKey;

    if (hasWeak || weighted < -75) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_wifi_weak';
      descriptionKey = 'diagnostics_wifi_weak_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_wifi_ok';
      descriptionKey = 'diagnostics_wifi_ok_desc';
    }

    // Pick the radio carrying the most clients to populate the legacy
    // single-band/channel summary fields.
    final primary = activeRadios.isNotEmpty
        ? (activeRadios.toList()
              ..sort((a, b) => b.clientCount.compareTo(a.clientCount)))
            .first
        : null;

    return WifiSignalCheckUIModel(
      rssi: weighted,
      channel: primary?.channel ?? 0,
      band: primary?.band ?? 'Unknown',
      connectedDevices: info.totalClients,
      radios: info.radios,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  DhcpPoolCheckUIModel _evaluateDhcpPool(DhcpPoolUsageUIModel info) {
    final DiagnosticSeverity severity;
    final String titleKey;
    final String descriptionKey;

    if (!info.enabled) {
      severity = DiagnosticSeverity.skipped;
      titleKey = 'diagnostics_dhcp_pool_disabled';
      descriptionKey = 'diagnostics_dhcp_pool_disabled_desc';
    } else if (info.capacityUnknown) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_dhcp_pool_unknown';
      descriptionKey = 'diagnostics_dhcp_pool_unknown_desc';
    } else if (info.isExhausted) {
      severity = DiagnosticSeverity.error;
      titleKey = 'diagnostics_dhcp_pool_exhausted';
      descriptionKey = 'diagnostics_dhcp_pool_exhausted_desc';
    } else if (info.isNearCapacity) {
      severity = DiagnosticSeverity.warning;
      titleKey = 'diagnostics_dhcp_pool_near';
      descriptionKey = 'diagnostics_dhcp_pool_near_desc';
    } else {
      severity = DiagnosticSeverity.ok;
      titleKey = 'diagnostics_dhcp_pool_ok';
      descriptionKey = 'diagnostics_dhcp_pool_ok_desc';
    }

    return DhcpPoolCheckUIModel(
      dhcpEnabled: info.enabled,
      minAddress: info.minAddress,
      maxAddress: info.maxAddress,
      capacity: info.capacity,
      usedLeases: info.usedLeases,
      totalLeases: info.totalLeases,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  ConnectedDevicesCheckUIModel _evaluateConnectedDevices(
      ConnectedDevicesUIModel devices) {
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

    return ConnectedDevicesCheckUIModel(
      totalDevices: devices.totalDevices,
      activeDevices: devices.activeDevices,
      highBandwidthDevices: devices.highBandwidthDevices,
      severity: severity,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
    );
  }

  DiagnosticStepUIModel _errorResult(DiagnosticStep step, Object error) {
    logger.e('[Diagnostics] Step $step failed: $error');
    return DiagnosticStepUIModel(
      step: step,
      severity: DiagnosticSeverity.error,
      titleKey: 'diagnostics_step_error',
      descriptionKey: 'diagnostics_step_error_desc',
      rawData: {'error': error.toString()},
    );
  }

  void _setError(ServiceError error) {
    logger.e('[Diagnostics] Error: $error');
    state = state.copyWith(
      step: DiagnosticStep.showingResults,
      error: error,
    );
  }
}
