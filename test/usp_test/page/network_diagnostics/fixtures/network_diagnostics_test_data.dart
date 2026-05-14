import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/page/network_diagnostics/models/network_diagnostics_ui_model.dart';

// =============================================================================
// Idle state — no diagnostic run yet, host entered
// =============================================================================

const idleState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  status: DiagnosticStatus.idle,
  host: '8.8.8.8',
  pingCount: 3,
  maxHops: 30,
);

// =============================================================================
// Running state — diagnostic in progress
// =============================================================================

const runningPingState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  status: DiagnosticStatus.running,
  host: '8.8.8.8',
  pingCount: 3,
  maxHops: 30,
);

// =============================================================================
// Ping completed with results
// =============================================================================

const pingResultData = PingResult(
  host: '8.8.8.8',
  successCount: 3,
  failureCount: 0,
  avgResponseTime: 12,
  minResponseTime: 10,
  maxResponseTime: 15,
  status: 'Complete',
);

const pingCompletedState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  status: DiagnosticStatus.completed,
  host: '8.8.8.8',
  pingCount: 3,
  maxHops: 30,
  pingResult: pingResultData,
);

// =============================================================================
// Traceroute completed with results
// =============================================================================

const tracerouteHops = [
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
];

const tracerouteResultData = TracerouteResult(
  host: '8.8.8.8',
  status: 'Complete',
  hops: tracerouteHops,
);

const tracerouteCompletedState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.traceroute,
  status: DiagnosticStatus.completed,
  host: '8.8.8.8',
  pingCount: 3,
  maxHops: 30,
  tracerouteResult: tracerouteResultData,
);

// =============================================================================
// Diagnostic error — run failed with error message
// =============================================================================

const diagnosticErrorState = NetworkDiagnosticsState(
  activeTab: DiagnosticType.ping,
  status: DiagnosticStatus.error,
  host: '192.168.99.99',
  pingCount: 3,
  maxHops: 30,
  errorMessage: 'Ping timed out — no response from 192.168.99.99',
);
