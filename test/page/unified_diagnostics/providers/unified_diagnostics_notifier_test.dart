import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/generated/dns_client.g.dart';
import 'package:privacy_gui/page/speed_test/models/speed_test_state.dart';
import 'package:privacy_gui/page/speed_test/providers/speed_test_notifier.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/unified_diagnostics_notifier.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/unified_diagnostics_service.dart';

class MockUnifiedDiagnosticsService extends Mock
    implements UnifiedDiagnosticsService {}

void main() {
  late MockUnifiedDiagnosticsService mockService;

  setUp(() {
    mockService = MockUnifiedDiagnosticsService();

    // Default session stubs
    when(() => mockService.startSession()).thenAnswer((_) async {});
    when(() => mockService.endSession()).thenAnswer((_) async {});

    // Default DNS stubs for flows that include DNS lookup
    when(() => mockService.nsLookup(any())).thenAnswer(
      (_) async => const NsLookupResult(
        hostName: 'www.google.com',
        status: 'Complete',
        successCount: 1,
        answers: [
          NsLookupAnswer(
            index: 1,
            status: 'Success',
            answerType: 'A',
            hostNameReturned: 'www.google.com',
            ipAddresses: ['142.250.80.46'],
            dnsServerIp: '8.8.8.8',
            responseTimeMs: 15,
          ),
        ],
      ),
    );
    when(() => mockService.getDnsClient()).thenAnswer(
      (_) async => const DnsClient(
        enabled: true,
        status: 'Enabled',
        serverCount: 1,
        servers: [
          DnsServer(
            instancePath: 'Device.DNS.Client.Server.1.',
            address: '8.8.8.8',
            type: 'DHCPv4',
            enabled: true,
            status: 'Enabled',
            alias: '',
            interface_: '',
          ),
        ],
      ),
    );
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        unifiedDiagnosticsServiceProvider.overrideWithValue(mockService),
        // Override speed test provider to avoid real network calls
        speedTestProvider.overrideWith(() => _MockSpeedTestNotifier()),
      ],
    );
    // Keep AutoDispose provider alive for the duration of each test.
    container.listen(unifiedDiagnosticsProvider, (_, __) {});
    return container;
  }

  group('UnifiedDiagnosticsNotifier', () {
    test('initial state is idle', () {
      final container = createContainer();
      final state = container.read(unifiedDiagnosticsProvider);

      expect(state.step, DiagnosticStep.idle);
      expect(state.problemType, isNull);
      expect(state.results, isEmpty);
      container.dispose();
    });

    test('start() transitions to selectProblem', () {
      final container = createContainer();
      final notifier = container.read(unifiedDiagnosticsProvider.notifier);

      notifier.start();

      final state = container.read(unifiedDiagnosticsProvider);
      expect(state.step, DiagnosticStep.selectProblem);
      container.dispose();
    });

    test('cancel() resets state and cleans up session', () async {
      final container = createContainer();
      final notifier = container.read(unifiedDiagnosticsProvider.notifier);

      notifier.start();
      await notifier.cancel();

      final state = container.read(unifiedDiagnosticsProvider);
      expect(state.step, DiagnosticStep.idle);
      verify(() => mockService.endSession()).called(1);
      container.dispose();
    });

    group('No Internet Flow', () {
      test('runs WAN → DHCP → Gateway → DNS → Internet sequence', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        // Mock successful WAN check
        when(() => mockService.checkWanStatus()).thenAnswer(
          (_) async => const WanStatusUIModel(
            status: 'Up',
            ipAddress: '192.168.1.100',
            subnetMask: '255.255.255.0',
            addressingType: 'DHCP',
          ),
        );

        // Mock successful ping operations
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) async => _createPingResult('192.168.1.1'));
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        await notifier.selectProblem(ProblemType.noInternet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.length,
            6); // WAN, DHCP, Gateway, DNS Ping, DNS Lookup, Internet
        expect(state.results.every((r) => r.isOk), isTrue);
        container.dispose();
      });

      test('stops early on WAN down', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus()).thenAnswer(
          (_) async => const WanStatusUIModel(
            status: 'Down',
            ipAddress: '',
            subnetMask: '',
            addressingType: 'DHCP',
          ),
        );

        await notifier.selectProblem(ProblemType.noInternet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.length, 1); // Only WAN
        expect(state.results.first.isError, isTrue);
        expect(state.recommendations, isNotEmpty);
        container.dispose();
      });

      test('skips DHCP for static IP', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus()).thenAnswer(
          (_) async => const WanStatusUIModel(
            status: 'Up',
            ipAddress: '192.168.1.100',
            subnetMask: '255.255.255.0',
            addressingType: 'Static',
          ),
        );

        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) async => _createPingResult('192.168.1.1'));
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        await notifier.selectProblem(ProblemType.noInternet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        final dhcpResult = state.results.firstWhere(
          (r) => r.step == DiagnosticStep.checkingDhcp,
        );
        expect(dhcpResult.isSkipped, isTrue);
        container.dispose();
      });

      test('generates gateway recommendation on ping failure', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus()).thenAnswer(
          (_) async => const WanStatusUIModel(
            status: 'Up',
            ipAddress: '192.168.1.100',
            subnetMask: '255.255.255.0',
            addressingType: 'DHCP',
          ),
        );

        // Gateway ping fails
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) async => _createFailedPingResult('192.168.1.1'));
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        await notifier.selectProblem(ProblemType.noInternet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(
          state.recommendations.any((r) => r.id == 'gateway_unreachable'),
          isTrue,
        );
        container.dispose();
      });
    });

    group('Slow Network Flow', () {
      test('runs SpeedTest → WiFi → Devices sequence', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWifiRadios()).thenAnswer(
          (_) async => [
            const WiFiRadioUIModel(
              instancePath: 'Device.WiFi.Radio.1.',
              band: '2.4GHz',
              channel: 6,
              channelBandwidth: '20MHz',
              transmitPower: 100,
              status: 'Up',
              autoChannel: true,
            ),
          ],
        );

        when(() => mockService.analyzeWifiSignalPerRadio()).thenAnswer(
          (_) async => const WifiSignalPerRadioUIModel(
            radios: [
              RadioSignalStatsUIModel(
                instancePath: 'Device.WiFi.Radio.1.',
                band: '2.4GHz',
                channel: 6,
                status: 'Up',
                clientCount: 2,
                averageRssi: -50,
                minRssi: -60,
              ),
            ],
          ),
        );

        when(() => mockService.checkConnectedDevices()).thenAnswer(
          (_) async => const ConnectedDevicesUIModel(
            totalDevices: 5,
            activeDevices: 3,
            highBandwidthDevices: [],
          ),
        );

        await notifier.selectProblem(ProblemType.slowNetwork);
        // Wait for speed test mock to complete
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        // SpeedTest, WiFi, Devices (traceroute skipped if speed is OK)
        expect(state.results.length, greaterThanOrEqualTo(3));
        container.dispose();
      });

      test('detects high bandwidth devices', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.analyzeWifiSignalPerRadio()).thenAnswer(
          (_) async => const WifiSignalPerRadioUIModel(
            radios: [
              RadioSignalStatsUIModel(
                instancePath: 'Device.WiFi.Radio.1.',
                band: '5GHz',
                channel: 36,
                status: 'Up',
                clientCount: 1,
                averageRssi: -40,
                minRssi: -40,
              ),
            ],
          ),
        );

        when(() => mockService.checkConnectedDevices()).thenAnswer(
          (_) async => const ConnectedDevicesUIModel(
            totalDevices: 10,
            activeDevices: 8,
            highBandwidthDevices: ['MacBook-Pro', 'Gaming-PC'],
          ),
        );

        await notifier.selectProblem(ProblemType.slowNetwork);
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(unifiedDiagnosticsProvider);
        final devicesResult = state.results.firstWhere(
          (r) => r.step == DiagnosticStep.checkingConnectedDevices,
        ) as ConnectedDevicesCheckUIModel;

        expect(devicesResult.totalDevices, 10);
        expect(devicesResult.highBandwidthDevices, isNotEmpty);
        container.dispose();
      });
    });

    group('Session Management', () {
      test('starts session before ping operations', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus()).thenAnswer(
          (_) async => const WanStatusUIModel(
            status: 'Up',
            ipAddress: '192.168.1.100',
            subnetMask: '255.255.255.0',
            addressingType: 'DHCP',
          ),
        );
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) async => _createPingResult('192.168.1.1'));
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        await notifier.selectProblem(ProblemType.noInternet);
        await Future.delayed(Duration.zero);

        verify(() => mockService.startSession()).called(1);
        verify(() => mockService.endSession()).called(1);
        container.dispose();
      });

      test('ends session even on error', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus()).thenAnswer(
          (_) async => const WanStatusUIModel(
            status: 'Up',
            ipAddress: '192.168.1.100',
            subnetMask: '255.255.255.0',
            addressingType: 'DHCP',
          ),
        );
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenThrow(Exception('Network error'));
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        await notifier.selectProblem(ProblemType.noInternet);
        await Future.delayed(Duration.zero);

        // Session should be cleaned up even though gateway ping threw
        verify(() => mockService.endSession()).called(1);
        container.dispose();
      });
    });

    group('Restart', () {
      test('restart() re-runs same problem type', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus()).thenAnswer(
          (_) async => const WanStatusUIModel(
            status: 'Up',
            ipAddress: '192.168.1.100',
            subnetMask: '255.255.255.0',
            addressingType: 'DHCP',
          ),
        );
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) async => _createPingResult('192.168.1.1'));
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        await notifier.selectProblem(ProblemType.noInternet);
        await Future.delayed(Duration.zero);

        // Restart
        await notifier.restart();
        await Future.delayed(Duration.zero);

        // Should have run twice
        verify(() => mockService.checkWanStatus()).called(2);
        container.dispose();
      });
    });
  });
}

