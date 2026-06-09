import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/device_score.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/manual_tools_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/unified_diagnostics_service.dart';

// =============================================================================
// Idle — start screen before any diagnostic
// =============================================================================

const idleState = UnifiedDiagnosticsState();

// =============================================================================
// Pre-qualifying — checking connection
// =============================================================================

const preQualifyingState = UnifiedDiagnosticsState(
  step: DiagnosticStep.preQualifying,
);

// =============================================================================
// Flow selection — internet OK
// =============================================================================

const selectFlowInternetOkState = UnifiedDiagnosticsState(
  step: DiagnosticStep.selectFlow,
  preQualifierResult: PreQualifierResult.internetOk,
);

// =============================================================================
// Flow selection — WAN down
// =============================================================================

const selectFlowWanDownState = UnifiedDiagnosticsState(
  step: DiagnosticStep.selectFlow,
  preQualifierResult: PreQualifierResult.wanDownNoIp,
);

// =============================================================================
// Flow selection — DNS failure
// =============================================================================

const selectFlowDnsFailureState = UnifiedDiagnosticsState(
  step: DiagnosticStep.selectFlow,
  preQualifierResult: PreQualifierResult.dnsFailure,
);

// =============================================================================
// Flow selection — internet slow
// =============================================================================

const selectFlowSlowState = UnifiedDiagnosticsState(
  step: DiagnosticStep.selectFlow,
  preQualifierResult: PreQualifierResult.internetSlow,
);

// =============================================================================
// Running — WAN check in progress
// =============================================================================

