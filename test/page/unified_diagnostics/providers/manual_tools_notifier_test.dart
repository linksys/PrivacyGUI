import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/manual_tools_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/manual_tools_notifier.dart';

class _MockExecutor extends Mock implements NetworkDiagnosticsExecutor {}

class _MockScope extends Mock implements DiagnosticScope {}

void main() {
  late _MockExecutor executor;
  late _MockScope scope;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

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
    executor = _MockExecutor();
    scope = _MockScope();
    when(() => executor.acquireScope(
          referencePaths: any(named: 'referencePaths'),
        )).thenAnswer((_) async => scope);
    when(() => scope.isReleased).thenReturn(false);
    when(() => scope.release()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        networkDiagnosticsExecutorProvider.overrideWithValue(executor),
      ],
    );
  }

  group('ManualToolsNotifier', () {
    test('build returns idle state with no fetch', () async {
      final container = createContainer();
      final state = await container.read(manualToolsProvider.future);
      expect(state.status, DiagnosticStatus.idle);
      expect(state.host, isEmpty);
      expect(state.pingResult, isNull);
      expect(state.tracerouteResult, isNull);
      verifyNever(() => executor.acquireScope(
            referencePaths: any(named: 'referencePaths'),
          ));
      container.dispose();
    });

    test('updateHost sets host and clears error', () async {
      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('8.8.8.8');

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.host, '8.8.8.8');
      container.dispose();
    });

    test('updatePingCount changes ping repetitions', () async {
      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updatePingCount(5);

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.pingCount, 5);
      container.dispose();
    });

    test('updateMaxHops changes traceroute max hops', () async {
      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateMaxHops(15);

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.maxHops, 15);
      container.dispose();
    });

    test('switchTab changes active tab', () async {
      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container
          .read(manualToolsProvider.notifier)
          .switchTab(DiagnosticType.traceroute);

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.activeTab, DiagnosticType.traceroute);
      container.dispose();
    });

    test('runPing skips if host is empty', () async {
      final container = createContainer();
      await container.read(manualToolsProvider.future);

      await container.read(manualToolsProvider.notifier).runPing();

      verifyNever(() => executor.acquireScope(
            referencePaths: any(named: 'referencePaths'),
          ));
      verifyNever(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          ));
      container.dispose();
    });

    test('runPing acquires scope and parses result', () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => pingResult);

      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('8.8.8.8');
      await container.read(manualToolsProvider.notifier).runPing();

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.completed);
      expect(state?.pingResult, isNotNull);
      expect(state?.pingResult?.successCount, 3);
      expect(state?.pingResult?.avgResponseTime, 42);
      verify(() => executor.acquireScope(
            referencePaths: any(named: 'referencePaths'),
          )).called(1);
      verify(() => scope.ping(
            host: '8.8.8.8',
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).called(1);
      container.dispose();
    });

    test('runPing reuses scope across multiple invocations', () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => pingResult);

      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('8.8.8.8');
      await container.read(manualToolsProvider.notifier).runPing();
      await container.read(manualToolsProvider.notifier).runPing();

      verify(() => executor.acquireScope(
            referencePaths: any(named: 'referencePaths'),
          )).called(1);
      verify(() => scope.ping(
            host: '8.8.8.8',
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).called(2);
      container.dispose();
    });

    test('runPing timeout sets error state', () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenThrow(TimeoutException('timeout'));

      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('8.8.8.8');
      await container.read(manualToolsProvider.notifier).runPing();

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.error);
      expect(state?.errorMessage, contains('timed out'));
      container.dispose();
    });

    test('runPing generic error sets error state', () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenThrow(Exception('network error'));

      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('8.8.8.8');
      await container.read(manualToolsProvider.notifier).runPing();

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.error);
      expect(state?.errorMessage, contains('Ping failed'));
      container.dispose();
    });

    test('runTraceroute executes and parses hops', () async {
      when(() => scope.traceRoute(
            host: any(named: 'host'),
            maxHopCount: any(named: 'maxHopCount'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => tracerouteResult);

      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('google.com');
      await container.read(manualToolsProvider.notifier).runTraceroute();

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.completed);
      expect(state?.tracerouteResult, isNotNull);
      expect(state?.tracerouteResult?.hops, hasLength(2));
      expect(state?.tracerouteResult?.hops[0].host, 'gateway.local');
      expect(state?.tracerouteResult?.hops[1].hostAddress, '10.0.0.1');
      verify(() => scope.traceRoute(
            host: 'google.com',
            maxHopCount: any(named: 'maxHopCount'),
            timeout: any(named: 'timeout'),
          )).called(1);
      container.dispose();
    });

    test('runTraceroute timeout sets error state', () async {
      when(() => scope.traceRoute(
            host: any(named: 'host'),
            maxHopCount: any(named: 'maxHopCount'),
            timeout: any(named: 'timeout'),
          )).thenThrow(TimeoutException('timeout'));

      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('google.com');
      await container.read(manualToolsProvider.notifier).runTraceroute();

      final state = container.read(manualToolsProvider).valueOrNull;
      expect(state?.status, DiagnosticStatus.error);
      expect(state?.errorMessage, contains('Traceroute timed out'));
      container.dispose();
    });

    test('runPing skips if already running', () async {
      final completer = Completer<OperateResult>();
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) => completer.future);

      final container = createContainer();
      await container.read(manualToolsProvider.future);

      container.read(manualToolsProvider.notifier).updateHost('8.8.8.8');
      final firstPing = container.read(manualToolsProvider.notifier).runPing();
      await container.read(manualToolsProvider.notifier).runPing();

      verify(() => scope.ping(
            host: '8.8.8.8',
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).called(1);

      completer.complete(pingResult);
      await firstPing;
      container.dispose();
    });

    test('disposing container releases scope', () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => pingResult);

      final container = createContainer();
      await container.read(manualToolsProvider.future);
      container.read(manualToolsProvider.notifier).updateHost('8.8.8.8');
      await container.read(manualToolsProvider.notifier).runPing();

      container.dispose();
      // Allow microtask queue to drain so onDispose async callbacks run.
      await Future<void>.delayed(Duration.zero);

      verify(() => scope.release()).called(1);
    });
  });
}