PingResult _createPingResult(String host) {
  return PingResult(
    host: host,
    successCount: 3,
    failureCount: 0,
    avgResponseTime: 15,
    minResponseTime: 10,
    maxResponseTime: 20,
    status: 'Complete',
  );
}

PingResult _createFailedPingResult(String host) {
  return PingResult(
    host: host,
    successCount: 0,
    failureCount: 3,
    avgResponseTime: 0,
    minResponseTime: 0,
    maxResponseTime: 0,
    status: 'Complete',
  );
}

class _MockSpeedTestNotifier extends AsyncNotifier<SpeedTestState>
    implements SpeedTestNotifier {
  @override
  Future<SpeedTestState> build() async => const SpeedTestState();

  @override
  void selectServer(SpeedTestServer server) {}

  @override
  Future<void> runSpeedTest() async {
    state = AsyncData(state.requireValue.copyWith(
      step: SpeedTestStep.completed,
      result: const SpeedTestResult(
        serverHost: 'Test Server',
        latencyMs: 20,
        downloadStatus: 'Complete',
        downloadBps: 100000000, // 100 Mbps
        downloadBytes: 100000000,
        downloadDurationMs: 8000,
        uploadStatus: 'NotSupported',
      ),
    ));
  }

  @override
  void reset() {
    state = const AsyncData(SpeedTestState());
  }
}
