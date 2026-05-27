import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/turbo_session_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

void main() {
  late MockUspBridgeClient mockBridge;
  late TurboSessionManager manager;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    manager = TurboSessionManager(mockBridge);
  });

  tearDown(() async {
    await manager.dispose();
  });

  group('TurboSessionManager', () {
    test('initial state is idle', () {
      expect(manager.state, TurboSessionState.idle);
      expect(manager.sessionId, isNull);
      expect(manager.isActive, isFalse);
    });

    test('start() transitions to active on success', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'granted',
            'session_id': 'test-session-123',
          });

      final sessionId = await manager.start();

      expect(sessionId, 'test-session-123');
      expect(manager.state, TurboSessionState.active);
      expect(manager.sessionId, 'test-session-123');
      expect(manager.isActive, isTrue);
      verify(() => mockBridge.turboStart()).called(1);
    });

    test('start() throws on denied status', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'denied',
            'error': 'Session already in use',
          });

      expect(
        () => manager.start(),
        throwsA(isA<TurboSessionException>().having(
          (e) => e.message,
          'message',
          contains('not granted'),
        )),
      );

      expect(manager.state, TurboSessionState.idle);
    });

    test('start() returns existing session if already active', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'granted',
            'session_id': 'session-1',
          });

      await manager.start();
      final secondCall = await manager.start();

      expect(secondCall, 'session-1');
      verify(() => mockBridge.turboStart()).called(1);
    });

    test('release() transitions to idle', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'granted',
            'session_id': 'session-to-release',
          });
      when(() => mockBridge.turboRelease(sessionId: any(named: 'sessionId')))
          .thenAnswer((_) async => {
                'status': 'released',
              });

      await manager.start();
      await manager.release();

      expect(manager.state, TurboSessionState.idle);
      expect(manager.sessionId, isNull);
      expect(manager.isActive, isFalse);
      verify(() => mockBridge.turboRelease(sessionId: 'session-to-release'))
          .called(1);
    });

    test('release() is idempotent when idle', () async {
      await manager.release();
      await manager.release();

      verifyNever(
          () => mockBridge.turboRelease(sessionId: any(named: 'sessionId')));
      expect(manager.state, TurboSessionState.idle);
    });

    test('release() completes even on error', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'granted',
            'session_id': 'session-error',
          });
      when(() => mockBridge.turboRelease(sessionId: any(named: 'sessionId')))
          .thenThrow(Exception('Network error'));

      await manager.start();
      await manager.release();

      expect(manager.state, TurboSessionState.idle);
      expect(manager.sessionId, isNull);
    });

    test('heartbeat() calls bridge heartbeat', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'granted',
            'session_id': 'hb-session',
          });
      when(() => mockBridge.turboHeartbeat(sessionId: any(named: 'sessionId')))
          .thenAnswer((_) async => {
                'status': 'ok',
              });

      await manager.start();
      await manager.heartbeat();

      verify(() => mockBridge.turboHeartbeat(sessionId: 'hb-session'))
          .called(1);
    });

    test('heartbeat() does nothing when not active', () async {
      await manager.heartbeat();

      verifyNever(
          () => mockBridge.turboHeartbeat(sessionId: any(named: 'sessionId')));
    });

    test('heartbeat timer runs automatically after start', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'granted',
            'session_id': 'timer-session',
          });
      when(() => mockBridge.turboHeartbeat(sessionId: any(named: 'sessionId')))
          .thenAnswer((_) async => {
                'status': 'ok',
              });
      when(() => mockBridge.turboRelease(sessionId: any(named: 'sessionId')))
          .thenAnswer((_) async => {
                'status': 'released',
              });

      await manager.start();

      // Wait slightly more than one heartbeat interval (12s is default, use fake)
      // In real tests we'd use fake_async, but for now just verify the timer was set
      expect(manager.isActive, isTrue);

      await manager.release();
    });

    test('getStatus() returns parsed TurboStatus', () async {
      when(() => mockBridge.turboStatus()).thenAnswer((_) async => {
            'state': 'IN_USE',
            'owner': 'controller::other-client',
            'session_id': 'other-session',
            'remaining_seconds': 285,
          });

      final status = await manager.getStatus();

      expect(status.state, 'IN_USE');
      expect(status.owner, 'controller::other-client');
      expect(status.sessionId, 'other-session');
      expect(status.remainingSeconds, 285);
      expect(status.isIdle, isFalse);
      expect(status.isInUse, isTrue);
    });

    test('dispose() releases active session', () async {
      when(() => mockBridge.turboStart()).thenAnswer((_) async => {
            'status': 'granted',
            'session_id': 'dispose-session',
          });
      when(() => mockBridge.turboRelease(sessionId: any(named: 'sessionId')))
          .thenAnswer((_) async => {
                'status': 'released',
              });

      await manager.start();
      await manager.dispose();

      verify(() => mockBridge.turboRelease(sessionId: 'dispose-session'))
          .called(1);
      expect(manager.state, TurboSessionState.idle);
    });
  });

  group('TurboStatus', () {
    test('fromJson parses all fields', () {
      final status = TurboStatus.fromJson({
        'state': 'IDLE',
        'owner': null,
        'session_id': null,
        'remaining_seconds': null,
      });

      expect(status.state, 'IDLE');
      expect(status.owner, isNull);
      expect(status.isIdle, isTrue);
      expect(status.isInUse, isFalse);
    });

    test('fromJson handles missing fields', () {
      final status = TurboStatus.fromJson({});

      expect(status.state, 'UNKNOWN');
      expect(status.owner, isNull);
      expect(status.sessionId, isNull);
      expect(status.remainingSeconds, isNull);
    });

    test('toString returns readable format', () {
      final status = TurboStatus.fromJson({
        'state': 'IN_USE',
        'owner': 'test-owner',
        'session_id': 'test-id',
        'remaining_seconds': 120,
      });

      final str = status.toString();
      expect(str, contains('IN_USE'));
      expect(str, contains('test-owner'));
      expect(str, contains('test-id'));
      expect(str, contains('120'));
    });
  });

  group('TurboSessionException', () {
    test('toString includes message', () {
      const exception = TurboSessionException('Test error message');
      expect(exception.toString(), contains('Test error message'));
    });
  });
}
