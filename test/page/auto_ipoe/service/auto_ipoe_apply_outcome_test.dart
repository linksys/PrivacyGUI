import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';
import 'package:mockito/mockito.dart';

class _MockRouterRepository extends Mock implements RouterRepository {}

class _ControlledAutoIPoEService extends AutoIPoEService {
  _ControlledAutoIPoEService() : super(_MockRouterRepository());

  Object? setError;
  Object? applyError;
  bool applyCalled = false;
  bool lastPnpReflectAfterApply = false;
  int applyCount = 0;
  int statusCallCount = 0;
  int probeCallCount = 0;
  List<Object> statusResults = [];
  List<Object> logResults = [];
  List<Object> probeResults = [];

  @override
  Future<void> setSettings(AutoIPoESettings settings) async {
    if (setError case final error?) {
      throw error;
    }
  }

  @override
  Future<AutoIPoEStatus> apply({
    bool resetFirst = false,
    bool pnpReflectAfterApply = false,
    AutoIPoESettings? settings,
  }) async {
    applyCalled = true;
    lastPnpReflectAfterApply = pnpReflectAfterApply;
    applyCount++;
    if (applyError case final error?) {
      throw error;
    }
    return const AutoIPoEStatus.init();
  }

  @override
  Future<AutoIPoEStatus> getStatus() async {
    statusCallCount++;
    final result = statusResults.removeAt(0);
    if (result is AutoIPoEStatus) {
      return result;
    }
    throw result;
  }

  @override
  Future<AutoIPoELog> getLog() async {
    if (logResults.isEmpty) {
      return const AutoIPoELog.init();
    }
    final result = logResults.removeAt(0);
    if (result is AutoIPoELog) {
      return result;
    }
    throw result;
  }

  @override
  Future<bool> probeInternet({
    String host = '1.1.1.1',
    int pingCount = 3,
    int maxPoll = 15,
    Duration pollDelay = const Duration(seconds: 1),
    Duration? maxDuration,
    bool Function()? shouldContinue,
  }) async {
    probeCallCount++;
    final result = probeResults.removeAt(0);
    if (result is bool) {
      return result;
    }
    throw result;
  }
}

AutoIPoEStatus _runtimeStatus({
  required AutoIPoEApplyState applyState,
  AutoIPoERuntimeType runtimeKind = AutoIPoERuntimeType.none,
  AutoIPoEMode selectedMode = AutoIPoEMode.auto,
  String? lastError,
  bool? retryable,
  AutoIPoEProgressPhase? progressPhase,
  int? progressAttempt,
  int? progressTotal,
  bool? connectivityVerified,
  bool terminalResultSupported = false,
  AutoIPoETerminalResult? terminalResult,
}) {
  return AutoIPoEStatus(
    isEnabled: true,
    isCurrentWANType: true,
    selectedMode: selectedMode,
    applyState: applyState,
    runtimeKind: runtimeKind,
    blockIPv6ManualConfiguration: true,
    isBusy: applyState == AutoIPoEApplyState.applying,
    needsResetBeforeLeaving: true,
    lastError: lastError,
    retryable: retryable,
    progressPhase: progressPhase,
    progressAttempt: progressAttempt,
    progressTotal: progressTotal,
    connectivityVerified: connectivityVerified,
    terminalResultSupported: terminalResultSupported,
    terminalResult: terminalResult,
  );
}

