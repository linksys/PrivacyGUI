import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

import '../helpers.dart';
import '../mocks.dart';

void main() {
  late MockUspBridgeClient mockBridge;
  late MockUspClient mockUsp;
  late SseManager manager;
  late SseOperationAwaiter awaiter;
  late StreamController<SseEvent> streamController;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    mockUsp = MockUspClient();
    streamController = StreamController<SseEvent>();

    when(() => mockBridge.notifications())
        .thenAnswer((_) => streamController.stream);
    when(() => mockBridge.subscribe(
          subscriptionId: any(named: 'subscriptionId'),
          path: any(named: 'path'),
          notifType: any(named: 'notifType'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.unsubscribe(
          subscriptionId: any(named: 'subscriptionId'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.abortSse()).thenReturn(null);

    when(() => mockUsp.onSseSubscribe = any(that: anything)).thenReturn(null);
    when(() => mockUsp.onTokenRefreshed = any(that: anything)).thenReturn(null);
    when(() => mockUsp.operate(any(), args: any(named: 'args')))
        .thenAnswer((_) async => {'commandKey': 'test-key-123'});

    manager = SseManager(usp: mockUsp, bridge: mockBridge);
    awaiter = SseOperationAwaiter(manager, mockUsp);
  });

  tearDown(() async {
    // Cancel any pending linger timer and run cleanup so a stray Timer
    // callback can't fire after the mocks are torn down.
    await awaiter.tearDownSharedSessionNow();
    if (!streamController.isClosed) {
      streamController.close();
    }
    await manager.dispose();
  });

  /// Helper: connect the manager and transition to connected state.
  Future<void> connectManager() async {
    await manager.connect();
    streamController.add(heartbeatEvent());
    await Future.delayed(const Duration(milliseconds: 50));
  }

  // ---------------------------------------------------------------------------
  // execute — SSE path
  // ---------------------------------------------------------------------------
  group('execute — SSE path', () {
    test('subscribes OperationComplete and fires operate', () async {
      await connectManager();

      // Start execute in background — it will wait for SSE result
      final future = awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        args: {'Host': '8.8.8.8'},
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify operate was called
      verify(() => mockUsp.operate(
            'Device.IP.Diagnostics.IPPing()',
            args: {'Host': '8.8.8.8'},
          )).called(1);

      // Verify subscription was registered
      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: 'Device.IP.Diagnostics.IPPing()',
            notifType: 4, // OperationComplete
          )).called(1);

      // Now deliver the result via SSE
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-internal-id',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': 'test-key-123',
          'output_args': {
            'Status': 'Complete',
            'SuccessCount': '5',
          },
        },
      ));

      final result = await future;
      expect(result.commandName, 'IPPing()');
      expect(result.status, 'Complete');
      expect(result.outputArgs['SuccessCount'], '5');
    });

    test('wildcard handler matches by commandKey', () async {
      await connectManager();

      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {'commandKey': 'specific-key-456'});

      final future = awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.TraceRoute()',
        referencePath: 'Device.IP.Diagnostics.TraceRoute()',
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Wrong commandKey — should not match
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-1',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'TraceRoute()',
          'command_key': 'wrong-key',
          'output_args': {'Status': 'Complete'},
        },
      ));
      await Future.delayed(Duration.zero);

      // Right commandKey — should match
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-2',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'TraceRoute()',
          'command_key': 'specific-key-456',
          'output_args': {'Status': 'Complete'},
        },
      ));

      final result = await future;
      expect(result.commandKey, 'specific-key-456');
    });

    test('result parsed from oper_complete payload', () async {
      await connectManager();

      final future = awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      streamController.add(notificationEvent(
        subscriptionId: 'cpe-1',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': 'test-key-123',
          'output_args': {
            'Status': 'Complete',
            'SuccessCount': '10',
            'FailureCount': '0',
            'AverageResponseTime': '15',
          },
        },
      ));

      final result = await future;
      expect(result.commandName, 'IPPing()');
      expect(result.commandKey, 'test-key-123');
      expect(result.outputArgs['SuccessCount'], '10');
      expect(result.outputArgs['AverageResponseTime'], '15');
    });

    test('timeout throws TimeoutException', () async {
      await connectManager();

      expect(
        () => awaiter.execute(
          operateCommand: 'Device.IP.Diagnostics.IPPing()',
          referencePath: 'Device.IP.Diagnostics.IPPing()',
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('cleanup called even on timeout', () async {
      await connectManager();

      try {
        await awaiter.execute(
          operateCommand: 'Device.IP.Diagnostics.IPPing()',
          referencePath: 'Device.IP.Diagnostics.IPPing()',
          timeout: const Duration(milliseconds: 200),
        );
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 50));

      // Unsubscribe should have been called (cleanup)
      verify(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).called(greaterThanOrEqualTo(1));
    });

    test('fallback to commandName when commandKey empty', () async {
      await connectManager();

      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {'commandKey': ''});

      final future = awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      streamController.add(notificationEvent(
        subscriptionId: 'cpe-1',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': '',
          'output_args': {'Status': 'Complete'},
        },
      ));

      final result = await future;
      expect(result.commandName, 'IPPing()');
    });
  });

  // ---------------------------------------------------------------------------
  // execute — Polling fallback
  // ---------------------------------------------------------------------------
  group('execute — Polling fallback', () {
    test('fires operate and polls GET', () async {
      // Don't connect → SSE disconnected → polling path
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.IP.Diagnostics.IPPing.DiagnosticsState': 'Complete',
            'Device.IP.Diagnostics.IPPing.SuccessCount': '5',
          });

      final result = await awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(seconds: 10),
      );

      verify(() => mockUsp.operate(
            'Device.IP.Diagnostics.IPPing()',
            args: any(named: 'args'),
          )).called(1);
      verify(() => mockUsp.get(any())).called(greaterThanOrEqualTo(1));
      expect(result.status, 'Complete');
    });

    test('returns on Error state', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.IP.Diagnostics.IPPing.DiagnosticsState': 'Error',
          });

      final result = await awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(seconds: 10),
      );

      expect(result.isError, isTrue);
    });

    test('timeout throws TimeoutException', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.IP.Diagnostics.IPPing.DiagnosticsState': 'Requested',
          });

      expect(
        () => awaiter.execute(
          operateCommand: 'Device.IP.Diagnostics.IPPing()',
          referencePath: 'Device.IP.Diagnostics.IPPing()',
          timeout: const Duration(seconds: 3),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('poll error does not abort loop', () async {
      int pollCount = 0;
      when(() => mockUsp.get(any())).thenAnswer((_) async {
        pollCount++;
        if (pollCount <= 2) throw Exception('network error');
        return {
          'Device.IP.Diagnostics.IPPing.DiagnosticsState': 'Complete',
          'Device.IP.Diagnostics.IPPing.SuccessCount': '5',
        };
      });

      final result = await awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(seconds: 10),
      );

      expect(result.status, 'Complete');
      expect(pollCount, greaterThanOrEqualTo(3));
    });
  });

  // ---------------------------------------------------------------------------
  // executeNoWait
  // ---------------------------------------------------------------------------
  group('executeNoWait', () {
    test('calls usp.operate', () async {
      await awaiter.executeNoWait(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        args: {'Host': '8.8.8.8'},
      );

      verify(() => mockUsp.operate(
            'Device.IP.Diagnostics.IPPing()',
            args: {'Host': '8.8.8.8'},
          )).called(1);
    });

    test('does not subscribe or wait', () async {
      await awaiter.executeNoWait(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
      );

      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));
    });
  });

  // ---------------------------------------------------------------------------
  // _parseOperateResult (tested indirectly)
  // ---------------------------------------------------------------------------
  group('parseOperateResult', () {
    test('valid oper_complete payload returns OperateResult', () async {
      await connectManager();

      final future = awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      streamController.add(notificationEvent(
        subscriptionId: 'cpe-1',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': 'test-key-123',
          'output_args': {'Status': 'Complete'},
        },
      ));

      final result = await future;
      expect(result, isNotNull);
      expect(result.isComplete, isTrue);
    });

    test('missing oper_complete does not match', () async {
      await connectManager();

      final future = awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(milliseconds: 500),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Notification without oper_complete — should be ignored
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-1',
        type: 'OperationComplete',
      ));

      expect(() => future, throwsA(isA<TimeoutException>()));
    });
  });

  // ---------------------------------------------------------------------------
  // Shared Session
  // ---------------------------------------------------------------------------
  group('Shared Session', () {
    test('startSharedSession creates subscription', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: 'Device.IP.Diagnostics.',
            notifType: 4, // OperationComplete
          )).called(1);
    });

    test('endSharedSession unsubscribes (after forced teardown)', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');
      await awaiter.endSharedSession();
      // endSharedSession schedules linger teardown; force immediate teardown
      // here so we can assert the unsubscribe call without waiting 4 seconds.
      await awaiter.tearDownSharedSessionNow();

      verify(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).called(1);
    });

    test('executeInSession uses shared subscription', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      // Reset verification for subscribe to check it's not called again
      clearInteractions(mockBridge);

      final future = awaiter.executeInSession(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        args: {'Host': '8.8.8.8'},
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify operate was called
      verify(() => mockUsp.operate(
            'Device.IP.Diagnostics.IPPing()',
            args: {'Host': '8.8.8.8'},
          )).called(1);

      // Verify NO new subscription was created (uses shared session)
      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));

      // Deliver result
      streamController.add(notificationEvent(
        subscriptionId: 'shared-session-id',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': 'test-key-123',
          'output_args': {'Status': 'Complete', 'SuccessCount': '3'},
        },
      ));

      final result = await future;
      expect(result.status, 'Complete');

      await awaiter.endSharedSession();
    });

    test('executeInSession throws if no shared session active', () async {
      await connectManager();

      expect(
        () => awaiter.executeInSession(
          operateCommand: 'Device.IP.Diagnostics.IPPing()',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('multiple executeInSession calls share same subscription', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      clearInteractions(mockBridge);

      // First operation
      final future1 = awaiter.executeInSession(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        args: {'Host': '8.8.8.8'},
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      streamController.add(notificationEvent(
        subscriptionId: 'shared',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': 'test-key-123',
          'output_args': {'Status': 'Complete'},
        },
      ));

      await future1;

      // Second operation — same session
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {'commandKey': 'test-key-456'});

      final future2 = awaiter.executeInSession(
        operateCommand: 'Device.IP.Diagnostics.TraceRoute()',
        args: {'Host': 'google.com'},
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      streamController.add(notificationEvent(
        subscriptionId: 'shared',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'TraceRoute()',
          'command_key': 'test-key-456',
          'output_args': {'Status': 'Complete'},
        },
      ));

      await future2;

      // NO new subscriptions should have been created
      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));

      await awaiter.endSharedSession();
    });

    test('execute() uses shared session if active', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      clearInteractions(mockBridge);

      final future = awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Should NOT create a new subscription since shared session is active
      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));

      streamController.add(notificationEvent(
        subscriptionId: 'shared',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': 'test-key-123',
          'output_args': {'Status': 'Complete'},
        },
      ));

      final result = await future;
      expect(result.isComplete, isTrue);

      await awaiter.endSharedSession();
    });

    test('two acquires share single subscription (ref-count)', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');
      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      // Second acquire only increments ref-count; subscribe runs once
      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).called(1);

      // First release: ref-count > 0, no teardown (and no linger either)
      await awaiter.endSharedSession();
      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));

      // Second release: ref-count hits zero, but teardown is deferred via
      // linger. Force immediate teardown to assert the unsubscribe call.
      await awaiter.endSharedSession();
      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));
      await awaiter.tearDownSharedSessionNow();
      verify(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).called(1);
    });

    test('endSharedSession beyond zero is no-op', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');
      await awaiter.endSharedSession();
      await awaiter.endSharedSession(); // Already at zero — no-op
      await awaiter.tearDownSharedSessionNow();

      // Unsubscribe should only be called once
      verify(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).called(1);
    });

    test('multi referencePaths subscribes each path', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePaths: const [
        'Device.IP.Diagnostics.',
        'Device.DNS.Diagnostics.',
      ]);

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: 'Device.IP.Diagnostics.',
            notifType: 4,
          )).called(1);
      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: 'Device.DNS.Diagnostics.',
            notifType: 4,
          )).called(1);

      await awaiter.endSharedSession();
      await awaiter.tearDownSharedSessionNow();

      // Both subscriptions cleaned up
      verify(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).called(2);
    });

    test('startSharedSession requires path argument', () async {
      await connectManager();

      expect(
        () => awaiter.startSharedSession(),
        throwsA(isA<ArgumentError>()),
      );
    });

    // -------------------------------------------------------------------------
    // HTTP operate retry — bridge can stall on first POST after page re-entry
    // while it drains prior session traffic. We retry once on timeout so the
    // user doesn't have to press "Run Again" themselves.
    // -------------------------------------------------------------------------
    test('first operate ack timeout → retry succeeds', () async {
      await connectManager();
      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      // First call hangs past the 15s HTTP timeout; second call succeeds.
      var callCount = 0;
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          // Hang for longer than _operateHttpTimeout (15s) so the retry path
          // engages. Use a bigger delay to be safe against flake.
          await Future<void>.delayed(const Duration(seconds: 20));
          return {'commandKey': 'never'};
        }
        return {'commandKey': 'second-key'};
      });

      final future = awaiter.executeInSession(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        args: {'Host': '8.8.8.8'},
        timeout: const Duration(seconds: 60),
      );

      // Wait long enough for the first attempt to time out and the retry
      // to fire, then deliver the OperationComplete for the retry.
      await Future<void>.delayed(const Duration(seconds: 16));

      streamController.add(notificationEvent(
        subscriptionId: 'shared',
        type: 'OperationComplete',
        operComplete: {
          'command_name': 'IPPing()',
          'command_key': 'second-key',
          'output_args': {'Status': 'Complete'},
        },
      ));

      final result = await future;
      expect(result.commandKey, 'second-key');
      expect(callCount, 2);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('both operate attempts time out → TimeoutException', () async {
      await connectManager();
      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      // Both attempts hang past the HTTP timeout.
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 20));
        return {'commandKey': 'never'};
      });

      expect(
        () => awaiter.executeInSession(
          operateCommand: 'Device.IP.Diagnostics.IPPing()',
          timeout: const Duration(seconds: 60),
        ),
        throwsA(isA<TimeoutException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 60)));

    // -------------------------------------------------------------------------
    // Linger window — ref-count→0 holds the subscription open briefly so a
    // quick re-acquire reuses it without churning the firmware.
    // -------------------------------------------------------------------------
    test('endSharedSession does NOT immediately unsubscribe (linger)',
        () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');
      await awaiter.endSharedSession();

      // Linger timer is pending; teardown has not run yet.
      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));
      expect(awaiter.hasSharedSubscription, isTrue);

      // Force teardown to clean up so subsequent tests start fresh.
      await awaiter.tearDownSharedSessionNow();
    });

    test('re-acquire within linger window reuses existing subscription',
        () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');
      await awaiter.endSharedSession();

      clearInteractions(mockBridge);

      // Re-acquire while still lingering — should NOT issue a new subscribe
      // and must NOT issue an unsubscribe either.
      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');

      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));
      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));

      // Clean up — explicit teardown for assertion stability.
      await awaiter.endSharedSession();
      await awaiter.tearDownSharedSessionNow();
    });

    test('tearDownSharedSessionNow forces immediate teardown', () async {
      await connectManager();

      await awaiter.startSharedSession(referencePath: 'Device.IP.Diagnostics.');
      await awaiter.endSharedSession();

      // Lingering — no unsubscribe yet.
      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));

      await awaiter.tearDownSharedSessionNow();

      verify(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).called(1);
      expect(awaiter.hasSharedSubscription, isFalse);
    });
  });
}
