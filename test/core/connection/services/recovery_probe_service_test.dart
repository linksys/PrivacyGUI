import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}

class MockRouterFingerprintService extends Mock
    implements RouterFingerprintService {}

void main() {
  late MockUspBridgeClient mockBridge;
  late MockUspAuthCoordinator mockAuth;
  late MockRouterFingerprintService mockFingerprint;
  late RecoveryProbeService service;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    mockAuth = MockUspAuthCoordinator();
    mockFingerprint = MockRouterFingerprintService();
    service = RecoveryProbeService(
      bridge: mockBridge,
      authCoordinator: mockAuth,
      fingerprintService: mockFingerprint,
    );
  });

  Map<String, dynamic> healthyResponse() => {
        'status': 'healthy',
        'agent_connected': true,
        'agent_state': 'ready',
      };

  group('RecoveryProbeService.probe()', () {
    test('returns unreachable when health check fails', () async {
      when(() => mockBridge.health()).thenThrow(Exception('network error'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when agent not connected', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {
            'status': 'healthy',
            'agent_connected': false,
            'agent_state': 'connecting',
          });

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when agent_state is not ready', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {
            'status': 'healthy',
            'agent_connected': true,
            'agent_state': 'connecting',
          });

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when health response missing agent fields',
        () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {});

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when health OK but login fails', () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenThrow(Exception('login failed'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() => mockFingerprint.matches(any()));
    });

    test('returns recovered when health OK, login OK, serial matches',
        () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'ABC123');
      when(() => mockFingerprint.matches('ABC123'))
          .thenAnswer((_) async => true);

      final result = await service.probe();

      expect(result, ProbeResult.recovered);
    });

    test('returns serialMismatch when health OK, login OK, serial differs',
        () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'XYZ789');
      when(() => mockFingerprint.matches('XYZ789'))
          .thenAnswer((_) async => false);

      final result = await service.probe();

      expect(result, ProbeResult.serialMismatch);
    });

    test('returns unreachable when health OK, login OK, serial read fails',
        () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenThrow(Exception('USP error'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
    });
  });
}
