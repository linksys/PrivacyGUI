import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/page/network_diagnostics/models/network_diagnostics_ui_model.dart';
import 'package:privacy_gui/page/network_diagnostics/providers/usp_network_diagnostics_notifier.dart';

/// Fake SseOperationAwaiter that records calls and returns canned results.
class FakeSseOperationAwaiter implements SseOperationAwaiter {
  OperateResult? executeResult;
  Object? executeError;
  int executeCallCount = 0;
  String? lastOperateCommand;
  Map<String, String>? lastArgs;

  @override
  Future<OperateResult> execute({
    required String operateCommand,
    required String referencePath,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    executeCallCount++;
    lastOperateCommand = operateCommand;
    lastArgs = args;
    if (executeError != null) throw executeError!;
    return executeResult!;
  }

  @override
  Future<void> executeNoWait({
    required String operateCommand,
    Map<String, String> args = const {},
  }) async {}

  @override
  Future<void> startSharedSession({required String referencePath}) async {}

  @override
  Future<void> endSharedSession() async {}

  @override
  Future<OperateResult> executeInSession({
    required String operateCommand,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    return execute(
      operateCommand: operateCommand,
      referencePath: '',
      args: args,
      timeout: timeout,
    );
  }
}

void main() {
  late FakeSseOperationAwaiter fakeAwaiter;

  final pingResult = OperateResult(
    commandName: 'IPPing()',
    commandKey: 'test-key',
    status: 'Complete',
    outputArgs: {
      'SuccessCount': '3',
      'FailureCount': '0',
      'AverageResponseTime': '42',
      'MinimumResponseTime': '30',
      'MaximumResponseTime': '55',
    },
  );

  final tracerouteResult = OperateResult(
    commandName: 'TraceRoute()',
    commandKey: 'test-key-2',
    status: 'Complete',
    outputArgs: {
      'RouteHops.1.Host': 'gateway.local',
      'RouteHops.1.HostAddress': '192.168.1.1',
      'RouteHops.1.RTTimes': '1,2,3',
      'RouteHops.2.Host': 'isp.net',
      'RouteHops.2.HostAddress': '10.0.0.1',
      'RouteHops.2.RTTimes': '10,12,11',
    },
  );

  setUp(() {
    fakeAwaiter = FakeSseOperationAwaiter();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        sseOperationAwaiterProvider.overrideWithValue(fakeAwaiter),
      ],
    );
    return container;
  }

  group('UspNetworkDiagnosticsNotifier', () {
    test('build returns idle state with no fetch', () async {
      final container = createContainer();
      final state = await container.read(uspNetworkDiagnosticsProvider.future);
      expect(state.status, DiagnosticStatus.idle);
      expect(state.host, isEmpty);
      expect(state.pingResult, isNull);
      expect(state.tracerouteResult, isNull);
      container.dispose();
    });

    test('updateHost sets host and clears error', () async {
      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .updateHost('8.8.8.8');

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.host, '8.8.8.8');
      container.dispose();
    });

    test('updatePingCount changes ping repetitions', () async {
      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container.read(uspNetworkDiagnosticsProvider.notifier).updatePingCount(5);

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.pingCount, 5);
      container.dispose();
    });

    test('updateMaxHops changes traceroute max hops', () async {
      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container.read(uspNetworkDiagnosticsProvider.notifier).updateMaxHops(15);

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.maxHops, 15);
      container.dispose();
    });

