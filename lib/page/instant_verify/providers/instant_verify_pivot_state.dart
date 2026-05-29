import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/instant_verify/models/customer_journey.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/jnap_capability.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';

enum PivotLoadPhase {
  /// Initial state — tests have not been triggered yet.
  idle,

  /// JNAP data loading.
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

  // ── Two-sample CPU measurement (#24) ──────────────────────────────────
  /// CPU load % sampled at the START of the diagnostic run (Phase 1a).
  final int? cpuLoadPctStart;
  /// CPU load % sampled at the END (after browser tests complete).
  /// If only start is high but end is normal, the spike was transient (our own JNAP burst).
  final int? cpuLoadPctEnd;

  // ── Browser test results (Phase 2 — arrive over 20-30s) ──────────────
  final GatewayPingResult? gatewayPing;
  final DnsCheckResult? dnsCheck;
  /// Result of a silent check against Google's public DNS (8.8.8.8 DoH).
  /// Null = not yet run. Only populated when [dnsCheck] resolved = false.
  /// Used internally to distinguish ISP DNS failure from full internet outage.
  final DnsCheckResult? publicDnsCheck;
  /// Whether the configured DNS server IPs respond to ICMP ping from the router.
  /// Null = not checked. Combined with [publicDnsCheck] for three-way diagnosis.
  final bool? configuredDnsReachable;
  final SpeedTestResult? speedTest;
  final RouterSpeedResult? routerSpeed;

  /// Current browser test step: 'idle' | 'gateway' | 'dns' | 'speed' | 'complete' | 'error'
  final String browserTestStep;

  // ── Agent-provided context (optional inputs) ─────────────────────────
  final double? planSpeedMbps;

  // ── Mesh topology ─────────────────────────────────────────────────────
  /// All mesh nodes (including the main router). Empty = single router, data pending.
  final List<MeshNodeInfo> meshNodes;

  /// Maps client MAC address → deviceId of the node it's connected to.
  final Map<String, String> clientToNodeId;

  // ── Computed values ───────────────────────────────────────────────────
  final List<DeviceScore> deviceScores;
  final Verdict? verdict;

  /// True while speed tests running — verdict card shows "Preliminary" badge.
  final bool verdictIsPreliminary;

  // ── JNAP capability map ───────────────────────────────────────────────
  /// Records which JNAP fields were actually present on this device/firmware.
  /// Keys are [JnapCapability] constants. Value true = field confirmed present.
  /// Used to gate VerdictEngine checks so absent fields produce null (skip)
  /// rather than false all-clears.
  final Map<String, bool> jnapCapabilities;

  // ── Customer journey tracking (V2.0 prep) ─────────────────────────────
  /// Actions the customer has taken this session — restarts, speed tests,
  /// flow navigation. Used for future Guardians support handoff payload.
  final List<JourneyAction> journeyActions;

  // ── Action state ──────────────────────────────────────────────────────
  final bool isRestarting;
  final bool isUpdatingFirmware;
  final String? pingOutput;
  final String? tracerouteOutput;
  final bool isPingRunning;

  final String? errorMessage;