const runningWanCheckState = UnifiedDiagnosticsState(
  step: DiagnosticStep.checkingWanStatus,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — DHCP check
// =============================================================================

const runningDhcpState = UnifiedDiagnosticsState(
  step: DiagnosticStep.checkingDhcp,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — DHCP pool check
// =============================================================================

const runningDhcpPoolState = UnifiedDiagnosticsState(
  step: DiagnosticStep.checkingDhcpPool,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — ping gateway
// =============================================================================

const runningPingGatewayState = UnifiedDiagnosticsState(
  step: DiagnosticStep.pingGateway,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — ping DNS
// =============================================================================

const runningPingDnsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.pingDns,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — ping internet
// =============================================================================

const runningPingInternetState = UnifiedDiagnosticsState(
  step: DiagnosticStep.pingInternet,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — DNS lookup
// =============================================================================

const runningDnsLookupState = UnifiedDiagnosticsState(
  step: DiagnosticStep.dnsLookup,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — speed test in progress
// =============================================================================

const runningSpeedTestState = UnifiedDiagnosticsState(
  step: DiagnosticStep.runningSpeedTest,
  flow: DiagnosticFlow.internet,
  progress: 0.45,
);

// =============================================================================
// Running — WiFi signal check
// =============================================================================

const runningWifiSignalState = UnifiedDiagnosticsState(
  step: DiagnosticStep.checkingWifiSignal,
  flow: DiagnosticFlow.wifiCoverage,
);

// =============================================================================
// Running — connected devices check
// =============================================================================

const runningConnectedDevicesState = UnifiedDiagnosticsState(
  step: DiagnosticStep.checkingConnectedDevices,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — traceroute
// =============================================================================

const runningTracerouteState = UnifiedDiagnosticsState(
  step: DiagnosticStep.runningTraceroute,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Running — mesh backhaul check
// =============================================================================

const runningMeshBackhaulState = UnifiedDiagnosticsState(
  step: DiagnosticStep.checkingMeshBackhaul,
  flow: DiagnosticFlow.meshBackhaul,
);

// =============================================================================
// Running — analyzing
// =============================================================================

const runningAnalyzingState = UnifiedDiagnosticsState(
  step: DiagnosticStep.analyzing,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Results — internet flow with mixed results
// =============================================================================

final internetResultsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.internet,
  preQualifierResult: PreQualifierResult.internetOk,
  results: [
    WanStatusCheckUIModel(
      status: 'Up',
      ipAddress: '192.168.1.100',
      addressingType: 'DHCP',
      severity: DiagnosticSeverity.ok,
      titleKey: 'WAN Status',
      descriptionKey: 'WAN interface is up with valid IP',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingGateway,
      host: '192.168.1.1',
      successCount: 3,
      failureCount: 0,
      avgResponseTime: 2,
      severity: DiagnosticSeverity.ok,
      titleKey: 'Gateway Ping',
      descriptionKey: 'Gateway reachable (avg 2ms)',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingDns,
      host: '8.8.8.8',
      successCount: 3,
      failureCount: 0,
      avgResponseTime: 15,
      severity: DiagnosticSeverity.ok,
      titleKey: 'DNS Ping',
      descriptionKey: 'DNS servers reachable (avg 15ms)',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingInternet,
      host: 'google.com',
      successCount: 2,
      failureCount: 1,
      avgResponseTime: 45,
      severity: DiagnosticSeverity.warning,
      titleKey: 'Internet Ping',
      descriptionKey: 'Intermittent packet loss detected (33%)',
    ),
  ],
  speedTest: const SpeedTestResult(
    serverHost: 'speedtest.tokyo2.linode.com',
    latencyMs: 12,
    downloadStatus: 'Complete',
    downloadBps: 95000000,
    downloadBytes: 104857600,
    downloadDurationMs: 8800,
    uploadStatus: 'Complete',
    uploadBps: 48000000,
    uploadBytes: 52428800,
    uploadDurationMs: 8700,
  ),
  recommendations: const [
    RecommendationUIModel(
      id: 'check_isp',
      titleKey: 'Check ISP Connection',
      descriptionKey: 'Intermittent packet loss may indicate an ISP issue',
      priority: 1,
    ),
  ],
);

// =============================================================================
// Results — all OK (no issues found)
// =============================================================================

final allOkResultsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.internet,
  preQualifierResult: PreQualifierResult.internetOk,
  results: [
    WanStatusCheckUIModel(
      status: 'Up',
      ipAddress: '203.0.113.42',
      addressingType: 'DHCP',
      severity: DiagnosticSeverity.ok,
      titleKey: 'WAN Status',
      descriptionKey: 'WAN interface is up with valid IP',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingGateway,
      host: '192.168.1.1',
      successCount: 5,
      failureCount: 0,
      avgResponseTime: 1,
      severity: DiagnosticSeverity.ok,
      titleKey: 'Gateway Ping',
      descriptionKey: 'Gateway reachable (avg 1ms)',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingDns,
      host: '8.8.8.8',
      successCount: 5,
      failureCount: 0,
      avgResponseTime: 8,
      severity: DiagnosticSeverity.ok,
      titleKey: 'DNS Ping',
      descriptionKey: 'DNS servers reachable (avg 8ms)',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingInternet,
      host: 'google.com',
      successCount: 5,
      failureCount: 0,
      avgResponseTime: 12,
      severity: DiagnosticSeverity.ok,
      titleKey: 'Internet Ping',
      descriptionKey: 'Internet reachable (avg 12ms)',
    ),
    DnsLookupCheckUIModel(
      hostName: 'www.google.com',
      resolvedIps: const ['142.250.196.68'],
      dnsServerUsed: '8.8.8.8',
      responseTimeMs: 15,
      configuredDnsServers: const ['8.8.8.8', '8.8.4.4'],
      severity: DiagnosticSeverity.ok,
      titleKey: 'DNS Lookup',
      descriptionKey: 'Name resolution working (15ms)',
    ),
  ],
  speedTest: const SpeedTestResult(
    serverHost: 'speedtest.tokyo2.linode.com',
    latencyMs: 8,
    downloadStatus: 'Complete',
    downloadBps: 250000000,
    downloadBytes: 104857600,
    downloadDurationMs: 3350,
    uploadStatus: 'Complete',
    uploadBps: 120000000,
    uploadBytes: 52428800,
    uploadDurationMs: 3500,
  ),
);

// =============================================================================
// Results — DNS lookup failure
// =============================================================================

final dnsLookupFailureResultsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.internet,
  preQualifierResult: PreQualifierResult.dnsFailure,
  results: [
    WanStatusCheckUIModel(
      status: 'Up',
      ipAddress: '192.168.1.100',
      addressingType: 'DHCP',
      severity: DiagnosticSeverity.ok,
      titleKey: 'WAN Status',
      descriptionKey: 'WAN interface is up with valid IP',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingGateway,
      host: '192.168.1.1',
      successCount: 3,
      failureCount: 0,
      avgResponseTime: 2,
      severity: DiagnosticSeverity.ok,
      titleKey: 'Gateway Ping',
      descriptionKey: 'Gateway reachable (avg 2ms)',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingDns,
      host: '8.8.8.8',
      successCount: 0,
      failureCount: 3,
      avgResponseTime: 0,
      severity: DiagnosticSeverity.error,
      titleKey: 'DNS Ping',
      descriptionKey: 'DNS servers unreachable — all packets lost',
    ),
    DnsLookupCheckUIModel(
      hostName: 'www.google.com',
      resolvedIps: const [],
      dnsServerUsed: '8.8.8.8',
      responseTimeMs: 0,
      configuredDnsServers: const ['8.8.8.8', '8.8.4.4'],
      severity: DiagnosticSeverity.error,
      titleKey: 'DNS Lookup',
      descriptionKey: 'Name resolution failed — no response from DNS servers',
    ),
  ],
  recommendations: const [
    RecommendationUIModel(
      id: 'change_dns',
      titleKey: 'Change DNS Servers',
      descriptionKey:
          'Current DNS servers are unreachable. Try switching to 1.1.1.1 or 9.9.9.9',
      priority: 0,
      actionId: 'changeDns',
    ),
    RecommendationUIModel(
      id: 'restart_modem',
      titleKey: 'Restart Modem',
      descriptionKey: 'Power cycle your modem to re-establish ISP connection',
      priority: 1,
    ),
  ],
);

// =============================================================================
// Results — traceroute with slow hops
// =============================================================================

final tracerouteResultsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.internet,
  preQualifierResult: PreQualifierResult.internetSlow,
  results: [
    WanStatusCheckUIModel(
      status: 'Up',
      ipAddress: '192.168.1.100',
      addressingType: 'DHCP',
      severity: DiagnosticSeverity.ok,
      titleKey: 'WAN Status',
      descriptionKey: 'WAN interface is up with valid IP',
    ),
    TracerouteCheckUIModel(
      targetHost: 'google.com',
      hops: const [
        TracerouteHopUIModel(
          hopNumber: 1,
          host: 'router.local',
          hostAddress: '192.168.1.1',
          avgRoundTrip: 2,
        ),
        TracerouteHopUIModel(
          hopNumber: 2,
          host: 'isp-gw.net',
          hostAddress: '10.0.0.1',
          avgRoundTrip: 15,
        ),
        TracerouteHopUIModel(
          hopNumber: 3,
          host: '',
          hostAddress: '172.16.0.1',
          avgRoundTrip: 350,
        ),
        TracerouteHopUIModel(
          hopNumber: 4,
          host: 'core-router.isp.net',
          hostAddress: '172.16.0.5',
          avgRoundTrip: 280,
        ),
        TracerouteHopUIModel(
          hopNumber: 5,
          host: 'dns.google',
          hostAddress: '8.8.8.8',
          avgRoundTrip: 45,
        ),
      ],
      severity: DiagnosticSeverity.warning,
      titleKey: 'Traceroute',
      descriptionKey: '2 slow hops detected (>200ms) at ISP level',
    ),
  ],
  recommendations: const [
    RecommendationUIModel(
      id: 'contact_isp',
      titleKey: 'Contact ISP',
      descriptionKey:
          'High latency detected at ISP hops — likely congestion or routing issue',
      priority: 0,
    ),
  ],
);

// =============================================================================
// Results — WiFi coverage flow
// =============================================================================

final wifiCoverageResultsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.wifiCoverage,
  results: [
    WifiSignalCheckUIModel(
      rssi: -72,
      channel: 36,
      band: '5GHz',
      connectedDevices: 8,
      radios: const [
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.1',
          band: '2.4GHz',
          channel: 6,
          status: 'Up',
          clientCount: 5,
          averageRssi: -65,
          minRssi: -78,
        ),
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.2',
          band: '5GHz',
          channel: 36,
          status: 'Up',
          clientCount: 3,
          averageRssi: -72,
          minRssi: -82,
        ),
      ],
      severity: DiagnosticSeverity.warning,
      titleKey: 'WiFi Signal',
      descriptionKey: 'Weak signal detected on 5GHz band (avg -72 dBm)',
    ),
    WifiCoverageCheckUIModel(
      totalWirelessDevices: 8,
      weakSignalDevices: const ['Living Room TV', 'Bedroom Laptop'],
      averageSignalStrength: -68,
      radios: const [
        WiFiRadioUIModel(
          instancePath: 'Device.WiFi.Radio.1',
          band: '2.4GHz',
          channel: 6,
          channelBandwidth: '20MHz',
          transmitPower: 100,
          status: 'Up',
          autoChannel: true,
        ),
        WiFiRadioUIModel(
          instancePath: 'Device.WiFi.Radio.2',
          band: '5GHz',
          channel: 36,
          channelBandwidth: '80MHz',
          transmitPower: 100,
          status: 'Up',
          autoChannel: true,
        ),
      ],
      severity: DiagnosticSeverity.warning,
      titleKey: 'WiFi Coverage',
      descriptionKey: '2 devices with weak signal detected',
    ),
  ],
  recommendations: const [
    RecommendationUIModel(
      id: 'add_node',
      titleKey: 'Add a Mesh Node',
      descriptionKey:
          'Weak signal devices may benefit from an additional mesh node',
      priority: 0,
    ),
    RecommendationUIModel(
      id: 'move_router',
      titleKey: 'Reposition Router',
      descriptionKey: 'Move the router to a more central location',
      priority: 1,
    ),
  ],
);

// =============================================================================
// Results — mesh backhaul flow
// =============================================================================

final meshBackhaulResultsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.meshBackhaul,
  results: [
    MeshBackhaulCheckUIModel(
      nodes: const [
        MeshNodeBackhaulUIModel(
          nodeId: 'AA:BB:CC:DD:EE:01',
          label: 'Living Room Node',
          mediaType: 'Wi-Fi',
          linkType: 'Wi-Fi',
          phyRateMbps: 450,
          lastUplinkRateKbps: 380,
          lastDownlinkRateKbps: 400,
          signalStrengthDbm: -55,
          isController: false,
          severity: MeshBackhaulSeverity.healthy,
        ),
        MeshNodeBackhaulUIModel(
          nodeId: 'AA:BB:CC:DD:EE:02',
          label: 'Bedroom Node',
          mediaType: 'Wi-Fi',
          linkType: 'Wi-Fi',
          phyRateMbps: 120,
          lastUplinkRateKbps: 85,
          lastDownlinkRateKbps: 90,
          signalStrengthDbm: -78,
          isController: false,
          severity: MeshBackhaulSeverity.poor,
        ),
        MeshNodeBackhaulUIModel(
          nodeId: 'AA:BB:CC:DD:EE:03',
          label: 'Office Node',
          mediaType: 'Ethernet',
          linkType: 'Ethernet',
          phyRateMbps: 1000,
          lastUplinkRateKbps: 940,
          lastDownlinkRateKbps: 950,
          signalStrengthDbm: 0,
          isController: false,
          severity: MeshBackhaulSeverity.healthy,
        ),
      ],
      severity: DiagnosticSeverity.warning,
      titleKey: 'Mesh Backhaul',
      descriptionKey: '1 node with poor wireless backhaul (Bedroom Node)',
    ),
  ],
  recommendations: const [
    RecommendationUIModel(
      id: 'move_node',
      titleKey: 'Move Bedroom Node Closer',
      descriptionKey:
          'Signal is weak (-78 dBm). Move the node closer to the controller or use wired backhaul',
      priority: 0,
    ),
  ],
);

// =============================================================================
// Results — device issues flow
// =============================================================================

final deviceIssuesResultsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.deviceIssues,
  results: [
    DeviceIssuesCheckUIModel(
      totalDevices: 12,
      devicesWithIssues: 3,
      weakSignalDevices: const ['Smart TV', 'Tablet'],
      lowDataRateDevices: const ['Old Laptop'],
      deviceScores: const [
        DeviceScoreUIModel(
          macAddress: 'AA:BB:CC:11:22:33',
          name: 'Smart TV',
          rssiDbm: -82,
          downlinkKbps: 15000,
        ),
        DeviceScoreUIModel(
          macAddress: 'AA:BB:CC:44:55:66',
          name: 'Tablet',
          rssiDbm: -75,
          downlinkKbps: 45000,
        ),
        DeviceScoreUIModel(
          macAddress: 'AA:BB:CC:77:88:99',
          name: 'Old Laptop',
          rssiDbm: -60,
          downlinkKbps: 8000,
        ),
      ],
      severity: DiagnosticSeverity.warning,
      titleKey: 'Device Issues',
      descriptionKey: '3 devices with connectivity issues detected',
    ),
  ],
  recommendations: const [
    RecommendationUIModel(
      id: 'move_tv',
      titleKey: 'Move Smart TV Closer',
      descriptionKey: 'Very weak signal (-82 dBm) — consider wired connection',
      priority: 0,
    ),
    RecommendationUIModel(
      id: 'update_laptop',
      titleKey: 'Update Old Laptop WiFi Driver',
      descriptionKey: 'Low data rate may indicate outdated WiFi adapter',
      priority: 1,
    ),
  ],
);

