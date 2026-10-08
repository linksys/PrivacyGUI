import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';

/// PROTOTYPE-ONLY notifier. Drives the Instant-Test UI entirely off the
/// engine's built-in mock scenarios so the front-end prototypes render with
/// believable data and **never** hit JNAP / the router.
///
/// Retained for reviewer/demo builds. The authenticated device route uses
/// the real notifier until the reviewer explicitly opens this preview.
///
/// Base scenario: D (rich — 3 mesh nodes, ethernet ports, CPU/mem, speed test,
/// verdict findings), augmented to 4+ devices so no device panel reads empty.
class MockInstantVerifyPivotNotifier extends InstantVerifyPivotNotifier {
  MockInstantVerifyPivotNotifier({this.showProgress = false, this.overviewScenario = 3, this.actionScenario = PreviewProbeScenario.healthy});
  final bool showProgress;
  bool _running = false;
  final PreviewProbeScenario actionScenario;
  final int overviewScenario;
  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    // Scenario D = index 3 (router overloaded + mesh issues — richest panels).
    loadMockScenario(overviewScenario);
    // Augment to four devices so My Devices / glance never read empty.
    const extra = DiagnosticClient(
      macAddress: 'AA:BB:CC:AB:CD:EF',
      hostname: 'Office-Printer',
      ipAddress: '192.168.1.110',
      band: '2.4 GHz',
      signalDecibels: -75,
      txRateMbps: 24,
      rxRateMbps: 18,
      isWireless: true,
    );
    final clients = [...state.clients, extra];
    state = state.copyWith(
      clients: clients,
      deviceScores: clients.map(DeviceScore.compute).toList(),
    );
  }

  /// The pivot auto-calls fetch() on first frame — intercept it to load mock
  /// data instead of issuing JNAP calls.
  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {
    if (_running) return;
    _ensureLoaded();
    if (!showProgress) return;
    _running = true;
    var disposed = false;
    ref.onDispose(() => disposed = true);
    final result = state;
    state = const InstantVerifyPivotState(phase: PivotLoadPhase.loading);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (disposed) return;
    state = InstantVerifyPivotState(phase: PivotLoadPhase.jnapLoaded,
        browserTestStep: 'dns', deviceInfo: result.deviceInfo,
        wanStatus: result.wanStatus, clients: result.clients,
        deviceScores: result.deviceScores,
        gatewayPing: const GatewayPingResult(reachable: true));
    await Future<void>.delayed(const Duration(seconds: 2));
    if (disposed) return;
    state = state.copyWith(browserTestStep: 'speed:download', dnsCheck: result.dnsCheck);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (disposed) return;
    state = actionScenario == PreviewProbeScenario.probeError
        ? const InstantVerifyPivotState(phase: PivotLoadPhase.complete,
            browserTestStep: 'error', errorMessage: 'Simulated check failure')
        : result;
    _running = false;
  }

  // ── Neutralize the interactive router actions (no live calls in mock) ──────

  @override
  Future<void> startPing(String host) async {
    state = state.copyWith(
      isPingRunning: false,
      pingOutput: 'PING $host: 56 data bytes\n'
          '64 bytes from $host: seq=0 ttl=56 time=3.1 ms\n'
          '64 bytes from $host: seq=1 ttl=56 time=2.8 ms\n'
          '64 bytes from $host: seq=2 ttl=56 time=3.0 ms\n'
          '--- $host ping statistics ---\n'
          '3 packets transmitted, 3 received, 0% packet loss\n'
          '(mock data — prototype mode)',
    );
  }

  @override
  Future<void> startTraceroute(String host) async {
    state = state.copyWith(
      tracerouteOutput: 'traceroute to $host, 30 hops max\n'
          ' 1  192.168.1.1  1.2 ms\n'
          ' 2  10.83.71.254  3.4 ms\n'
          ' 3  $host  12.0 ms\n'
          '(mock data — prototype mode)',
    );
  }

  @override
  Future<void> restartRouter() async {
    if (actionScenario == PreviewProbeScenario.restartRejected) throw StateError('Simulated rejected restart');
    state = state.copyWith(hasRestartedThisSession: true);
  }

  @override
  Future<void> triggerFirmwareUpdate() async {}
  @override
  Future<void> disableMacFilter() async {}
  @override
  Future<void> setGuestNetworkEnabled(bool enabled) async {}
  @override
  Future<void> deauthClient(String macAddress) async {
    if (actionScenario == PreviewProbeScenario.reconnectRejected) throw StateError('Simulated rejected reconnect');
  }
  @override
  Future<bool> changeRadioChannel(String radioID, int channel) async => false;
  @override
  Future<ChannelOptimizeResult> optimizeChannels() async =>
      const ChannelOptimizeResult(status: ChannelOptimizeStatus.alreadyOptimal);
}

/// Every browser diagnostic in the preview uses fixed data, including calls
/// made directly by a workflow rather than through the pivot notifier.
enum PreviewProbeScenario {
  healthy, gatewayDown, internetDown, dnsFailure, probeError,
  speedError, slowSpeed, laggySpeed, monitorDrops, speedAfterRestartError, restartRejected, reconnectRejected,
}

class MockBrowserDiagnosticService extends BrowserDiagnosticService {
  MockBrowserDiagnosticService({this.scenario = PreviewProbeScenario.healthy});
  final PreviewProbeScenario scenario;
  int _speedRuns = 0;
  @override
  Future<GatewayPingResult> pingGateway() async {
    if (scenario == PreviewProbeScenario.probeError) {
      throw StateError('Simulated unavailable connection probe');
    }
    return GatewayPingResult(
        reachable: scenario != PreviewProbeScenario.gatewayDown &&
            scenario != PreviewProbeScenario.monitorDrops,
        latencyMs: 2);
  }
  @override
  Future<GatewayPingResult> pingPublicIp() async =>
      GatewayPingResult(reachable: scenario != PreviewProbeScenario.internetDown, latencyMs: 18);
  @override
  Future<DnsCheckResult> checkDns() async =>
      DnsCheckResult(resolved: scenario != PreviewProbeScenario.dnsFailure, latencyMs: 12);
  @override
  Future<DnsCheckResult> checkPublicDns() async =>
      const DnsCheckResult(resolved: true, latencyMs: 12);
  @override
  Future<SpeedTestResult> runInternetSpeedTest(
          {void Function(String)? onStep}) async {
    _speedRuns++;
    if (scenario == PreviewProbeScenario.speedError ||
        (scenario == PreviewProbeScenario.speedAfterRestartError && _speedRuns > 1)) {
      throw StateError('Simulated unavailable speed check');
    }
    return SpeedTestResult(
        downloadMbps: scenario == PreviewProbeScenario.slowSpeed ? 3 : 120,
        uploadMbps: 45,
        latencyMs: scenario == PreviewProbeScenario.laggySpeed ? 148 : 18,
        jitterMs: scenario == PreviewProbeScenario.laggySpeed ? 40 : 2);
  }
  @override
  Future<RouterSpeedResult> runRouterSpeedTest(
          {void Function(String)? onStep}) async =>
      const RouterSpeedResult(latencyMs: 2, throughputMbps: 240);
}
