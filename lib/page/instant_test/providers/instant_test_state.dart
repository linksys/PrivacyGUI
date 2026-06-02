import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/instant_test/models/customer_journey.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart'
    as usp_speed;

enum InstantTestLoadPhase {
  /// Initial state — tests have not been triggered yet.
  idle,

  /// USP providers loading.
  loading,

  /// USP data loaded. Verdict can surface device/WAN findings.
  /// Browser speed tests running in background.
  uspLoaded,

  /// All tests complete — verdict includes speed findings.
  complete,
}

class InstantTestState extends Equatable {
  final InstantTestLoadPhase phase;

  // ── USP data — typed models (Phase 1 — available immediately from providers) ──
  final WanStatusUIModel? wanStatus;
  final List<DeviceUIModel> clients;
  final List<NodeUIModel> meshNodes;
  final List<EthernetPortUIModel> ethernetPorts;

  // ── System info (from systemInfoDataProvider) ─────────────────────────
  final String? firmwareVersion;
  final bool? firmwareUpdateAvailable;
  final int? uptimeSeconds;
  final int? cpuLoadPctStart;
  final int? cpuLoadPctEnd;
  final int? memoryLoadPct;

  // ── Computed USP values ────────────────────────────────────────────────
  /// Maps client MAC address → parent node device ID.
  final Map<String, String> clientToNodeId;

  // ── Browser test results (Phase 2 — arrive over 20-30s) ──────────────
  final GatewayPingResult? gatewayPing;
  final DnsCheckResult? dnsCheck;
  final DnsCheckResult? publicDnsCheck;
  final bool? configuredDnsReachable;
  final SpeedTestResult? speedTest;
  final RouterSpeedResult? routerSpeed;

  // ── Three-leg speed test: router→internet leg (USP speedTestProvider) ──
  final usp_speed.SpeedTestResult? routerInternetResult;

  final String browserTestStep;

  // ── Staleness tracking ────────────────────────────────────────────────
  /// When the last complete run finished. Used for "Last checked N minutes ago".
  final DateTime? completedAt;

  // ── Agent-provided context (optional inputs) ─────────────────────────
  final double? planSpeedMbps;

  // ── Computed verdict ──────────────────────────────────────────────────
  final List<DeviceScore> deviceScores;
  final Verdict? verdict;
  final bool verdictIsPreliminary;

  // ── Customer journey tracking ─────────────────────────────────────────
  final List<JourneyAction> journeyActions;
  final String? flowEntered;
  final String? escalationReason;

  // ── Action state ──────────────────────────────────────────────────────
  final bool hasRestartedThisSession;
  final bool recentPriorRestart;
  final bool isRestarting;
  final bool isUpdatingFirmware;
  final String? pingOutput;
  final String? tracerouteOutput;
  final bool isPingRunning;

  final String? errorMessage;

  const InstantTestState({
    this.phase = InstantTestLoadPhase.idle,
    this.wanStatus,
    this.clients = const [],
    this.meshNodes = const [],
    this.ethernetPorts = const [],
    this.firmwareVersion,
    this.firmwareUpdateAvailable,
    this.uptimeSeconds,
    this.cpuLoadPctStart,
    this.cpuLoadPctEnd,
    this.memoryLoadPct,
    this.clientToNodeId = const {},
    this.gatewayPing,
    this.dnsCheck,
    this.publicDnsCheck,
    this.configuredDnsReachable,
    this.speedTest,
    this.routerSpeed,
    this.routerInternetResult,
    this.browserTestStep = 'idle',
    this.completedAt,
    this.planSpeedMbps,
    this.deviceScores = const [],
    this.verdict,
    this.verdictIsPreliminary = true,
    this.journeyActions = const [],
    this.flowEntered,
    this.escalationReason,
    this.hasRestartedThisSession = false,
    this.recentPriorRestart = false,
    this.isRestarting = false,
    this.isUpdatingFirmware = false,
    this.pingOutput,
    this.tracerouteOutput,
    this.isPingRunning = false,
    this.errorMessage,
  });

