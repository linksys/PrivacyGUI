import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/services/usp_admin_service.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/providers/local_storage_stub.dart'
    if (dart.library.html)
        'package:privacy_gui/page/instant_test/providers/local_storage_web.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart'
    show SpeedTestStep;
import 'package:privacy_gui/page/unified_diagnostics/providers/speed_test_notifier.dart';

final instantTestProvider =
    NotifierProvider<InstantTestNotifier, InstantTestState>(
  InstantTestNotifier.new,
);

class InstantTestNotifier extends Notifier<InstantTestState> {
  /// Incremented on every fetch() — _runBrowserTests checks this before
  /// each state write; if it changed, a newer fetch started and we abort.
  int _fetchGeneration = 0;

  /// Timestamp of the last completed speed test — used to skip re-running
  /// within 3 minutes on passive reloads unless explicitly forced.
  DateTime? _lastSpeedTestTime;

  /// Timestamp of the last speed-test ATTEMPT. Enforces a hard minimum cooldown
  /// that even a forced/explicit re-run cannot bypass — abuse backstop against
  /// button-hammering. (Ported from JNAP line.)
  DateTime? _lastSpeedTestAttempt;

  /// Minimum time between speed-test attempts, even when forced.
  static const speedTestCooldown = Duration(seconds: 15);

  /// Seconds remaining before another speed test may run (0 = ready).
  int get speedTestCooldownRemaining {
    if (_lastSpeedTestAttempt == null) return 0;
    final remaining =
        speedTestCooldown - DateTime.now().difference(_lastSpeedTestAttempt!);
    return remaining.isNegative ? 0 : remaining.inSeconds + 1;
  }

  @override
  InstantTestState build() {
    // Watch dashboardOrchestratorProvider to ensure all L1 providers
    // (devicesDataProvider, wanDataProvider, ethernetDataProvider) are
    // populated even when deep-linking directly to /uspInstantTest without
    // visiting the dashboard page first.
    ref.watch(dashboardOrchestratorProvider);
    return const InstantTestState();
  }

  // ── Main load ─────────────────────────────────────────────────────────

  /// Load all USP provider data then run browser tests in background.
  ///
  /// [forceSpeedTest] bypasses the 3-minute TTL.
  Future<void> fetch({bool forceSpeedTest = false}) async {
    final generation = ++_fetchGeneration;
    state = InstantTestState(
      phase: InstantTestLoadPhase.loading,
      planSpeedMbps: state.planSpeedMbps,
      journeyActions: state.journeyActions,
      flowEntered: state.flowEntered,
    );

    try {
      // Read typed USP providers — no JNAP calls.
      final devicesData = ref.read(devicesDataProvider).valueOrNull;
      final wanData = ref.read(wanDataProvider).valueOrNull;
      final ethernetData = ref.read(ethernetDataProvider).valueOrNull;
      final sysInfoData = ref.read(systemInfoDataProvider).valueOrNull;
      final firmwareBanks = ref.read(firmwareBanksDataProvider).valueOrNull;

      final clients = devicesData?.clientDevices ?? [];
      final meshNodes = devicesData?.nodeModels ?? [];
      final ethernetPorts = ethernetData?.ethernetPortModels ?? [];
      final wanStatus = wanData?.model;

      // Build clientToNodeId map from DeviceUIModel.parentNodeId
      final clientToNodeId = <String, String>{};
      for (final device in clients) {
        if (device.parentNodeId != null) {
          clientToNodeId[device.mac] = device.parentNodeId!;
        }
      }

      // Compute device scores
      final deviceScores = clients
          .where((d) => d.isWifi)
          .map((d) => DeviceScore.compute(d))
          .toList();

      // Firmware info from systemInfoDataProvider
      final sysModel = sysInfoData?.model;
      final firmwareUpdateAvailable =
          firmwareBanks?.availableBank != null;
      // Router identity for the AppBar header — model from the master node,
      // serial from system info.
      final masters = meshNodes.where((n) => n.isMaster);
      final routerModel = masters.isNotEmpty ? masters.first.model : null;
      final routerSerial = sysModel?.serialNumber;

      // Check for recent restart in localStorage
      final lastRestartStr = getStoredValue('instant_test_last_restart');
      final recentPriorRestart = lastRestartStr != null &&
          DateTime.now()
                  .difference(DateTime.tryParse(lastRestartStr) ?? DateTime(2000))
                  .inMinutes <
              30;

      state = state.copyWith(
        phase: InstantTestLoadPhase.uspLoaded,
        wanStatus: wanStatus,
        clients: clients,
        meshNodes: meshNodes,
        ethernetPorts: ethernetPorts,
        routerModel: routerModel,
        routerSerial: routerSerial,
        firmwareVersion: sysModel?.softwareVersion,
        firmwareUpdateAvailable: firmwareUpdateAvailable,
        uptimeSeconds: sysModel?.uptime,
        clientToNodeId: clientToNodeId,
        deviceScores: deviceScores,
        recentPriorRestart: recentPriorRestart,
        verdictIsPreliminary: true,
      );

      // Compute preliminary verdict from USP data alone
      _updateVerdict(preliminary: true);

      // Run browser tests asynchronously
      unawaited(_runBrowserTests(generation, forceSpeedTest: forceSpeedTest));
    } catch (e) {
      logger.e('[InstantTest] fetch error: $e');
      state = state.copyWith(
        phase: InstantTestLoadPhase.complete,
        errorMessage: 'Failed to load diagnostic data: $e',
      );
    }
  }