// =============================================================================
// Results — multiple recommendations
// =============================================================================

final multipleRecommendationsState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.internet,
  preQualifierResult: PreQualifierResult.wanDownNoIp,
  results: [
    WanStatusCheckUIModel(
      status: 'Down',
      ipAddress: '',
      addressingType: 'DHCP',
      severity: DiagnosticSeverity.error,
      titleKey: 'WAN Status',
      descriptionKey: 'WAN interface is DOWN — no IP address assigned',
    ),
    DhcpPoolCheckUIModel(
      dhcpEnabled: true,
      minAddress: '192.168.1.100',
      maxAddress: '192.168.1.200',
      capacity: 100,
      usedLeases: 95,
      totalLeases: 100,
      severity: DiagnosticSeverity.warning,
      titleKey: 'DHCP Pool',
      descriptionKey: 'DHCP pool near capacity (95/100 leases used)',
    ),
    PingCheckUIModel(
      step: DiagnosticStep.pingGateway,
      host: '192.168.1.1',
      successCount: 0,
      failureCount: 5,
      avgResponseTime: 0,
      severity: DiagnosticSeverity.error,
      titleKey: 'Gateway Ping',
      descriptionKey: 'Gateway unreachable — all packets lost',
    ),
  ],
  recommendations: const [
    RecommendationUIModel(
      id: 'restart_modem',
      titleKey: 'Restart Modem',
      descriptionKey: 'Power cycle your modem to re-establish WAN connection',
      priority: 0,
      actionId: 'restartModem',
    ),
    RecommendationUIModel(
      id: 'check_cable',
      titleKey: 'Check WAN Cable',
      descriptionKey: 'Ensure the WAN cable is securely connected',
      priority: 1,
    ),
    RecommendationUIModel(
      id: 'expand_dhcp',
      titleKey: 'Expand DHCP Pool',
      descriptionKey:
          'DHCP pool is nearly exhausted — consider expanding range',
      priority: 2,
      actionId: 'expandDhcpPool',
    ),
    RecommendationUIModel(
      id: 'contact_isp',
      titleKey: 'Contact ISP',
      descriptionKey: 'If issue persists after modem restart, contact your ISP',
      priority: 3,
    ),
  ],
);