  InstantTestState copyWith({
    InstantTestLoadPhase? phase,
    WanStatusUIModel? wanStatus,
    List<DeviceUIModel>? clients,
    List<NodeUIModel>? meshNodes,
    List<EthernetPortUIModel>? ethernetPorts,
    String? firmwareVersion,
    bool? firmwareUpdateAvailable,
    int? uptimeSeconds,
    int? cpuLoadPctStart,
    int? cpuLoadPctEnd,
    int? memoryLoadPct,
    Map<String, String>? clientToNodeId,
    GatewayPingResult? gatewayPing,
    DnsCheckResult? dnsCheck,
    DnsCheckResult? publicDnsCheck,
    bool? configuredDnsReachable,
    SpeedTestResult? speedTest,
    RouterSpeedResult? routerSpeed,
    usp_speed.SpeedTestResult? routerInternetResult,
    String? browserTestStep,
    DateTime? completedAt,
    double? planSpeedMbps,
    List<DeviceScore>? deviceScores,
    Verdict? verdict,
    bool? verdictIsPreliminary,
    List<JourneyAction>? journeyActions,
    String? flowEntered,
    String? escalationReason,
    bool? hasRestartedThisSession,
    bool? recentPriorRestart,
    bool? isRestarting,
    bool? isUpdatingFirmware,
    String? pingOutput,
    String? tracerouteOutput,
    bool? isPingRunning,
    String? errorMessage,
  }) {
    return InstantTestState(
      phase: phase ?? this.phase,
      wanStatus: wanStatus ?? this.wanStatus,
      clients: clients ?? this.clients,
      meshNodes: meshNodes ?? this.meshNodes,
      ethernetPorts: ethernetPorts ?? this.ethernetPorts,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      firmwareUpdateAvailable: firmwareUpdateAvailable ?? this.firmwareUpdateAvailable,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      cpuLoadPctStart: cpuLoadPctStart ?? this.cpuLoadPctStart,
      cpuLoadPctEnd: cpuLoadPctEnd ?? this.cpuLoadPctEnd,
      memoryLoadPct: memoryLoadPct ?? this.memoryLoadPct,
      clientToNodeId: clientToNodeId ?? this.clientToNodeId,
      gatewayPing: gatewayPing ?? this.gatewayPing,
      dnsCheck: dnsCheck ?? this.dnsCheck,
      publicDnsCheck: publicDnsCheck ?? this.publicDnsCheck,
      configuredDnsReachable: configuredDnsReachable ?? this.configuredDnsReachable,
      speedTest: speedTest ?? this.speedTest,
      routerSpeed: routerSpeed ?? this.routerSpeed,
      routerInternetResult: routerInternetResult ?? this.routerInternetResult,
      browserTestStep: browserTestStep ?? this.browserTestStep,
      completedAt: completedAt ?? this.completedAt,
      planSpeedMbps: planSpeedMbps ?? this.planSpeedMbps,
      deviceScores: deviceScores ?? this.deviceScores,
      verdict: verdict ?? this.verdict,
      verdictIsPreliminary: verdictIsPreliminary ?? this.verdictIsPreliminary,
      journeyActions: journeyActions ?? this.journeyActions,
      flowEntered: flowEntered ?? this.flowEntered,
      escalationReason: escalationReason ?? this.escalationReason,
      hasRestartedThisSession: hasRestartedThisSession ?? this.hasRestartedThisSession,
      recentPriorRestart: recentPriorRestart ?? this.recentPriorRestart,
      isRestarting: isRestarting ?? this.isRestarting,
      isUpdatingFirmware: isUpdatingFirmware ?? this.isUpdatingFirmware,
      pingOutput: pingOutput ?? this.pingOutput,
      tracerouteOutput: tracerouteOutput ?? this.tracerouteOutput,
      isPingRunning: isPingRunning ?? this.isPingRunning,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        wanStatus,
        clients,
        meshNodes,
        ethernetPorts,
        firmwareVersion,
        firmwareUpdateAvailable,
        uptimeSeconds,
        cpuLoadPctStart,
        cpuLoadPctEnd,
        memoryLoadPct,
        clientToNodeId,
        gatewayPing,
        dnsCheck,
        publicDnsCheck,
        configuredDnsReachable,
        speedTest,
        routerSpeed,
        routerInternetResult,
        browserTestStep,
        // completedAt intentionally excluded from props:
        // wall-clock timestamps would make two diagnostically identical states
        // unequal, causing spurious Riverpod re-notifications on every re-run.
        planSpeedMbps,
        deviceScores,
        verdict,
        verdictIsPreliminary,
        journeyActions,
        flowEntered,
        escalationReason,
        hasRestartedThisSession,
        recentPriorRestart,
        isRestarting,
        isUpdatingFirmware,
        pingOutput,
        tracerouteOutput,
        isPingRunning,
        errorMessage,
      ];
}
