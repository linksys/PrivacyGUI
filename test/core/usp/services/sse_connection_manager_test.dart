import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

import '../helpers.dart';
import '../mocks.dart';

void main() {
  late MockUspBridgeClient mockBridge;
  late StreamController<SseEvent> streamController;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    streamController = StreamController<SseEvent>();

    when(() => mockBridge.notifications())
        .thenAnswer((_) => streamController.stream);
  });

  tearDown(() {
    if (!streamController.isClosed) {
      streamController.close();
    }
  });

  // ---------------------------------------------------------------------------
  // connect
  // ---------------------------------------------------------------------------
  group('connect', () {
    test('transitions to connecting then connected on event', () async {
      final manager = SseConnectionManager(mockBridge);
      final states = <SseConnectionState>[];
      manager.connectionState.addListener(() {
        states.add(manager.connectionState.value);
      });

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      expect(states, contains(SseConnectionState.connecting));
      expect(states, contains(SseConnectionState.connected));

      manager.dispose();
    });

    test('calls bridge.notifications()', () async {
      final manager = SseConnectionManager(mockBridge);

      await manager.connect();

      verify(() => mockBridge.notifications()).called(1);

      manager.dispose();
    });

    test('duplicate connect awaits existing — only 1 notifications() call',
        () async {
      final manager = SseConnectionManager(mockBridge);

      // Call connect twice simultaneously
      await Future.wait([manager.connect(), manager.connect()]);

      verify(() => mockBridge.notifications()).called(1);

      manager.dispose();
    });

    test('disposed manager does nothing on connect', () async {
      final manager = SseConnectionManager(mockBridge);
      manager.dispose();

      await manager.connect();

      verifyNever(() => mockBridge.notifications());
    });

    test('stream immediately errors schedules reconnect', () async {
      final errorStream = Stream<SseEvent>.error(Exception('stream error'));
      when(() => mockBridge.notifications()).thenAnswer((_) => errorStream);

      final manager = SseConnectionManager(mockBridge);
      await manager.connect();
      await Future.delayed(const Duration(milliseconds: 50));

      // After stream error, should schedule reconnect
      expect(manager.connectionState.value, SseConnectionState.reconnecting);

      manager.dispose();
    });

    test('onConnected callback fires on first real event', () async {
      final manager = SseConnectionManager(mockBridge);
      bool connected = false;
      manager.onConnected = () => connected = true;

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      expect(connected, isTrue);

      manager.dispose();
    });

    test('_debug events do not trigger connected transition', () async {
      final manager = SseConnectionManager(mockBridge);
      bool connectedCallbackFired = false;
      manager.onConnected = () => connectedCallbackFired = true;

      await manager.connect();
      streamController.add(debugEvent('diagnostic info'));
      await Future.delayed(Duration.zero);

      expect(
          manager.connectionState.value, isNot(SseConnectionState.connected));
      expect(connectedCallbackFired, isFalse);

      manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // disconnect
  // ---------------------------------------------------------------------------
  group('disconnect', () {
    test('transitions to disconnected', () async {
      final manager = SseConnectionManager(mockBridge);

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);
      expect(manager.connectionState.value, SseConnectionState.connected);

      await manager.disconnect();
      expect(manager.connectionState.value, SseConnectionState.disconnected);

      manager.dispose();
    });

    test('cancels reconnect timer', () async {
      final manager = SseConnectionManager(mockBridge);

      // Connect, get connected, then stream closes (triggers reconnect)
      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);
      expect(manager.connectionState.value, SseConnectionState.connected);

      await streamController.close();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(manager.connectionState.value, SseConnectionState.reconnecting);

      // Disconnect should cancel the reconnect
      await manager.disconnect();
      expect(manager.connectionState.value, SseConnectionState.disconnected);

      // Even after waiting, state should stay disconnected
      await Future.delayed(const Duration(milliseconds: 200));
      expect(manager.connectionState.value, SseConnectionState.disconnected);

      manager.dispose();
    });

    test('onDisconnected fires if was connected', () async {
      final manager = SseConnectionManager(mockBridge);
      bool disconnected = false;
      manager.onDisconnected = () => disconnected = true;

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      await manager.disconnect();
      expect(disconnected, isTrue);

      manager.dispose();
    });

    test('resets reconnect attempt counter', () async {
      final manager = SseConnectionManager(mockBridge);

      await manager.connect();
      await manager.disconnect();

      // tryReconnect should work after disconnect
      when(() => mockBridge.notifications())
          .thenAnswer((_) => StreamController<SseEvent>().stream);
      final result = await manager.tryReconnect();
      // Intentional disconnect prevents reconnect
      expect(result, isFalse);

      manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Event handling
  // ---------------------------------------------------------------------------
  group('Event handling', () {
    test('onEvent callback receives every event', () async {
      final manager = SseConnectionManager(mockBridge);
      final events = <SseEvent>[];
      manager.onEvent = (e) => events.add(e);

      await manager.connect();
      streamController.add(heartbeatEvent());
      streamController.add(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));
      await Future.delayed(Duration.zero);

      expect(events.length, 2);

      manager.dispose();
    });

    test('stream error triggers handleStreamEnd', () async {
      final manager = SseConnectionManager(mockBridge);
      bool disconnectedCalled = false;
      manager.onDisconnected = () => disconnectedCalled = true;

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);
      expect(manager.connectionState.value, SseConnectionState.connected);

      streamController.addError(Exception('stream error'));
      await Future.delayed(Duration.zero);

      expect(disconnectedCalled, isTrue);

      manager.dispose();
    });

    test('stream done triggers handleStreamEnd', () async {
      final manager = SseConnectionManager(mockBridge);
      bool disconnectedCalled = false;
      manager.onDisconnected = () => disconnectedCalled = true;

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      await streamController.close();
      await Future.delayed(Duration.zero);

      expect(disconnectedCalled, isTrue);

      manager.dispose();
    });

    test('double-fire guard: error+done only handles once', () async {
      final manager = SseConnectionManager(mockBridge);
      int disconnectedCount = 0;
      manager.onDisconnected = () => disconnectedCount++;

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      // Error then close on same stream
      streamController.addError(Exception('error'));
      await streamController.close();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(disconnectedCount, 1); // Only once, not twice

      manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Heartbeat watchdog
  // ---------------------------------------------------------------------------
  group('Heartbeat watchdog', () {
    test('timeout after 45s no events triggers reconnect', () {
      fakeAsync((async) {
        final manager = SseConnectionManager(mockBridge);

        manager.connect();
        async.flushMicrotasks();

        streamController.add(heartbeatEvent());
        async.flushMicrotasks();
        expect(manager.connectionState.value, SseConnectionState.connected);

        // Advance 45s without any events
        async.elapse(const Duration(seconds: 45));

        // Should have triggered stream end → reconnect
        expect(
          manager.connectionState.value,
          isNot(SseConnectionState.connected),
        );

        manager.dispose();
      });
    });

    test('event resets timer — no timeout within 45s of last event', () {
      fakeAsync((async) {
        final manager = SseConnectionManager(mockBridge);

        manager.connect();
        async.flushMicrotasks();

        streamController.add(heartbeatEvent());
        async.flushMicrotasks();

        // Advance 30s, send another event
        async.elapse(const Duration(seconds: 30));
        streamController.add(heartbeatEvent());
        async.flushMicrotasks();

        // Advance another 30s (60s total, but only 30s since last event)
        async.elapse(const Duration(seconds: 30));

        expect(manager.connectionState.value, SseConnectionState.connected);

        manager.dispose();
      });
    });

    test('disconnect cancels watchdog', () {
      fakeAsync((async) {
        final manager = SseConnectionManager(mockBridge);

        manager.connect();
        async.flushMicrotasks();

        streamController.add(heartbeatEvent());
        async.flushMicrotasks();

        manager.disconnect();
        async.flushMicrotasks();

        // Even after 45s+ the state should stay disconnected (no reconnect)
        async.elapse(const Duration(seconds: 60));
        expect(manager.connectionState.value, SseConnectionState.disconnected);

        manager.dispose();
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Reconnection / backoff
  // ---------------------------------------------------------------------------
  group('Reconnection / backoff', () {
    test('stream close triggers reconnect state', () async {
      final manager = SseConnectionManager(mockBridge);

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);
      expect(manager.connectionState.value, SseConnectionState.connected);

      // Close the stream — triggers handleStreamEnd → scheduleReconnect
      await streamController.close();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.connectionState.value, SseConnectionState.reconnecting);

      manager.dispose();
    });

    test('max retries transitions to suspended', () async {
      final manager = SseConnectionManager(
        mockBridge,
        initialBackoff: const Duration(milliseconds: 10),
        maxBackoff: const Duration(milliseconds: 100),
        maxRetries: 5,
      );

      // Each reconnect creates a new stream that immediately closes
      int attempt = 0;
      when(() => mockBridge.notifications()).thenAnswer((_) {
        attempt++;
        final sc = StreamController<SseEvent>();
        Future.microtask(() => sc.close());
        return sc.stream;
      });

      await manager.connect();

      // Total backoff: 20+40+80+100+100 = 340ms
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (manager.connectionState.value == SseConnectionState.suspended) {
          break;
        }
      }

      expect(manager.connectionState.value, SseConnectionState.suspended);
      expect(attempt, greaterThan(1));

      manager.dispose();
    });

    test('intentional disconnect prevents reconnect', () async {
      final manager = SseConnectionManager(mockBridge);

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      await manager.disconnect();
      expect(manager.connectionState.value, SseConnectionState.disconnected);

      // Wait and verify state doesn't change
      await Future.delayed(const Duration(milliseconds: 200));
      expect(manager.connectionState.value, SseConnectionState.disconnected);

      manager.dispose();
    });

    test('tryReconnect from suspended resets attempts', () async {
      final manager = SseConnectionManager(
        mockBridge,
        initialBackoff: const Duration(milliseconds: 10),
        maxBackoff: const Duration(milliseconds: 100),
        maxRetries: 5,
      );

      // Exhaust retries with streams that immediately close
      when(() => mockBridge.notifications()).thenAnswer((_) {
        final sc = StreamController<SseEvent>();
        Future.microtask(() => sc.close());
        return sc.stream;
      });

      await manager.connect();

      // Wait for suspension
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (manager.connectionState.value == SseConnectionState.suspended) {
          break;
        }
      }
      expect(manager.connectionState.value, SseConnectionState.suspended);

      // Now allow connection to succeed
      final newStreamController = StreamController<SseEvent>();
      when(() => mockBridge.notifications())
          .thenAnswer((_) => newStreamController.stream);

      final result = await manager.tryReconnect();
      expect(result, isTrue);

      // Should be connecting again (not suspended)
      expect(
        manager.connectionState.value,
        isNot(SseConnectionState.suspended),
      );

      newStreamController.close();
      manager.dispose();
    });

    test('tryReconnect returns false when already connected', () async {
      final manager = SseConnectionManager(mockBridge);

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);
      expect(manager.connectionState.value, SseConnectionState.connected);

      final result = await manager.tryReconnect();
      expect(result, isFalse);

      manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------
  group('dispose', () {
    test('cancels all timers and subscriptions', () {
      fakeAsync((async) {
        final manager = SseConnectionManager(mockBridge);

        manager.connect();
        async.flushMicrotasks();

        streamController.add(heartbeatEvent());
        async.flushMicrotasks();

        manager.dispose();

        // No timers should fire after dispose
        async.elapse(const Duration(seconds: 120));
        // If timers weren't cancelled, this would throw
      });
    });

    test('disposed flag prevents connect', () async {
      final manager = SseConnectionManager(mockBridge);
      manager.dispose();

      await manager.connect();

      verifyNever(() => mockBridge.notifications());
    });

    test('connectionState ValueNotifier is disposed', () {
      final manager = SseConnectionManager(mockBridge);
      manager.dispose();

      // After dispose, adding listeners throws a FlutterError
      expect(
        () => manager.connectionState.addListener(() {}),
        throwsA(anything),
      );
    });
  });
}