// =============================================================================
// Completed — diagnostic done
// =============================================================================

const completedState = UnifiedDiagnosticsState(
  step: DiagnosticStep.completed,
  flow: DiagnosticFlow.internet,
);

// =============================================================================
// Error — diagnostic failed
// =============================================================================

const errorState = UnifiedDiagnosticsState(
  step: DiagnosticStep.showingResults,
  flow: DiagnosticFlow.internet,
  errorMessage: 'Connection timed out — unable to reach diagnostic service',
);

// =============================================================================
// Manual tools — Ping tab (idle)
// =============================================================================

const manualToolsPingIdleState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  host: '8.8.8.8',
  pingCount: 3,
);

// =============================================================================
// Manual tools — Ping tab with result
// =============================================================================

const manualToolsPingResultState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  status: DiagnosticStatus.completed,
  host: '8.8.8.8',
  pingCount: 3,
  pingResult: PingResult(
    host: '8.8.8.8',
    successCount: 3,
    failureCount: 0,
    avgResponseTime: 12,
    minResponseTime: 10,
    maxResponseTime: 15,
    status: 'Complete',
  ),
);

// =============================================================================
// Manual tools — Traceroute tab (idle)
// =============================================================================

const manualToolsTracerouteIdleState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.traceroute,
  host: 'google.com',
  maxHops: 30,
);

