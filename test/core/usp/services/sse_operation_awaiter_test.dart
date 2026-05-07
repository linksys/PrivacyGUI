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
}
