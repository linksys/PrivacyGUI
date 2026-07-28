import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/generated/dns_client.g.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/device_score.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/speed_test_notifier.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/unified_diagnostics_notifier.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/unified_diagnostics_service.dart';

class _MockUnifiedDiagnosticsService extends Mock
    implements UnifiedDiagnosticsService {}

class _MockExecutor extends Mock implements NetworkDiagnosticsExecutor {}

class _MockScope extends Mock implements DiagnosticScope {}

void main() {
  late _MockUnifiedDiagnosticsService mockService;
  late _MockExecutor mockExecutor;
  late _MockScope mockScope;

  setUp(() {
    mockService = _MockUnifiedDiagnosticsService();
    mockExecutor = _MockExecutor();
    mockScope = _MockScope();

    // Default scope lifecycle stubs
    when(() => mockExecutor.acquireScope(
          referencePaths: any(named: 'referencePaths'),
        )).thenAnswer((_) async => mockScope);
    when(() => mockScope.isReleased).thenReturn(false);
    when(() => mockScope.release()).thenAnswer((_) async {});

    // attachScope is invoked by the notifier whenever a scope is acquired
    when(() => mockService.attachScope(any())).thenReturn(null);

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

    // Default DHCP pool stub for internet flow
    when(() => mockService.checkDhcpPool()).thenAnswer(
      (_) async => const DhcpPoolUsageUIModel(
        enabled: true,
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.149',
        capacity: 50,
        usedLeases: 5,
        totalLeases: 5,
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(_FakeScope());
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        unifiedDiagnosticsServiceProvider.overrideWithValue(mockService),
        networkDiagnosticsExecutorProvider.overrideWithValue(mockExecutor),
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
      expect(state.flow, isNull);
      expect(state.results, isEmpty);
      container.dispose();
    });

    test('cancel() resets state and releases scope if acquired', () async {
      final container = createContainer();
      final notifier = container.read(unifiedDiagnosticsProvider.notifier);

      await notifier.cancel();

      final state = container.read(unifiedDiagnosticsProvider);
      expect(state.step, DiagnosticStep.idle);
      // No scope was acquired in this flow, so release() must NOT be called.
      verifyNever(() => mockScope.release());
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

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        // WAN, DHCP Pool, Gateway, DNS Ping, DNS Lookup, Internet.
        // Speed test disabled: blocked by FW support (#857).
        expect(state.results.length, 6);
        expect(state.results.every((r) => r.isOk), isTrue);
        container.dispose();
      });

      test('records WAN error result and continues flow', () async {
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
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) async => _createFailedPingResult('192.168.1.1'));
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createFailedPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createFailedPingResult('1.1.1.1'));

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        // Flow no longer early-stops; all checks run and the WAN-down result
        // is preserved in the results list.
        final wanResult = state.results.firstWhere(
          (r) => r.step == DiagnosticStep.checkingWanStatus,
        );
        expect(wanResult.isError, isTrue);
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

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        // New flow no longer probes DHCP lease — only checks the LAN-side DHCP
        // pool, which is independent of WAN addressing type.
        expect(
          state.results.any((r) => r.step == DiagnosticStep.checkingDhcp),
          isFalse,
        );
        expect(
          state.results.any((r) => r.step == DiagnosticStep.checkingDhcpPool),
          isTrue,
        );
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

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(
          state.recommendations.any((r) => r.id == 'gateway_unreachable'),
          isTrue,
        );
        container.dispose();
      });
    });

    group('Scope Lifecycle', () {
      test('acquires scope and attaches to service before ping operations',
          () async {
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

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        // Scope acquired exactly once (lazy-cached) and attached to service.
        verify(() => mockExecutor.acquireScope(
              referencePaths: any(named: 'referencePaths'),
            )).called(1);
        verify(() => mockService.attachScope(mockScope)).called(1);
        container.dispose();
      });

      test('reuses scope across multiple flow runs (restart)', () async {
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

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        await notifier.restart();
        await Future.delayed(Duration.zero);

        // Scope cached after first ensure — never re-acquired.
        verify(() => mockExecutor.acquireScope(
              referencePaths: any(named: 'referencePaths'),
            )).called(1);
        verify(() => mockService.checkWanStatus()).called(2);
        container.dispose();
      });

      test('disposing container releases scope', () async {
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

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        container.dispose();
        // Drain microtasks so async ref.onDispose callback fires.
        await Future<void>.delayed(Duration.zero);

        verify(() => mockScope.release()).called(1);
      });

      test('release scope even when ping throws mid-flow', () async {
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

        await notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        container.dispose();
        await Future<void>.delayed(Duration.zero);

        // Even though gateway ping threw, the scope must still be released
        // exactly once on dispose.
        verify(() => mockScope.release()).called(1);
      });
    });

    group('Mesh / Backhaul Flow', () {
      test('marks step as skipped when no mesh nodes exist', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkMeshBackhaul())
            .thenAnswer((_) async => const []);

        await notifier.selectFlow(DiagnosticFlow.meshBackhaul);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.length, 1);
        expect(state.results.first, isA<MeshBackhaulCheckUIModel>());
        expect(state.results.first.isSkipped, isTrue);
        container.dispose();
      });

      test('reports ok severity when all nodes are healthy', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkMeshBackhaul()).thenAnswer((_) async => [
              const MeshBackhaulNodeRecord(
                nodeId: 'agent-A',
                label: 'Linksys M60TB',
                mediaType: 'IEEE_802_3ab_Ethernet',
                linkType: 'Ethernet',
                phyRateMbps: 1000,
                lastUplinkRateKbps: 1000,
                lastDownlinkRateKbps: 1000,
                signalStrengthDbm: 0,
                isController: false,
                severity: MeshBackhaulSeverity.healthy,
              ),
            ]);

        await notifier.selectFlow(DiagnosticFlow.meshBackhaul);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        final result = state.results.single as MeshBackhaulCheckUIModel;
        expect(result.severity, DiagnosticSeverity.ok);
        expect(result.nodes.single.severity, MeshBackhaulSeverity.healthy);
        // Healthy backhaul → no recommendations.
        expect(state.recommendations, isEmpty);
        container.dispose();
      });

      test('emits warning + reposition recommendation when any node is weak',
          () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkMeshBackhaul()).thenAnswer((_) async => [
              const MeshBackhaulNodeRecord(
                nodeId: 'agent-A',
                label: 'Linksys M60TB',
                mediaType: 'IEEE_802_11ax',
                linkType: 'Wi-Fi',
                phyRateMbps: 200,
                lastUplinkRateKbps: 200,
                lastDownlinkRateKbps: 200,
                signalStrengthDbm: -70,
                isController: false,
                severity: MeshBackhaulSeverity.weak,
              ),
            ]);

        await notifier.selectFlow(DiagnosticFlow.meshBackhaul);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        final result = state.results.single as MeshBackhaulCheckUIModel;
        expect(result.severity, DiagnosticSeverity.warning);
        expect(result.weakCount, 1);
        expect(result.poorCount, 0);
        expect(state.recommendations.any((r) => r.id == 'mesh_backhaul_weak'),
            isTrue);
        container.dispose();
      });

      test(
          'emits error + ethernet-backhaul recommendation when any node is poor',
          () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkMeshBackhaul()).thenAnswer((_) async => [
              const MeshBackhaulNodeRecord(
                nodeId: 'agent-A',
                label: 'Linksys M60TB',
                mediaType: 'IEEE_802_11ax',
                linkType: 'Wi-Fi',
                phyRateMbps: 50,
                lastUplinkRateKbps: 50,
                lastDownlinkRateKbps: 50,
                signalStrengthDbm: -80,
                isController: false,
                severity: MeshBackhaulSeverity.poor,
              ),
              const MeshBackhaulNodeRecord(
                nodeId: 'agent-B',
                label: 'Linksys M60TB',
                mediaType: 'IEEE_802_11ax',
                linkType: 'Wi-Fi',
                phyRateMbps: 200,
                lastUplinkRateKbps: 200,
                lastDownlinkRateKbps: 200,
                signalStrengthDbm: -70,
                isController: false,
                severity: MeshBackhaulSeverity.weak,
              ),
            ]);

        await notifier.selectFlow(DiagnosticFlow.meshBackhaul);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        final result = state.results.single as MeshBackhaulCheckUIModel;
        expect(result.severity, DiagnosticSeverity.error);
        expect(result.poorCount, 1);
        expect(result.weakCount, 1);
        // When any node is poor, only the poor recommendation is added —
        // weak is suppressed because the poor case dominates.
        expect(state.recommendations.any((r) => r.id == 'mesh_backhaul_poor'),
            isTrue);
        expect(state.recommendations.any((r) => r.id == 'mesh_backhaul_weak'),
            isFalse);
        container.dispose();
      });

      test('captures error result when service.checkMeshBackhaul throws',
          () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkMeshBackhaul())
            .thenThrow(Exception('USP failed'));

        await notifier.selectFlow(DiagnosticFlow.meshBackhaul);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.single.isError, isTrue);
        expect(state.results.single.step, DiagnosticStep.checkingMeshBackhaul);
        container.dispose();
      });
    });

    group('Device Issues Flow', () {
      test('runs getDeviceScores and reports ok severity for healthy fleet',
          () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.getDeviceScores())
            .thenAnswer((_) async => const [
                  DeviceScoreUIModel(
                    macAddress: 'AA:BB:CC:DD:EE:FF',
                    name: 'iPhone',
                    rssiDbm: -55,
                    downlinkKbps: 100000,
                    isWireless: true,
                  ),
                ]);

        await notifier.selectFlow(DiagnosticFlow.deviceIssues);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.single, isA<DeviceIssuesCheckUIModel>());
        expect(state.results.single.severity, DiagnosticSeverity.ok);
        container.dispose();
      });

      test('captures error result when getDeviceScores throws', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.getDeviceScores())
            .thenThrow(Exception('USP failed'));

        await notifier.selectFlow(DiagnosticFlow.deviceIssues);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.single.isError, isTrue);
        container.dispose();
      });
    });

    group('WiFi Coverage Flow', () {
      test('reports ok severity when coverage is healthy', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.analyzeWifiCoverage())
            .thenAnswer((_) async => const WifiCoverageUIModel(
                  totalWirelessDevices: 4,
                  weakSignalDevices: [],
                  averageSignalStrength: -55,
                  radios: [],
                ));

        await notifier.selectFlow(DiagnosticFlow.wifiCoverage);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.single, isA<WifiCoverageCheckUIModel>());
        expect(state.results.single.severity, DiagnosticSeverity.ok);
        container.dispose();
      });
    });

    group('Intermittent Flow', () {
      test('reports ok severity when no jitter / loss / reboot', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkIntermittent())
            .thenAnswer((_) async => const IntermittentUIModel(
                  uptimeSeconds: 86400,
                  pingSuccessRate: 1.0,
                  averageLatencyMs: 12,
                  jitterMs: 2,
                  hasHighJitter: false,
                  hasPacketLoss: false,
                  recentReboot: false,
                ));

        await notifier.selectFlow(DiagnosticFlow.intermittent);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results.single, isA<IntermittentCheckUIModel>());
        expect(state.results.single.severity, DiagnosticSeverity.ok);
        container.dispose();
      });

      test('reports error severity on packet loss', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkIntermittent())
            .thenAnswer((_) async => const IntermittentUIModel(
                  uptimeSeconds: 3600,
                  pingSuccessRate: 0.5,
                  averageLatencyMs: 12,
                  jitterMs: 2,
                  hasHighJitter: false,
                  hasPacketLoss: true,
                  recentReboot: false,
                ));

        await notifier.selectFlow(DiagnosticFlow.intermittent);
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.results.single.severity, DiagnosticSeverity.error);
        container.dispose();
      });
    });

    group('Full Diagnostic Flow', () {
      test('runs all checks and shows results when everything succeeds',
          () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus())
            .thenAnswer((_) async => const WanStatusUIModel(
                  status: 'Up',
                  ipAddress: '192.168.1.100',
                  subnetMask: '255.255.255.0',
                  addressingType: 'DHCP',
                ));
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
        when(() => mockService.analyzeWifiSignalPerRadio()).thenAnswer(
            (_) async => const WifiSignalPerRadioUIModel(radios: []));
        when(() => mockService.checkConnectedDevices())
            .thenAnswer((_) async => const ConnectedDevicesUIModel(
                  totalDevices: 5,
                  activeDevices: 5,
                  highBandwidthDevices: [],
                ));
        when(() => mockService.checkMeshBackhaul())
            .thenAnswer((_) async => const []);

        await notifier.runFullDiagnostic();
        await Future.delayed(Duration.zero);

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.showingResults);
        expect(state.results, isNotEmpty);
        // Verify the major checks all ran.
        verify(() => mockService.checkWanStatus()).called(1);
        verify(() => mockService.pingGateway(
              repeatCount: any(named: 'repeatCount'),
            )).called(1);
        verify(() => mockService.checkMeshBackhaul()).called(1);
        verify(() => mockService.checkConnectedDevices()).called(1);
        container.dispose();
      });
    });

    group('Cancellation', () {
      test('cancel awaits the in-flight run and releases scope', () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus())
            .thenAnswer((_) async => const WanStatusUIModel(
                  status: 'Up',
                  ipAddress: '192.168.1.100',
                  subnetMask: '255.255.255.0',
                  addressingType: 'DHCP',
                ));
        // Hang the gateway ping so we can interleave a cancel().
        final gatewayCompleter = Completer<PingResult>();
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) => gatewayCompleter.future);
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        final runFuture = notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        // Concurrently cancel; cancel must await in-flight before releasing.
        final cancelFuture = notifier.cancel();
        gatewayCompleter.complete(_createPingResult('192.168.1.1'));
        await runFuture;
        await cancelFuture;

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.idle);
        // Scope was acquired once during the run and released exactly once.
        verify(() => mockScope.release()).called(1);
        container.dispose();
      });

      // Regression for #1148: pressing "Cancel Diagnostics" mid-flow must
      // short-circuit the remaining sequential steps at the next step
      // boundary, not run every check to completion first. We hang the
      // gateway ping, fire cancel() while it's in-flight, then release the
      // ping — the subsequent steps (DNS ping, DNS lookup, internet ping,
      // speed test) must NOT be invoked.
      test('cancel mid-flow skips subsequent diagnostic steps (#1148)',
          () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        when(() => mockService.checkWanStatus())
            .thenAnswer((_) async => const WanStatusUIModel(
                  status: 'Up',
                  ipAddress: '192.168.1.100',
                  subnetMask: '255.255.255.0',
                  addressingType: 'DHCP',
                ));
        // Hang the gateway ping so we can interleave a cancel() before the
        // remaining steps run.
        final gatewayCompleter = Completer<PingResult>();
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) => gatewayCompleter.future);
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        final runFuture = notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        // Cancel while the gateway ping is still in-flight, then let it
        // resolve. The next step boundary must observe _cancelled and bail.
        final cancelFuture = notifier.cancel();
        gatewayCompleter.complete(_createPingResult('192.168.1.1'));
        await runFuture;
        await cancelFuture;

        // Steps after the cancelled gateway ping must never have executed.
        verifyNever(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            ));
        verifyNever(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            ));

        final state = container.read(unifiedDiagnosticsProvider);
        expect(state.step, DiagnosticStep.idle);
        container.dispose();
      });

      // Regression for the cancel→restart clobber race (PR #1175 review):
      // a runner suspended on a long await must NOT overwrite a *newer* run's
      // state when it revives. Run A hangs on the gateway ping; we cancel, then
      // start Run B which completes fully; only then do we release Run A's ping.
      // With the old shared `_cancelled` bool (reset to false by Run B), the
      // revived Run A saw _cancelled==false and clobbered B's state. The
      // per-run generation guard must make A's post-await writes no-ops.
      test('revived run after cancel+restart does not clobber new run (#1175)',
          () async {
        final container = createContainer();
        final notifier = container.read(unifiedDiagnosticsProvider.notifier);

        // Fingerprint the two runs so a clobber is detectable: Run A's WAN
        // check reports Down (error), Run B's reports Up (ok). If revived Run A
        // clobbers state, the final WAN result would be an error and the
        // results list would collapse to Run A's short accumulation.
        var wanCalls = 0;
        when(() => mockService.checkWanStatus()).thenAnswer((_) async {
          wanCalls++;
          return wanCalls == 1
              ? const WanStatusUIModel(
                  status: 'Down',
                  ipAddress: '',
                  subnetMask: '',
                  addressingType: 'DHCP',
                )
              : const WanStatusUIModel(
                  status: 'Up',
                  ipAddress: '192.168.1.100',
                  subnetMask: '255.255.255.0',
                  addressingType: 'DHCP',
                );
        });
        // First gateway ping (Run A) hangs; every later call (Run B) resolves
        // immediately so B can run to completion while A is suspended.
        final runAGateway = Completer<PingResult>();
        var gatewayCalls = 0;
        when(() =>
                mockService.pingGateway(repeatCount: any(named: 'repeatCount')))
            .thenAnswer((_) {
          gatewayCalls++;
          return gatewayCalls == 1
              ? runAGateway.future
              : Future.value(_createPingResult('192.168.1.1'));
        });
        when(() => mockService.pingDns(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('8.8.8.8'));
        when(() => mockService.pingInternet(
              host: any(named: 'host'),
              repeatCount: any(named: 'repeatCount'),
            )).thenAnswer((_) async => _createPingResult('1.1.1.1'));

        // Run A — suspends at the hung gateway ping.
        final runAFuture = notifier.selectFlow(DiagnosticFlow.internet);
        await Future.delayed(Duration.zero);

        // Cancel Run A, then immediately start Run B and let it finish.
        final cancelFuture = notifier.cancel();
        final runBFuture = notifier.selectFlow(DiagnosticFlow.internet);
        await runBFuture;
        await Future.delayed(Duration.zero);

        // Snapshot Run B's completed state before reviving A.
        final afterB = container.read(unifiedDiagnosticsProvider);
        expect(afterB.step, DiagnosticStep.showingResults);
        expect(afterB.results.length, 6);
        final wanB = afterB.results
            .firstWhere((r) => r.step == DiagnosticStep.checkingWanStatus);
        expect(wanB.isError, isFalse); // Run B saw WAN Up.

        // Revive Run A — its post-await writes must be rejected by the
        // generation guard and leave Run B's state untouched.
        runAGateway.complete(_createPingResult('192.168.1.1'));
        await runAFuture;
        await cancelFuture;
        await Future.delayed(Duration.zero);

        final finalState = container.read(unifiedDiagnosticsProvider);
        expect(finalState.step, DiagnosticStep.showingResults);
        // Run A must NOT have clobbered: length and WAN verdict stay Run B's.
        expect(finalState.results.length, 6);
        final finalWan = finalState.results
            .firstWhere((r) => r.step == DiagnosticStep.checkingWanStatus);
        expect(finalWan.isError, isFalse,
            reason: 'revived Run A (WAN Down) must not clobber Run B (WAN Up)');
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

        await notifier.selectFlow(DiagnosticFlow.internet);
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

class _FakeScope extends Fake implements DiagnosticScope {}

class _MockSpeedTestNotifier extends AutoDisposeAsyncNotifier<SpeedTestState>
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

  @override
  Future<void> cancel() async {
    state = const AsyncData(SpeedTestState());
  }
}
