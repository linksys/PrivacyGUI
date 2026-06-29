import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';

/// PROTOTYPE-ONLY notifier. Drives the Instant-Test UI entirely off the
/// engine's built-in mock scenarios so the front-end prototypes render with
/// believable data and **never** hit JNAP / the router.
///
/// Lives on the throwaway `proto/instant-test-frontend-explore` branch — not
/// for the shipping JNAP branch.
///
/// Base scenario: D (rich — 3 mesh nodes, ethernet ports, CPU/mem, speed test,
/// verdict findings), augmented to 4+ devices so no device panel reads empty.
class MockInstantVerifyPivotNotifier extends InstantVerifyPivotNotifier {
  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    // Scenario D = index 3 (router overloaded + mesh issues — richest panels).
    loadMockScenario(3);
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
    _ensureLoaded();
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
    // no-op in prototype mode
  }
}