void main() {
  group('isAutoIPoEApplyOutcomeUnknownError', () {
    test('classifies interrupted Apply outcomes for read-only reconciliation',
        () {
      expect(
        isAutoIPoEApplyOutcomeUnknownError(const JNAPSideEffectError()),
        isTrue,
      );
      expect(
        isAutoIPoEApplyOutcomeUnknownError(
          ClientException('connection interrupted'),
        ),
        isTrue,
      );
      expect(
        isAutoIPoEApplyOutcomeUnknownError(
          TimeoutException('response timed out'),
        ),
        isTrue,
      );
    });

    test('does not hide explicit JNAP failures', () {
      expect(
        isAutoIPoEApplyOutcomeUnknownError(
          const JNAPError(
            result: 'ErrorInvalidInput',
            error: 'The requested settings are invalid',
          ),
        ),
        isFalse,
      );
    });
  });

  group('AutoIPoEInternetSettingsBridge.savePnpIPoE', () {
    test('hands accepted Apply side effects to PnP reconciliation', () async {
      final service = _ControlledAutoIPoEService();
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await bridge.savePnpIPoE();

      expect(service.applyCount, 1);
      expect(service.lastPnpReflectAfterApply, isTrue);
    });

    test('surfaces Set transport errors because Apply was not dispatched',
        () async {
      final service = _ControlledAutoIPoEService();
      final error = ClientException('Set request failed');
      service.setError = error;
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.savePnpIPoE(),
        throwsA(
          isA<AutoIPoEApplyNotStarted>().having(
            (value) => value.cause,
            'cause',
            same(error),
          ),
        ),
      );
      expect(service.applyCalled, isFalse);
    });

    test('wraps an interrupted Apply for read-only reconciliation', () async {
      final service = _ControlledAutoIPoEService();
      final error = TimeoutException('Apply response timed out');
      service.applyError = error;
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.savePnpIPoE(),
        throwsA(
          isA<AutoIPoEApplyOutcomeUnknown>()
              .having((value) => value.cause, 'cause', same(error)),
        ),
      );
      expect(service.applyCalled, isTrue);
    });

    test('surfaces an explicit Apply JNAP failure', () async {
      final service = _ControlledAutoIPoEService();
      const error = JNAPError(
        result: 'ErrorInvalidInput',
        error: 'The requested settings are invalid',
      );
      service.applyError = error;
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(bridge.savePnpIPoE(), throwsA(same(error)));
      expect(service.applyCalled, isTrue);
    });
  });

  group('AutoIPoEInternetSettingsBridge completion reconciliation', () {
    test('does not accept a completed log while status is not Active',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(applyState: AutoIPoEApplyState.idle),
        ]
        ..logResults = <Object>[
          const AutoIPoELog(
            content: '### end of logging ###',
            isComplete: true,
            rebootRecommended: false,
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
        ),
        throwsA(isA<AutoIPoERecoveryPending>()),
      );
    });

    test('streams status and log progress throughout bounded reconciliation',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(applyState: AutoIPoEApplyState.applying),
        ]
        ..logResults = <Object>[
          const AutoIPoELog(
            content: 'Waiting for delegated IPv6 prefix',
            isComplete: false,
            rebootRecommended: false,
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final reconciliationProgress = <AutoIPoEReconciliationProgress>[];
      AutoIPoEStatus? progressStatus;
      AutoIPoELog? progressLog;

      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
          onProgress: (status, log) {
            progressStatus = status;
            progressLog = log;
          },
          onReconciliationProgress: reconciliationProgress.add,
        ),
        throwsA(isA<AutoIPoERecoveryPending>()),
      );

      expect(progressStatus?.applyState, AutoIPoEApplyState.applying);
      expect(progressLog?.content, contains('delegated IPv6 prefix'));
      expect(
        reconciliationProgress.map((value) => value.currentStep),
        [1, 2],
      );
    });

    test('does not claim tunnel readiness while status is unreachable',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [ClientException('network restarting')];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final progress = <AutoIPoEReconciliationProgress>[];

      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
          onReconciliationProgress: progress.add,
        ),
        throwsA(isA<AutoIPoERecoveryPending>()),
      );

      expect(progress.map((value) => value.currentStep), [1]);
    });

    test('completes only for a real active tunnel runtime', () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.mape,
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final progress = <AutoIPoEReconciliationProgress>[];

      await bridge.waitForPnpIPoESetupCompletion(
        maxRetry: 1,
        retryDelay: Duration.zero,
        onReconciliationProgress: progress.add,
      );

      expect(progress.map((value) => value.currentStep), [1, 3]);
    });

    test('does not accept Active before the supported terminal result arrives',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.mape,
            terminalResultSupported: true,
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
        ),
        throwsA(isA<AutoIPoERecoveryPending>()),
      );
      expect(service.statusCallCount, 1);
    });

    test('streams structured provider, validation, and attempt progress',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.applying,
            progressPhase: AutoIPoEProgressPhase.detecting,
            terminalResultSupported: true,
          ),
          _runtimeStatus(
            applyState: AutoIPoEApplyState.applying,
            progressPhase: AutoIPoEProgressPhase.provisioning,
            terminalResultSupported: true,
          ),
          _runtimeStatus(
            applyState: AutoIPoEApplyState.applying,
            progressPhase: AutoIPoEProgressPhase.applyingNetwork,
            terminalResultSupported: true,
          ),
          _runtimeStatus(
            applyState: AutoIPoEApplyState.applying,
            progressPhase: AutoIPoEProgressPhase.validatingTunnel,
            terminalResultSupported: true,
          ),
          _runtimeStatus(
            applyState: AutoIPoEApplyState.applying,
            progressPhase: AutoIPoEProgressPhase.checkingInternet,
            progressAttempt: 3,
            progressTotal: 5,
            terminalResultSupported: true,
          ),
          _runtimeStatus(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.mape,
            progressPhase: AutoIPoEProgressPhase.completed,
            connectivityVerified: true,
            terminalResultSupported: true,
            terminalResult: const AutoIPoETerminalResult(
              phase: AutoIPoETerminalPhase.completed,
              operation: AutoIPoETerminalResult.applyOperation,
              exitCode: 0,
              reason: 'Completed',
              connectivityVerified: true,
            ),
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final progress = <AutoIPoEReconciliationProgress>[];

      await bridge.waitForPnpIPoESetupCompletion(
        maxRetry: 6,
        retryDelay: Duration.zero,
        useStructuredProgress: true,
        onReconciliationProgress: progress.add,
      );

      expect(
        progress.map((value) => value.currentStep),
        [1, 1, 2, 3, 4, 4, 5],
      );
      expect(progress[5].phase, AutoIPoEProgressPhase.checkingInternet);
      expect((progress[5].attempt, progress[5].attemptTotal), (3, 5));
    });

    test('both entry points recover across transient router and WiFi loss',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          ClientException('router restarting'),
          TimeoutException('WiFi reconnecting'),
          _runtimeStatus(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.mape,
            progressPhase: AutoIPoEProgressPhase.completed,
            connectivityVerified: true,
            terminalResultSupported: true,
            terminalResult: const AutoIPoETerminalResult(
              phase: AutoIPoETerminalPhase.completed,
              operation: AutoIPoETerminalResult.applyOperation,
              exitCode: 0,
              reason: 'Completed',
              connectivityVerified: true,
            ),
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final progress = <AutoIPoEReconciliationProgress>[];

      await bridge.waitForPnpIPoESetupCompletion(
        maxRetry: 3,
        retryDelay: Duration.zero,
        useStructuredProgress: true,
        onReconciliationProgress: progress.add,
      );

      expect(service.statusCallCount, 3);
      expect(service.applyCount, 0);
      expect(progress.last.currentStep, 5);
    });

    test('scheduled provider retry is distinct and never reapplies', () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.idle,
            lastError: 'StaleFailure',
            retryable: true,
            progressPhase: AutoIPoEProgressPhase.retryScheduled,
            terminalResultSupported: true,
            terminalResult: const AutoIPoETerminalResult(
              phase: AutoIPoETerminalPhase.retryScheduled,
              operation: AutoIPoETerminalResult.applyOperation,
              exitCode: 0,
              reason: 'RetryScheduled',
              connectivityVerified: false,
            ),
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final progress = <AutoIPoEReconciliationProgress>[];

      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 5,
          retryDelay: Duration.zero,
          useStructuredProgress: true,
          onReconciliationProgress: progress.add,
        ),
        throwsA(
          isA<AutoIPoERecoveryPending>()
              .having(
                (error) => error.issue.code,
                'code',
                'RetryScheduled',
              )
              .having(
                (error) => error.issue.recoveryAction,
                'recovery action',
                AutoIPoERecoveryAction.scheduledRetry,
              ),
        ),
      );

      expect(service.statusCallCount, 1);
      expect(service.applyCount, 0);
      expect(progress.last.phase, AutoIPoEProgressPhase.retryScheduled);
    });

    test('structured five-stage progress is opt-in for PnP', () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.mape,
            progressPhase: AutoIPoEProgressPhase.completed,
            connectivityVerified: true,
            terminalResultSupported: true,
            terminalResult: const AutoIPoETerminalResult(
              phase: AutoIPoETerminalPhase.completed,
              operation: AutoIPoETerminalResult.applyOperation,
              exitCode: 0,
              reason: 'Completed',
              connectivityVerified: true,
            ),
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final progress = <AutoIPoEReconciliationProgress>[];

      await bridge.waitForPnpIPoESetupCompletion(
        maxRetry: 1,
        retryDelay: Duration.zero,
        onReconciliationProgress: progress.add,
      );

      expect(progress.map((value) => value.currentStep), [1, 3]);
    });

    test('post-IPoE Internet retry is read-only and completes at step 5',
        () async {
      final service = _ControlledAutoIPoEService()
        ..probeResults = [false, ClientException('restarting'), true];
      final bridge = AutoIPoEInternetSettingsBridge(service);
      final progress = <AutoIPoEReconciliationProgress>[];

      await bridge.waitForPnpIPoEInternetConnectivity(
        maxRetry: 3,
        retryDelay: Duration.zero,
        onReconciliationProgress: progress.add,
      );

      expect(service.probeCallCount, 3);
      expect(service.applyCount, 0);
      expect(
        progress.map((value) => value.currentStep),
        [4, 4, 4, 5],
      );
    });

    test('post-IPoE Internet retry is bounded and never reapplies', () async {
      final service = _ControlledAutoIPoEService()
        ..probeResults = [false, false];
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.waitForPnpIPoEInternetConnectivity(
          maxRetry: 2,
          retryDelay: Duration.zero,
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(service.probeCallCount, 2);
      expect(service.applyCount, 0);
    });

    test('post-IPoE Internet retry also has a wall-clock budget', () async {
      final service = _ControlledAutoIPoEService()..probeResults = [true];
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.waitForPnpIPoEInternetConnectivity(
          maxRetry: 40,
          retryDelay: Duration.zero,
          maxDuration: Duration.zero,
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(service.probeCallCount, 0);
      expect(service.applyCount, 0);
    });

    for (final scenario in <({
      String name,
      AutoIPoERuntimeType runtime,
      AutoIPoEMode mode,
    })>[
      (
        name: 'MAP-E',
        runtime: AutoIPoERuntimeType.mape,
        mode: AutoIPoEMode.auto,
      ),
      (
        name: 'DS-Lite',
        runtime: AutoIPoERuntimeType.dsLite,
        mode: AutoIPoEMode.auto,
      ),
      (
        name: 'static IPIP6',
        runtime: AutoIPoERuntimeType.ipip6,
        mode: AutoIPoEMode.biglobeStaticIp,
      ),
    ]) {
      test('${scenario.name} reaches probe without another Apply', () async {
        final service = _ControlledAutoIPoEService()
          ..statusResults = [
            _runtimeStatus(
              applyState: AutoIPoEApplyState.active,
              runtimeKind: scenario.runtime,
              selectedMode: scenario.mode,
            ),
          ]
          ..probeResults = [true];
        final bridge = AutoIPoEInternetSettingsBridge(service);
        final progress = <AutoIPoEReconciliationProgress>[];

        await bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
          expectedMode: scenario.mode,
          onReconciliationProgress: progress.add,
        );
        await bridge.waitForPnpIPoEInternetConnectivity(
          maxRetry: 1,
          retryDelay: Duration.zero,
          onReconciliationProgress: progress.add,
        );

        expect(progress.map((value) => value.currentStep), [1, 3, 4, 5]);
        expect(service.probeCallCount, 1);
        expect(service.applyCount, 0);
      });
    }

    for (final scenario in <({
      String name,
      AutoIPoERuntimeType runtime,
      AutoIPoEMode mode,
    })>[
      (
        name: 'structured MAP-E',
        runtime: AutoIPoERuntimeType.mape,
        mode: AutoIPoEMode.auto,
      ),
      (
        name: 'structured DS-Lite',
        runtime: AutoIPoERuntimeType.dsLite,
        mode: AutoIPoEMode.auto,
      ),
      (
        name: 'structured static IPIP6',
        runtime: AutoIPoERuntimeType.ipip6,
        mode: AutoIPoEMode.biglobeStaticIp,
      ),
    ]) {
      test('${scenario.name} requires the exact successful terminal tuple',
          () async {
        final service = _ControlledAutoIPoEService()
          ..statusResults = [
            _runtimeStatus(
              applyState: AutoIPoEApplyState.active,
              runtimeKind: scenario.runtime,
              selectedMode: scenario.mode,
              terminalResultSupported: true,
              terminalResult: const AutoIPoETerminalResult(
                phase: AutoIPoETerminalPhase.completed,
                operation: AutoIPoETerminalResult.applyOperation,
                exitCode: 0,
                reason: 'Completed',
                connectivityVerified: true,
              ),
            ),
          ];
        final bridge = AutoIPoEInternetSettingsBridge(service);

        await bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
          expectedMode: scenario.mode,
        );

        expect(service.statusCallCount, 1);
        expect(service.applyCount, 0);
      });
    }

    for (final scenario in <({
      String name,
      AutoIPoERuntimeType runtime,
      AutoIPoEMode mode,
    })>[
      (
        name: 'dynamic MAP-E',
        runtime: AutoIPoERuntimeType.mape,
        mode: AutoIPoEMode.auto,
      ),
      (
        name: 'static IPIP6',
        runtime: AutoIPoERuntimeType.ipip6,
        mode: AutoIPoEMode.biglobeStaticIp,
      ),
    ]) {
      test(
          '${scenario.name} ignores uncorrelated Failed states until exact success',
          () async {
        final absentResult = _runtimeStatus(
          applyState: AutoIPoEApplyState.failed,
          runtimeKind: scenario.runtime,
          selectedMode: scenario.mode,
          lastError: 'ConnectivityFailed',
          retryable: false,
          terminalResultSupported: true,
        );
        final malformedResult = AutoIPoEStatus.fromMap({
          'isEnabled': true,
          'isCurrentWANType': true,
          'selectedMode': scenario.mode.value,
          'applyState': AutoIPoEApplyState.failed.value,
          'runtimeType': scenario.runtime.value,
          'blockIPv6ManualConfiguration': true,
          'isBusy': false,
          'needsResetBeforeLeaving': true,
          'lastError': 'ConnectivityFailed',
          'retryable': false,
          'terminalResultSupported': true,
          'terminalResult': const {
            'phase': 'failed',
            'operation': AutoIPoETerminalResult.applyOperation,
            'exitCode': '1',
            'reason': 'ConnectivityFailed',
            'connectivityVerified': false,
          },
        });
        final mismatchedResult = _runtimeStatus(
          applyState: AutoIPoEApplyState.failed,
          runtimeKind: scenario.runtime,
          selectedMode: scenario.mode,
          lastError: 'ConnectivityFailed',
          retryable: false,
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.failed,
            operation: 'static_ip',
            exitCode: 1,
            reason: 'ConnectivityFailed',
            connectivityVerified: false,
          ),
        );
        final completed = _runtimeStatus(
          applyState: AutoIPoEApplyState.active,
          runtimeKind: scenario.runtime,
          selectedMode: scenario.mode,
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.completed,
            operation: AutoIPoETerminalResult.applyOperation,
            exitCode: 0,
            reason: 'Completed',
            connectivityVerified: true,
          ),
        );
        final service = _ControlledAutoIPoEService()
          ..statusResults = [
            absentResult,
            malformedResult,
            mismatchedResult,
            completed,
          ];
        final bridge = AutoIPoEInternetSettingsBridge(service);

        await bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 4,
          retryDelay: Duration.zero,
          expectedMode: scenario.mode,
        );

        expect(service.statusCallCount, 4);
        expect(service.applyCount, 0);
      });

      test('${scenario.name} accepts an exact correlated terminal failure',
          () async {
        final service = _ControlledAutoIPoEService()
          ..statusResults = [
            _runtimeStatus(
              applyState: AutoIPoEApplyState.active,
              runtimeKind: scenario.runtime,
              selectedMode: scenario.mode,
              terminalResultSupported: true,
              terminalResult: const AutoIPoETerminalResult(
                phase: AutoIPoETerminalPhase.failed,
                operation: AutoIPoETerminalResult.applyOperation,
                exitCode: 1,
                reason: 'ConnectivityFailed',
                connectivityVerified: false,
              ),
            ),
          ];
        final bridge = AutoIPoEInternetSettingsBridge(service);

        await expectLater(
          bridge.waitForPnpIPoESetupCompletion(
            maxRetry: 5,
            retryDelay: Duration.zero,
            expectedMode: scenario.mode,
          ),
          throwsA(
            isA<AutoIPoERecoveryPending>().having(
              (error) => error.issue.code,
              'code',
              'ConnectivityFailed',
            ),
          ),
        );
        expect(service.statusCallCount, 1);
      });

      test('${scenario.name} surfaces exact Busy without waiting for timeout',
          () async {
        final service = _ControlledAutoIPoEService()
          ..statusResults = [
            _runtimeStatus(
              applyState: AutoIPoEApplyState.failed,
              runtimeKind: scenario.runtime,
              selectedMode: scenario.mode,
              lastError: 'StaleFailure',
              retryable: false,
              terminalResultSupported: true,
              terminalResult: const AutoIPoETerminalResult(
                phase: AutoIPoETerminalPhase.busy,
                operation: AutoIPoETerminalResult.applyOperation,
                exitCode: 75,
                reason: 'Busy',
                connectivityVerified: false,
              ),
            ),
          ];
        final bridge = AutoIPoEInternetSettingsBridge(service);

        await expectLater(
          bridge.waitForPnpIPoESetupCompletion(
            maxRetry: 5,
            retryDelay: Duration.zero,
            expectedMode: scenario.mode,
          ),
          throwsA(
            isA<AutoIPoERecoveryPending>()
                .having(
                  (error) => error.issue.code,
                  'code',
                  'Busy',
                )
                .having(
                  (error) => error.issue.recoveryAction,
                  'recovery action',
                  AutoIPoERecoveryAction.retrySetup,
                ),
          ),
        );
        expect(service.statusCallCount, 1);
        expect(service.applyCount, 0);
      });
    }

    for (final result in const [
      AutoIPoETerminalResult(
        phase: AutoIPoETerminalPhase.completed,
        operation: 'static_ip',
        exitCode: 0,
        reason: 'Completed',
        connectivityVerified: true,
      ),
      AutoIPoETerminalResult(
        phase: AutoIPoETerminalPhase.completed,
        operation: AutoIPoETerminalResult.applyOperation,
        exitCode: 1,
        reason: 'Completed',
        connectivityVerified: true,
      ),
    ]) {
      test(
          'terminal result ${result.operation}/${result.exitCode} remains unconfirmed',
          () async {
        final service = _ControlledAutoIPoEService()
          ..statusResults = [
            _runtimeStatus(
              applyState: AutoIPoEApplyState.active,
              runtimeKind: AutoIPoERuntimeType.mape,
              terminalResultSupported: true,
              terminalResult: result,
            ),
          ];
        final bridge = AutoIPoEInternetSettingsBridge(service);

        await expectLater(
          bridge.waitForPnpIPoESetupCompletion(
            maxRetry: 1,
            retryDelay: Duration.zero,
          ),
          throwsA(isA<AutoIPoERecoveryPending>()),
        );
      });
    }

    test('surfaces missing settings as terminal and highlights mode group',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.failed,
            lastError: 'MissingV6PlusStaticIPSettings',
            retryable: false,
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
        ),
        throwsA(
          isA<AutoIPoETerminalFailure>().having(
            (error) => error.issue.fieldGroup,
            'field group',
            AutoIPoEFieldGroup.v6PlusStaticIp,
          ),
        ),
      );
    });

    test('keeps retryable DAD failures correlated without another Apply',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.failed,
            lastError: 'MapCeDADTimeout',
            retryable: true,
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await bridge.savePnpIPoE();
      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 1,
          retryDelay: Duration.zero,
        ),
        throwsA(
          isA<AutoIPoERecoveryPending>().having(
            (error) => error.issue.recoveryAction,
            'recovery action',
            AutoIPoERecoveryAction.retrySetup,
          ),
        ),
      );
      expect(service.applyCount, 1);
    });

    test('does not poll a terminal retryable ConnectivityFailed worker',
        () async {
      final service = _ControlledAutoIPoEService()
        ..statusResults = [
          _runtimeStatus(
            applyState: AutoIPoEApplyState.failed,
            lastError: 'ConnectivityFailed',
            retryable: true,
          ),
        ];
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.waitForPnpIPoESetupCompletion(
          maxRetry: 5,
          retryDelay: Duration.zero,
        ),
        throwsA(
          isA<AutoIPoERecoveryPending>().having(
            (error) => error.issue.recoveryAction,
            'recovery action',
            AutoIPoERecoveryAction.retrySetup,
          ),
        ),
      );

      expect(service.statusCallCount, 1);
      expect(service.applyCount, 0);
    });
  });

  group('Advanced Auto-IPoE dispatch', () {
    test('uses the same unknown-outcome protection after Apply dispatch',
        () async {
      final service = _ControlledAutoIPoEService()
        ..applyError = TimeoutException('Apply response timed out');
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.saveIPoEInternetSettings(
          settings: const AutoIPoESettings.init().copyWith(
            isEnabled: true,
            selectedMode: AutoIPoEMode.auto,
          ),
          originalWanType: WanType.dhcp,
        ),
        throwsA(isA<AutoIPoEApplyOutcomeUnknown>()),
      );
      expect(service.applyCount, 1);
    });

    test('marks an interrupted Set as safe to submit from the form', () async {
      final service = _ControlledAutoIPoEService()
        ..setError = ClientException('Set request failed');
      final bridge = AutoIPoEInternetSettingsBridge(service);

      await expectLater(
        bridge.saveIPoEInternetSettings(
          settings: const AutoIPoESettings.init(),
          originalWanType: WanType.dhcp,
        ),
        throwsA(isA<AutoIPoEApplyNotStarted>()),
      );
      expect(service.applyCount, 0);
    });
  });
}