// =============================================================================
// Manual tools — Traceroute tab with result
// =============================================================================

const manualToolsTracerouteResultState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.traceroute,
  status: DiagnosticStatus.completed,
  host: 'google.com',
  maxHops: 30,
  tracerouteResult: TracerouteResult(
    host: 'google.com',
    status: 'Complete',
    hops: [
      TracerouteHop(
        hopNumber: 1,
        host: 'router.local',
        hostAddress: '192.168.1.1',
        rtTimes: [1, 1, 2],
      ),
      TracerouteHop(
        hopNumber: 2,
        host: 'isp-gw.net',
        hostAddress: '10.0.0.1',
        rtTimes: [5, 6, 5],
      ),
      TracerouteHop(
        hopNumber: 3,
        host: '',
        hostAddress: '172.16.0.1',
        rtTimes: [10, 12, 11],
      ),
      TracerouteHop(
        hopNumber: 4,
        host: 'dns.google',
        hostAddress: '8.8.8.8',
        rtTimes: [14, 13, 14],
      ),
    ],
  ),
);

// =============================================================================
// Manual tools — NS Lookup tab (idle)
// =============================================================================

const manualToolsNsLookupIdleState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.nsLookup,
  host: 'google.com',
  dnsServer: '8.8.8.8',
);

