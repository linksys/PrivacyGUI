import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/diagnostic_report_service.dart';

void main() {
  const service = DiagnosticReportService();

  group('DiagnosticReportService.buildTextReport', () {
    test('always includes header, date line, and end marker', () {
      const state = UnifiedDiagnosticsState();
      final report = service.buildTextReport(state);

      expect(report, contains('=== Linksys Network Diagnostics Report ==='));
      expect(report, contains('=== End of Report ==='));
      expect(report, contains('Date: '));
      expect(report, contains('Flow: Full Diagnostic'));
    });

    test('flow line reflects each DiagnosticFlow', () {
      const flows = {
        DiagnosticFlow.internet: 'Internet Diagnostics',
        DiagnosticFlow.deviceIssues: 'Device Issues',
        DiagnosticFlow.wifiCoverage: 'WiFi Coverage',
        DiagnosticFlow.meshBackhaul: 'Mesh Backhaul',
        DiagnosticFlow.intermittent: 'Intermittent Connection',
      };
      for (final entry in flows.entries) {
        final state = const UnifiedDiagnosticsState().copyWith(flow: entry.key);
        expect(
          service.buildTextReport(state),
          contains('Flow: ${entry.value}'),
          reason: 'Flow ${entry.key} should render as ${entry.value}',
        );
      }
    });

    test('renders error message when present', () {
      const state =
          UnifiedDiagnosticsState(errorMessage: 'Network unreachable');
      final report = service.buildTextReport(state);
      expect(report, contains('ERROR: Network unreachable'));
    });

    test('renders ping result with severity icon and details', () {
      final ping = PingCheckUIModel(
        step: DiagnosticStep.pingGateway,
        host: '192.168.1.1',
        successCount: 3,
        failureCount: 0,
        avgResponseTime: 5,
        severity: DiagnosticSeverity.ok,
        titleKey: 'ping_ok',
        descriptionKey: 'ping_ok_desc',
      );
      final state = UnifiedDiagnosticsState(results: [ping]);
      final report = service.buildTextReport(state);

      expect(report, contains('--- Diagnostic Results ---'));
      expect(report, contains('[OK] Gateway Ping'));
      expect(report, contains('Host: 192.168.1.1, Latency: 5ms, Success: 3/3'));
    });

    test(
        'renders WAN status, WiFi signal, DHCP pool, devices, DNS, and traceroute',
        () {
      final results = <DiagnosticStepUIModel>[
        WanStatusCheckUIModel(
          status: 'Up',
          ipAddress: '203.0.113.10',
          addressingType: 'DHCP',
          severity: DiagnosticSeverity.ok,
          titleKey: 't',
          descriptionKey: 'd',
        ),
        WifiSignalCheckUIModel(
          rssi: -65,
          channel: 36,
          band: '5GHz',
          connectedDevices: 4,
          severity: DiagnosticSeverity.warning,
          titleKey: 't',
          descriptionKey: 'd',
        ),
        DhcpPoolCheckUIModel(
          dhcpEnabled: true,
          minAddress: '192.168.1.10',
          maxAddress: '192.168.1.99',
          capacity: 90,
          usedLeases: 45,
          totalLeases: 45,
          severity: DiagnosticSeverity.ok,
          titleKey: 't',
          descriptionKey: 'd',
        ),
        DhcpPoolCheckUIModel(
          dhcpEnabled: false,
          minAddress: '',
          maxAddress: '',
          capacity: 0,
          usedLeases: 0,
          totalLeases: 0,
          severity: DiagnosticSeverity.skipped,
          titleKey: 't',
          descriptionKey: 'd',
        ),
        ConnectedDevicesCheckUIModel(
          totalDevices: 12,
          activeDevices: 8,
          highBandwidthDevices: const [],
          severity: DiagnosticSeverity.ok,
          titleKey: 't',
          descriptionKey: 'd',
        ),
        DnsLookupCheckUIModel(
          hostName: 'example.com',
          resolvedIps: const ['93.184.216.34'],
          dnsServerUsed: '8.8.8.8',
          responseTimeMs: 15,
          configuredDnsServers: const ['8.8.8.8'],
          severity: DiagnosticSeverity.ok,
          titleKey: 't',
          descriptionKey: 'd',
        ),
        TracerouteCheckUIModel(
          hops: const [
            TracerouteHopUIModel(
              hopNumber: 1,
              host: 'gw',
              hostAddress: '192.168.1.1',
              avgRoundTrip: 1,
            ),
          ],
          targetHost: 'google.com',
          severity: DiagnosticSeverity.ok,
          titleKey: 't',
          descriptionKey: 'd',
        ),
      ];
      final state = UnifiedDiagnosticsState(results: results);
      final report = service.buildTextReport(state);

      expect(report, contains('Status: Up, IP: 203.0.113.10, Type: DHCP'));
      expect(report, contains('RSSI: -65dBm, Band: 5GHz, Clients: 4'));
      expect(report, contains('Used: 45/90 (50%)'));
      expect(report, contains('DHCP Disabled'));
      expect(report, contains('Total: 12, Active: 8'));
      expect(report, contains('Host: example.com, Resolved: 93.184.216.34'));
      expect(report, contains('Target: google.com, Hops: 1'));
    });

    test('severity icons map correctly', () {
      DiagnosticStepUIModel make(DiagnosticSeverity sev) =>
          DiagnosticStepUIModel(
            step: DiagnosticStep.pingDns,
            severity: sev,
            titleKey: 't',
            descriptionKey: 'd',
          );
      final report = service.buildTextReport(
        UnifiedDiagnosticsState(results: [
          make(DiagnosticSeverity.ok),
          make(DiagnosticSeverity.warning),
          make(DiagnosticSeverity.error),
          make(DiagnosticSeverity.skipped),
        ]),
      );
      expect(report, contains('[OK] DNS Ping'));
      expect(report, contains('[WARN] DNS Ping'));
      expect(report, contains('[FAIL] DNS Ping'));
      expect(report, contains('[SKIP] DNS Ping'));
    });

    test('renders speed test section with download / upload / latency', () {
      final state = const UnifiedDiagnosticsState().copyWith(
        speedTest: const SpeedTestResult(
          downloadStatus: 'Complete',
          downloadBps: 50000000,
          uploadStatus: 'Complete',
          uploadBps: 10000000,
          latencyMs: 12,
        ),
      );
      final report = service.buildTextReport(state);
      expect(report, contains('--- Speed Test ---'));
      expect(report, contains('Download: 50.0 Mbps'));
      expect(report, contains('Upload: 10.0 Mbps'));
      expect(report, contains('Latency: 12 ms'));
    });

    test('omits upload line when uploadStatus is NotSupported', () {
      final state = const UnifiedDiagnosticsState().copyWith(
        speedTest: const SpeedTestResult(
          downloadStatus: 'Complete',
          downloadBps: 25000000,
          uploadStatus: 'NotSupported',
        ),
      );
      final report = service.buildTextReport(state);
      expect(report, contains('Download: 25.0 Mbps'));
      expect(report, isNot(contains('Upload:')));
      expect(report, isNot(contains('Latency:')));
    });

    test('renders recommendations using catalog lookups', () {
      const recs = [
        RecommendationUIModel(
          id: 'wan-down',
          titleKey: 'diagnostics_rec_wan_down_title',
          descriptionKey: 'diagnostics_rec_wan_down_desc',
        ),
      ];
      final state =
          const UnifiedDiagnosticsState().copyWith(recommendations: recs);
      final report = service.buildTextReport(state);
      expect(report, contains('--- Recommendations ---'));
      expect(report, contains('WAN Connection Down'));
      expect(report, contains('Check your modem connection'));
    });

    test('omits recommendations section when none present', () {
      const state = UnifiedDiagnosticsState();
      final report = service.buildTextReport(state);
      expect(report, isNot(contains('--- Recommendations ---')));
    });
  });
}