  // ── Browser tests ────────────────────────────────────────────────────

  Future<void> _runBrowserTests(int generation,
      {bool forceSpeedTest = false}) async {
    final svc = BrowserDiagnosticService();

    // 1. Gateway ping
    if (_fetchGeneration != generation) return;
    state = state.copyWith(browserTestStep: 'gateway');
    final gateway = await svc.pingGateway();
    if (_fetchGeneration != generation) return;
    state = state.copyWith(gatewayPing: gateway);
    _updateVerdict(preliminary: true);

    // 2. DNS check
    if (_fetchGeneration != generation) return;
    state = state.copyWith(browserTestStep: 'dns');
    final dns = await svc.checkDns();
    if (_fetchGeneration != generation) return;
    state = state.copyWith(dnsCheck: dns);

    // 2b. If DNS failed, run public DNS check for root-cause differentiation
    DnsCheckResult? publicDns;
    if (!dns.resolved) {
      publicDns = await svc.checkPublicDns();
      if (_fetchGeneration != generation) return;
      state = state.copyWith(publicDnsCheck: publicDns);
    }
    _updateVerdict(preliminary: true);

    // 3. Speed test (skip if recent and not forced, or within hard cooldown)
    final now = DateTime.now();
    final withinHardCooldown = _lastSpeedTestAttempt != null &&
        now.difference(_lastSpeedTestAttempt!) < speedTestCooldown;
    final skipSpeed = withinHardCooldown ||
        (!forceSpeedTest &&
            _lastSpeedTestTime != null &&
            now.difference(_lastSpeedTestTime!).inMinutes < 3);

    if (!skipSpeed) {
      if (_fetchGeneration != generation) return;
      _lastSpeedTestAttempt = DateTime.now();
      state = state.copyWith(browserTestStep: 'speed');

      // Client→Internet leg (Cloudflare)
      final speed = await svc.runInternetSpeedTest(
        onStep: (step) {
          if (_fetchGeneration == generation) {
            state = state.copyWith(browserTestStep: 'speed:$step');
          }
        },
      );
      if (_fetchGeneration != generation) return;
      // A 0 download means the CDN was unreachable — don't store it as a real
      // result (false "0 Mbps"); flag the check as failed so the UI surfaces
      // "couldn't finish" instead of a false all-clear. (Ported from JNAP.)
      if (speed.downloadMbps > 0) {
        _lastSpeedTestTime = DateTime.now();
        state = state.copyWith(speedTest: speed, speedTestFailed: false);
      } else {
        state = state.copyWith(speedTestFailed: true);
      }
      _updateVerdict(preliminary: false);

      // Client→Router leg (D-R7 Phase 3): measures WiFi throughput
      try {
        if (_fetchGeneration == generation) {
          state = state.copyWith(browserTestStep: 'speed:client-router');
          final routerSpeed = await svc.runRouterSpeedTest(
            onStep: (step) {
              if (_fetchGeneration == generation) {
                state = state.copyWith(browserTestStep: 'speed:router:$step');
              }
            },
          );
          if (_fetchGeneration != generation) return;
          state = state.copyWith(routerSpeed: routerSpeed);
          _updateVerdict(preliminary: false);
        }
      } catch (e) {
        logger.w('[InstantTest] Client-router speed test failed: $e');
      }

      // Router→Internet leg (D-R7): USP speedTestProvider
      try {
        if (_fetchGeneration == generation) {
          state = state.copyWith(browserTestStep: 'speed:router-internet');
          final uspSpeed = ref.read(speedTestProvider);
          if (uspSpeed.valueOrNull?.step !=
              SpeedTestStep.completed) {
            await ref.read(speedTestProvider.notifier).runSpeedTest();
          }
          if (_fetchGeneration != generation) return;
          final routerResult = ref.read(speedTestProvider).valueOrNull?.result;
          if (routerResult != null) {
            state = state.copyWith(routerInternetResult: routerResult);
            _updateVerdict(preliminary: false);
          }
        }
      } catch (e) {
        logger.w('[InstantTest] Router-internet speed test failed: $e');
      }
    }

    if (_fetchGeneration != generation) return;
    state = state.copyWith(
      phase: InstantTestLoadPhase.complete,
      browserTestStep: 'complete',
      verdictIsPreliminary: false,
      completedAt: DateTime.now(),
    );
    _updateVerdict(preliminary: false);
  }

