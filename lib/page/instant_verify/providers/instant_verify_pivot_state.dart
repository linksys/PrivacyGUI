import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';

enum PivotLoadPhase {
  /// Initial state — JNAP data not yet received.
  loading,

  /// JNAP data loaded (<1s). Verdict can surface device/firmware/WAN findings.
  /// Browser speed tests are running in background.
  jnapLoaded,

  /// All tests complete — verdict includes speed findings.
  complete,
}

class InstantVerifyPivotState extends Equatable {
  final PivotLoadPhase phase;

  // ── JNAP data (Phase 1 — available <1s) ──────────────────────────────
  final Map<String, dynamic>? deviceInfo;
  final Map<String, dynamic>? wanStatus;
  final Map<String, dynamic>? routerHealth;
  final List<DiagnosticClient> clients;
  final Map<String, dynamic>? firmwareUpdate;
  final Map<String, dynamic>? radioInfo;
  final Map<String, dynamic>? guestNetwork;
  final Map<String, dynamic>? ethernetPorts;
  final Map<String, dynamic>? ipv6Settings;
  final Map<String, dynamic>? macFilter;
  final Map<String, dynamic>? networkSecurity;
  final Map<String, dynamic>? parentalControls;
  final Map<String, dynamic>? wirelessSchedule;
  final Map<String, dynamic>? channelInfo;
  final Map<String, dynamic>? backhaulInfo;
  final int dhcpLeasesCount;
  final int dhcpPoolLimit;

  // ── Browser test results (Phase 2 — arrive over 20-30s) ──────────────
  final GatewayPingResult? gatewayPing;
  final DnsCheckResult? dnsCheck;
  final SpeedTestResult? speedTest;
  final RouterSpeedResult? routerSpeed;

  /// Current browser test step: 'idle' | 'gateway' | 'dns' | 'speed' | 'complete' | 'error'
  final String browserTestStep;

  // ── Agent-provided context (optional inputs) ─────────────────────────
  final double? planSpeedMbps;

  // ── Computed values ───────────────────────────────────────────────────
  final List<DeviceScore> deviceScores;
  final Verdict? verdict;

  /// True while speed tests running — verdict card shows "Preliminary" badge.
  final bool verdictIsPreliminary;

  // ── Action state ──────────────────────────────────────────────────────
  final bool isRestarting;
  final bool isUpdatingFirmware;
  final String? pingOutput;
  final String? tracerouteOutput;
  final bool isPingRunning;

  final String? errorMessage;

  const InstantVerifyPivotState({
    this.phase = PivotLoadPhase.loading,
    this.deviceInfo,
    this.wanStatus,
    this.routerHealth,
    this.clients = const [],
    this.firmwareUpdate,
    this.radioInfo,
    this.guestNetwork,
    this.ethernetPorts,
    this.ipv6Settings,
    this.macFilter,
    this.networkSecurity,
    this.parentalControls,
    this.wirelessSchedule,
    this.channelInfo,
    this.backhaulInfo,
    this.dhcpLeasesCount = 0,
    this.dhcpPoolLimit = 150,
    this.gatewayPing,
    this.dnsCheck,
    this.speedTest,
    this.routerSpeed,
    this.browserTestStep = 'idle',
    this.planSpeedMbps,
    this.deviceScores = const [],
    this.verdict,
    this.verdictIsPreliminary = true,
    this.isRestarting = false,
    this.isUpdatingFirmware = false,
    this.pingOutput,
    this.tracerouteOutput,
    this.isPingRunning = false,
    this.errorMessage,
  });