    test('switchTab changes active tab', () async {
      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .switchTab(DiagnosticType.traceroute);

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.activeTab, DiagnosticType.traceroute);
      container.dispose();
    });

    test('runPing skips if host is empty', () async {
      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      await container.read(uspNetworkDiagnosticsProvider.notifier).runPing();

      expect(fakeAwaiter.executeCallCount, 0);
      container.dispose();
    });

    test('runPing executes and parses result', () async {
      fakeAwaiter.executeResult = pingResult;

      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .updateHost('8.8.8.8');
      await container.read(uspNetworkDiagnosticsProvider.notifier).runPing();

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.completed);
      expect(state?.pingResult, isNotNull);
      expect(state?.pingResult?.successCount, 3);
      expect(state?.pingResult?.avgResponseTime, 42);
      expect(fakeAwaiter.executeCallCount, 1);
      expect(fakeAwaiter.lastOperateCommand, 'Device.IP.Diagnostics.IPPing()');
      container.dispose();
    });

    test('runPing timeout sets error state', () async {
      fakeAwaiter.executeError = TimeoutException('timeout');

      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .updateHost('8.8.8.8');
      await container.read(uspNetworkDiagnosticsProvider.notifier).runPing();

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.error);
      expect(state?.errorMessage, contains('timed out'));
      container.dispose();
    });

    test('runPing generic error sets error state', () async {
      fakeAwaiter.executeError = Exception('network error');

      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .updateHost('8.8.8.8');
      await container.read(uspNetworkDiagnosticsProvider.notifier).runPing();

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.error);
      expect(state?.errorMessage, contains('Ping failed'));
      container.dispose();
    });

    test('runTraceroute executes and parses hops', () async {
      fakeAwaiter.executeResult = tracerouteResult;

      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .updateHost('google.com');
      await container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .runTraceroute();

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.completed);
      expect(state?.tracerouteResult, isNotNull);
      expect(state?.tracerouteResult?.hops, hasLength(2));
      expect(state?.tracerouteResult?.hops[0].host, 'gateway.local');
      expect(state?.tracerouteResult?.hops[1].hostAddress, '10.0.0.1');
      container.dispose();
    });

    test('runTraceroute timeout sets error state', () async {
      fakeAwaiter.executeError = TimeoutException('timeout');

      final container = createContainer();
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .updateHost('google.com');
      await container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .runTraceroute();

      final state = container.read(uspNetworkDiagnosticsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.error);
      expect(state?.errorMessage, contains('Traceroute timed out'));
      container.dispose();
    });

    test('runPing skips if already running', () async {
      // Simulate a long-running execute by using a completer
      final completer = Completer<OperateResult>();
      fakeAwaiter.executeResult = null;
      // Override execute to block
      final slowAwaiter = _SlowSseOperationAwaiter(completer.future);

      final container = ProviderContainer(
        overrides: [
          sseOperationAwaiterProvider.overrideWithValue(slowAwaiter),
        ],
      );
      await container.read(uspNetworkDiagnosticsProvider.future);

      container
          .read(uspNetworkDiagnosticsProvider.notifier)
          .updateHost('8.8.8.8');

      // Start first ping (won't complete because completer not resolved)
      final firstPing =
          container.read(uspNetworkDiagnosticsProvider.notifier).runPing();

      // Second ping should skip because status is running
      await container.read(uspNetworkDiagnosticsProvider.notifier).runPing();
      expect(slowAwaiter.executeCallCount, 1); // Only first call went through

      // Resolve to clean up
      completer.complete(pingResult);
      await firstPing;
      container.dispose();
    });
  });
}

/// Helper: an awaiter that blocks execute() until a Future completes.
class _SlowSseOperationAwaiter implements SseOperationAwaiter {
  final Future<OperateResult> _future;
  int executeCallCount = 0;

  _SlowSseOperationAwaiter(this._future);

  @override
  Future<OperateResult> execute({
    required String operateCommand,
    required String referencePath,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    executeCallCount++;
    return _future;
  }

  @override
  Future<void> executeNoWait({
    required String operateCommand,
    Map<String, String> args = const {},
  }) async {}

  @override
  Future<void> startSharedSession({required String referencePath}) async {}

  @override
  Future<void> endSharedSession() async {}

  @override
  Future<OperateResult> executeInSession({
    required String operateCommand,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    return execute(
      operateCommand: operateCommand,
      referencePath: '',
      args: args,
      timeout: timeout,
    );
  }
}
