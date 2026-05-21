import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/speed_test_notifier.dart';

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
    commandKey: 'speed-ping',
    status: 'Complete',
    outputArgs: {
      'AverageResponseTime': '12',
      'SuccessCount': '3',
      'FailureCount': '0',
    },
  );

  final downloadCompleteResult = OperateResult(
    commandName: 'DownloadDiagnostics()',
    commandKey: 'speed-dl',
    status: 'Complete',
    outputArgs: {
      'Status': 'Complete',
      'BOMTime': '2026-05-21T16:00:00.000Z',
      'EOMTime': '2026-05-21T16:00:08.000Z',
      'TestBytesReceived': '100000000',
    },
  );

  final downloadFailedResult = OperateResult(
    commandName: 'DownloadDiagnostics()',
    commandKey: 'speed-dl-err',
    status: 'Complete',
    outputArgs: {
      'Status': 'Error_NoResponse',
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

  group('SpeedTestNotifier', () {
    test('build returns idle state', () async {
      final container = createContainer();
      final state = await container.read(speedTestProvider.future);
      expect(state.step, SpeedTestStep.idle);
      expect(state.selectedServer.name, isNotEmpty);
      expect(state.result, isNull);
      container.dispose();
    });

    test('selectServer updates selected server', () async {
      final container = createContainer();
      await container.read(speedTestProvider.future);

      final newServer = SpeedTestServer.all[2];
      container.read(speedTestProvider.notifier).selectServer(newServer);

      final state = container.read(speedTestProvider).valueOrNull;
      expect(state?.selectedServer, newServer);
      container.dispose();
    });

    test('selectServer is ignored while running', () async {
      final completer = Completer<OperateResult>();
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) => completer.future);

      final container = createContainer();
      // Keep the autoDispose provider alive across this test.
      final sub = container.listen(speedTestProvider, (_, __) {});
      await container.read(speedTestProvider.future);

      final original =
          container.read(speedTestProvider).valueOrNull?.selectedServer;

      final run = container.read(speedTestProvider.notifier).runSpeedTest();
      // Wait for state to flip to running.
      await Future<void>.delayed(Duration.zero);

      container
          .read(speedTestProvider.notifier)
          .selectServer(SpeedTestServer.all[3]);

      final state = container.read(speedTestProvider).valueOrNull;
      expect(state?.selectedServer, original);

      // Cleanup: complete the in-flight ping then await test future.
      completer.complete(pingResult);
      when(() => scope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => downloadCompleteResult);
      await run;
      sub.close();
      container.dispose();
    });

    test('runSpeedTest happy path completes with parsed result', () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => pingResult);
      when(() => scope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => downloadCompleteResult);

      final container = createContainer();
      await container.read(speedTestProvider.future);

      await container.read(speedTestProvider.notifier).runSpeedTest();

      final state = container.read(speedTestProvider).valueOrNull;
      expect(state?.step, SpeedTestStep.completed);
      expect(state?.result, isNotNull);
      expect(state?.result?.latencyMs, 12);
      expect(state?.result?.downloadStatus, 'Complete');
      expect(state?.result?.downloadBps, greaterThan(0));
      // Scope released exactly once for the run.
      verify(() => scope.release()).called(1);
      container.dispose();
    });

    test('runSpeedTest sets error when download status is non-Complete',
        () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => pingResult);
      when(() => scope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => downloadFailedResult);

      final container = createContainer();
      await container.read(speedTestProvider.future);

      await container.read(speedTestProvider.notifier).runSpeedTest();

      final state = container.read(speedTestProvider).valueOrNull;
      expect(state?.step, SpeedTestStep.error);
      expect(state?.errorMessage, contains('Could not connect'));
      container.dispose();
    });

    test('runSpeedTest skips when already running', () async {
      final completer = Completer<OperateResult>();
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) => completer.future);
      when(() => scope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => downloadCompleteResult);

      final container = createContainer();
      await container.read(speedTestProvider.future);

      final first = container.read(speedTestProvider.notifier).runSpeedTest();
      // Second call while first is in flight should be skipped.
      await container.read(speedTestProvider.notifier).runSpeedTest();

      verify(() => executor.acquireScope(
            referencePaths: any(named: 'referencePaths'),
          )).called(1);

      completer.complete(pingResult);
      await first;
      container.dispose();
    });

    test('cancel during run releases scope and resets to idle', () async {
      final pingCompleter = Completer<OperateResult>();
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) => pingCompleter.future);

      final container = createContainer();
      await container.read(speedTestProvider.future);

      final run = container.read(speedTestProvider.notifier).runSpeedTest();
      await Future<void>.delayed(Duration.zero);

      await container.read(speedTestProvider.notifier).cancel();

      final state = container.read(speedTestProvider).valueOrNull;
      expect(state?.step, SpeedTestStep.idle);
      verify(() => scope.release()).called(1);

      // Drain the in-flight run.
      pingCompleter.complete(pingResult);
      when(() => scope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => downloadCompleteResult);
      try {
        await run;
      } catch (_) {}
      container.dispose();
    });

    test('reset returns to idle state when not running', () async {
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => pingResult);
      when(() => scope.downloadDiagnostic(
            downloadUrl: any(named: 'downloadUrl'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => downloadCompleteResult);

      final container = createContainer();
      await container.read(speedTestProvider.future);
      await container.read(speedTestProvider.notifier).runSpeedTest();

      container.read(speedTestProvider.notifier).reset();
      final state = container.read(speedTestProvider).valueOrNull;
      expect(state?.step, SpeedTestStep.idle);
      expect(state?.result, isNull);
      container.dispose();
    });

    test('autoDispose tears down scope when last listener leaves', () async {
      final completer = Completer<OperateResult>();
      when(() => scope.ping(
            host: any(named: 'host'),
            numberOfRepetitions: any(named: 'numberOfRepetitions'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) => completer.future);

      final container = createContainer();
      await container.read(speedTestProvider.future);

      // Hold a subscription so the provider stays alive while we kick off a run.
      final sub = container.listen(speedTestProvider, (_, __) {});
      unawaited(container.read(speedTestProvider.notifier).runSpeedTest());
      await Future<void>.delayed(Duration.zero);

      sub.close();
      // Drain microtasks so onDispose async callbacks run.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(() => scope.release()).called(1);

      // Drain the in-flight ping so the test future does not leak.
      completer.complete(pingResult);
      container.dispose();
    });
  });
}