  InstantVerifyPivotState copyWith({
    PivotLoadPhase? phase,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? wanStatus,
    Map<String, dynamic>? routerHealth,
    List<DiagnosticClient>? clients,
    Map<String, dynamic>? firmwareUpdate,
    Map<String, dynamic>? radioInfo,
    Map<String, dynamic>? guestNetwork,
    Map<String, dynamic>? ethernetPorts,
    Map<String, dynamic>? ipv6Settings,
    Map<String, dynamic>? macFilter,
    Map<String, dynamic>? networkSecurity,
    Map<String, dynamic>? parentalControls,
    Map<String, dynamic>? wirelessSchedule,
    Map<String, dynamic>? channelInfo,
    Map<String, dynamic>? backhaulInfo,
    int? dhcpLeasesCount,
    int? dhcpPoolLimit,
    GatewayPingResult? gatewayPing,
    DnsCheckResult? dnsCheck,
    SpeedTestResult? speedTest,
    RouterSpeedResult? routerSpeed,
    String? browserTestStep,
    double? planSpeedMbps,
    List<DeviceScore>? deviceScores,
    Verdict? verdict,
    bool? verdictIsPreliminary,
    bool? isRestarting,
    bool? isUpdatingFirmware,
    String? pingOutput,
    String? tracerouteOutput,
    bool? isPingRunning,
    String? errorMessage,
  }) {
    return InstantVerifyPivotState(
      phase: phase ?? this.phase,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      wanStatus: wanStatus ?? this.wanStatus,
      routerHealth: routerHealth ?? this.routerHealth,
      clients: clients ?? this.clients,
      firmwareUpdate: firmwareUpdate ?? this.firmwareUpdate,
      radioInfo: radioInfo ?? this.radioInfo,
      guestNetwork: guestNetwork ?? this.guestNetwork,
      ethernetPorts: ethernetPorts ?? this.ethernetPorts,
      ipv6Settings: ipv6Settings ?? this.ipv6Settings,
      macFilter: macFilter ?? this.macFilter,
      networkSecurity: networkSecurity ?? this.networkSecurity,
      parentalControls: parentalControls ?? this.parentalControls,
      wirelessSchedule: wirelessSchedule ?? this.wirelessSchedule,
      channelInfo: channelInfo ?? this.channelInfo,
      backhaulInfo: backhaulInfo ?? this.backhaulInfo,
      dhcpLeasesCount: dhcpLeasesCount ?? this.dhcpLeasesCount,
      dhcpPoolLimit: dhcpPoolLimit ?? this.dhcpPoolLimit,
      gatewayPing: gatewayPing ?? this.gatewayPing,
      dnsCheck: dnsCheck ?? this.dnsCheck,
      speedTest: speedTest ?? this.speedTest,
      routerSpeed: routerSpeed ?? this.routerSpeed,
      browserTestStep: browserTestStep ?? this.browserTestStep,
      planSpeedMbps: planSpeedMbps ?? this.planSpeedMbps,
      deviceScores: deviceScores ?? this.deviceScores,
      verdict: verdict ?? this.verdict,
      verdictIsPreliminary: verdictIsPreliminary ?? this.verdictIsPreliminary,
      isRestarting: isRestarting ?? this.isRestarting,
      isUpdatingFirmware: isUpdatingFirmware ?? this.isUpdatingFirmware,
      pingOutput: pingOutput ?? this.pingOutput,
      tracerouteOutput: tracerouteOutput ?? this.tracerouteOutput,
      isPingRunning: isPingRunning ?? this.isPingRunning,
      errorMessage: errorMessage,
    );
  }

  // ── Computed getters ──────────────────────────────────────────────────

  bool get wanConnected {
    if (wanStatus == null) return false;
    final status = wanStatus!['wanStatus'] as String?;
    return status == 'Connected' || status == 'connected';
  }

  int get uptimeSeconds {
    if (routerHealth == null) return 0;
    return (routerHealth!['uptimeInSeconds'] as int?) ?? 0;
  }

  bool get firmwareUpdateAvailable {
    if (firmwareUpdate == null) return false;
    final status = firmwareUpdate!['firmwareUpdateStatus'] as String?;
    return status == 'UpdateAvailable';
  }

  String? get availableFirmwareVersion =>
      firmwareUpdate?['availableUpdate']?['firmwareVersion'] as String?;

  String? get routerModel => deviceInfo?['modelNumber'] as String?;
  String? get routerSerial => deviceInfo?['serialNumber'] as String?;
  String? get routerFirmware => deviceInfo?['firmwareVersion'] as String?;
  String? get wanIpAddress => wanStatus?['ipAddress'] as String?;
  String? get wanConnectionType => wanStatus?['detectedWANType'] as String?
      ?? wanStatus?['wanType'] as String?;

  int get issueDeviceCount => deviceScores.where((d) => d.isIssue).length;
  int get atRiskDeviceCount => deviceScores.where((d) => d.isAtRisk).length;
  int get goodDeviceCount => deviceScores.where((d) => d.isGood).length;
  int get wirelessDeviceCount => clients.where((c) => c.isWireless).length;
  int get wiredDeviceCount => clients.where((c) => !c.isWireless).length;

  double get dhcpUtilization =>
      dhcpPoolLimit > 0 ? dhcpLeasesCount / dhcpPoolLimit : 0;

  List<DeviceScore> get issueDevices =>
      deviceScores.where((d) => d.isIssue).toList()
        ..sort((a, b) => a.score.compareTo(b.score));

  bool get isBrowserTestRunning =>
      browserTestStep != 'idle' &&
      browserTestStep != 'complete' &&
      browserTestStep != 'error';

  @override
  List<Object?> get props => [
        phase,
        deviceInfo,
        wanStatus,
        routerHealth,
        clients,
        firmwareUpdate,
        radioInfo,
        guestNetwork,
        ethernetPorts,
        ipv6Settings,
        macFilter,
        networkSecurity,
        parentalControls,
        wirelessSchedule,
        channelInfo,
        backhaulInfo,
        dhcpLeasesCount,
        dhcpPoolLimit,
        gatewayPing,
        dnsCheck,
        speedTest,
        routerSpeed,
        browserTestStep,
        planSpeedMbps,
        deviceScores,
        verdict,
        verdictIsPreliminary,
        isRestarting,
        isUpdatingFirmware,
        pingOutput,
        tracerouteOutput,
        isPingRunning,
        errorMessage,
      ];
}