// =============================================================================
// Manual tools — NS Lookup tab with result
// =============================================================================

const manualToolsNsLookupResultState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.nsLookup,
  status: DiagnosticStatus.completed,
  host: 'google.com',
  dnsServer: '8.8.8.8',
  nsLookupResult: NsLookupResult(
    hostName: 'google.com',
    status: 'Complete',
    successCount: 1,
    answers: [
      NsLookupAnswer(
        index: 1,
        status: 'Success',
        answerType: 'A',
        hostNameReturned: 'google.com',
        ipAddresses: ['142.250.196.68', '142.250.196.69'],
        dnsServerIp: '8.8.8.8',
        responseTimeMs: 15,
      ),
      NsLookupAnswer(
        index: 2,
        status: 'Success',
        answerType: 'AAAA',
        hostNameReturned: 'google.com',
        ipAddresses: ['2404:6800:4004:820::200e'],
        dnsServerIp: '8.8.8.8',
        responseTimeMs: 18,
      ),
    ],
  ),
);

// =============================================================================
// Manual tools — Ping running
// =============================================================================

const manualToolsPingRunningState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  status: DiagnosticStatus.running,
  host: '8.8.8.8',
  pingCount: 5,
);

// =============================================================================
// Manual tools — error state
// =============================================================================

const manualToolsErrorState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  status: DiagnosticStatus.error,
  host: '192.168.99.99',
  pingCount: 3,
  errorMessage: 'Ping timed out — no response from 192.168.99.99',
);