  // ── Verdict computation ───────────────────────────────────────────────

  void _updateVerdict({required bool preliminary}) {
    final s = state;
    final wan = s.wanStatus;

    final verdict = VerdictEngine.compute(
      gatewayReachable: s.gatewayPing?.reachable,
      wanConnected: wan?.isUp,
      wanIpAddress: wan?.ipAddress,
      dnsWorking: s.dnsCheck?.resolved,
      downloadMbps: s.speedTest?.downloadMbps,
      latencyMs: s.speedTest?.latencyMs,
      speedTestFailed: s.speedTestFailed,
      firmwareUpdateAvailable: s.firmwareUpdateAvailable,
      firmwareVersion: s.firmwareVersion,
      uptimeSeconds: s.uptimeSeconds,
      publicDnsWorking: s.publicDnsCheck?.resolved,
      configuredDnsReachable: s.configuredDnsReachable,
      deviceScores: s.deviceScores,
      clients: s.clients,
      meshNodes: s.meshNodes,
      planSpeedMbps: s.planSpeedMbps,
      cpuLoadPct: s.cpuLoadPctEnd,
      cpuLoadPctStart: s.cpuLoadPctStart,
      memoryLoadPct: s.memoryLoadPct,
      routerInternetDownloadMbps: s.routerInternetResult?.downloadMbps,
    );

    state = state.copyWith(
      verdict: verdict,
      verdictIsPreliminary: preliminary,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────

  void setPlanSpeed(double mbps) {
    state = state.copyWith(planSpeedMbps: mbps);
    _updateVerdict(preliminary: state.verdictIsPreliminary);
  }

  void setFlowEntered(String flowKey) {
    state = state.copyWith(flowEntered: flowKey);
  }

  void setEscalationReason(String reason) {
    state = state.copyWith(escalationReason: reason);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // ── Restart (D-R1: Connection Recovery wrap) ─────────────────────────────
  // Callers must invoke showRecoveryDialog after this returns to show the
  // recovery UI (SSE pause + probe loop + auto-dismiss).

  Future<void> restartRouter() async {
    state = state.copyWith(isRestarting: true, errorMessage: null);
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await ref.read(uspAdminServiceProvider).reboot();
      });
      // Record restart for recurrence detection
      setStoredValue(
        'instant_test_last_restart',
        DateTime.now().toUtc().toIso8601String(),
      );
      state = state.copyWith(
        isRestarting: false,
        hasRestartedThisSession: true,
      );
    } on ServiceError catch (e) {
      logger.e('[InstantTest] restartRouter failed', error: e);
      state = state.copyWith(
        isRestarting: false,
        errorMessage: 'Restart failed: ${e.toString()}',
      );
      rethrow;
    }
  }
}