  const InstantVerifyPivotState({
    this.phase = PivotLoadPhase.idle,
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
    this.cpuLoadPctStart,
    this.cpuLoadPctEnd,
    this.jnapCapabilities = const {},
    this.gatewayPing,
    this.dnsCheck,
    this.publicDnsCheck,
    this.configuredDnsReachable,
    this.speedTest,
    this.routerSpeed,
    this.browserTestStep = 'idle',
    this.planSpeedMbps,
    this.meshNodes = const [],
    this.clientToNodeId = const {},
    this.deviceScores = const [],
    this.verdict,
    this.verdictIsPreliminary = true,
    this.journeyActions = const [],
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
    int? cpuLoadPctStart,
    int? cpuLoadPctEnd,
    Map<String, bool>? jnapCapabilities,
    GatewayPingResult? gatewayPing,
    DnsCheckResult? dnsCheck,
    DnsCheckResult? publicDnsCheck,
    bool? configuredDnsReachable,
    SpeedTestResult? speedTest,
    RouterSpeedResult? routerSpeed,
    String? browserTestStep,
    double? planSpeedMbps,
    List<MeshNodeInfo>? meshNodes,
    Map<String, String>? clientToNodeId,
    List<DeviceScore>? deviceScores,
    Verdict? verdict,
    bool? verdictIsPreliminary,
    List<JourneyAction>? journeyActions,
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
      cpuLoadPctStart: cpuLoadPctStart ?? this.cpuLoadPctStart,
      cpuLoadPctEnd: cpuLoadPctEnd ?? this.cpuLoadPctEnd,
      jnapCapabilities: jnapCapabilities ?? this.jnapCapabilities,
      gatewayPing: gatewayPing ?? this.gatewayPing,
      dnsCheck: dnsCheck ?? this.dnsCheck,
      publicDnsCheck: publicDnsCheck ?? this.publicDnsCheck,
      configuredDnsReachable: configuredDnsReachable ?? this.configuredDnsReachable,
      speedTest: speedTest ?? this.speedTest,
      routerSpeed: routerSpeed ?? this.routerSpeed,
      browserTestStep: browserTestStep ?? this.browserTestStep,
      planSpeedMbps: planSpeedMbps ?? this.planSpeedMbps,
      meshNodes: meshNodes ?? this.meshNodes,
      clientToNodeId: clientToNodeId ?? this.clientToNodeId,
      deviceScores: deviceScores ?? this.deviceScores,
      verdict: verdict ?? this.verdict,
      verdictIsPreliminary: verdictIsPreliminary ?? this.verdictIsPreliminary,
      journeyActions: journeyActions ?? this.journeyActions,
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
  String? get routerMac => deviceInfo?['macAddress'] as String?;
  String? get routerFirmware => deviceInfo?['firmwareVersion'] as String?;

  // WAN IP and gateway are nested inside wanConnection in the JNAP response
  String? get wanIpAddress =>
      (wanStatus?['wanConnection'] as Map<String, dynamic>?)?['ipAddress'] as String? ??
      wanStatus?['ipAddress'] as String?; // fallback for older firmware shapes
  String? get wanGateway =>
      (wanStatus?['wanConnection'] as Map<String, dynamic>?)?['gateway'] as String?;
  String? get wanConnectionType => wanStatus?['detectedWANType'] as String?
      ?? wanStatus?['wanType'] as String?;

  /// DNS servers assigned to this router (from GetWANStatus wanConnection).
  /// Filters out empty/0.0.0.0 entries.
  List<String> get wanDnsServers {
    final conn = wanStatus?['wanConnection'] as Map<String, dynamic>?;
    if (conn == null) return [];
    final raw = [
      conn['dnsServer1'] as String?,
      conn['dnsServer2'] as String?,
      conn['dnsServer3'] as String?,
    ];
    return raw
        .whereType<String>()
        .where((s) => s.isNotEmpty && s != '0.0.0.0')
        .toList();
  }

  /// True if IPv6 WAN is connected (from GetWANStatus wanIPv6Status).
  bool get wanIpv6Connected {
    final v6 = wanStatus?['wanIPv6Status'] as String?;
    return v6 == 'Connected' || v6 == 'connected';
  }

  int get twoPointFourGhzCount =>
      clients.where((c) => c.isWireless && c.band.contains('2.4')).length;
  int get fiveGhzCount =>
      clients.where((c) => c.isWireless && !c.band.contains('2.4')).length;

  bool get isMeshNetwork => meshNodes.length > 1;

  /// Count of wireless clients connected to a specific node.
  int clientCountForNode(String deviceId) =>
      clientToNodeId.values.where((id) => id == deviceId).length;

  List<MeshNodeInfo> get weakBackhaulNodes =>
      meshNodes.where((n) => n.hasWeakBackhaul).toList();

  int get issueDeviceCount => deviceScores.where((d) => d.isIssue).length;
  int get atRiskDeviceCount => deviceScores.where((d) => d.isAtRisk).length;
  int get goodDeviceCount => deviceScores.where((d) => d.isGood).length;
  int get wirelessDeviceCount => clients.where((c) => c.isWireless).length;
  int get wiredDeviceCount => clients.where((c) => !c.isWireless).length;

  double get dhcpUtilization =>
      dhcpPoolLimit > 0 ? dhcpLeasesCount / dhcpPoolLimit : 0;

  /// SSID from GetRadioInfo3. Prefers a non-factory SSID if multiple radios exist.
  String? get wifiSsid {
    final radios = radioInfo?['radios'] as List?;
    if (radios == null || radios.isEmpty) return null;
    String? firstSsid;
    for (final radio in radios) {
      final settings =
          (radio as Map<String, dynamic>)['settings'] as Map<String, dynamic>?;
      final ssid = settings?['ssid'] as String?;
      if (ssid == null || ssid.isEmpty) continue;
      firstSsid ??= ssid;
      if (!ssid.startsWith('Linksys')) return ssid;
    }
    return firstSsid;
  }

  /// WPA passphrase of the first radio from GetRadioInfo3.
  String? get wifiPassword {
    final radios = radioInfo?['radios'] as List?;
    if (radios == null || radios.isEmpty) return null;
    final settings =
        (radios.first as Map<String, dynamic>)['settings'] as Map<String, dynamic>?;
    final wpa = settings?['wpaPersonalSettings'] as Map<String, dynamic>?;
    return wpa?['passphrase'] as String?;
  }

  /// True if the MAC address filter (device blocklist) is active.
  bool get isMacFilterEnabled {
    if (macFilter == null) return false;
    final mode = macFilter!['macFilterMode'] as String?;
    return mode != null && mode != 'Disabled';
  }

  /// True if router is configured for WPA3-only (no WPA2 fallback).
  /// Smart home devices with WPA3-only may fail to connect.
  bool get isWpa3Only {
    if (networkSecurity == null) return false;
    return networkSecurity!.values.whereType<String>().any(
          (v) => v.toUpperCase().contains('WPA3') && !v.toUpperCase().contains('WPA2'),
        );
  }

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
        cpuLoadPctStart,
        cpuLoadPctEnd,
        jnapCapabilities,
        gatewayPing,
        dnsCheck,
        publicDnsCheck,
        configuredDnsReachable,
        speedTest,
        routerSpeed,
        browserTestStep,
        planSpeedMbps,
        meshNodes,
        clientToNodeId,
        deviceScores,
        verdict,
        verdictIsPreliminary,
        journeyActions,
        isRestarting,
        isUpdatingFirmware,
        pingOutput,
        tracerouteOutput,
        isPingRunning,
        errorMessage,
      ];
}
