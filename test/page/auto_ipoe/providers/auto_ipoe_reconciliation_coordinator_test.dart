// Unit tests for the reconciliation coordinator.
//
// This logic used to live in two widget State classes, fenced by private
// generation counters, which is why none of it had tests: the interesting cases
// are "a newer attempt superseded this one mid-await" and "the polling window
// ended but the worker is still running", and neither is reachable from a
// widget test without racing the framework.
//
// The invariant every case here protects is that following an Apply never
// dispatches one. The fake fails the test if anything asks it to save.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_reconciliation_coordinator.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';

/// Status shaped like new firmware: it reports the structured terminal result,
/// so the legacy LinksysNow probe is not needed.
AutoIPoEStatus _newFirmwareStatus() => const AutoIPoEStatus.init().copyWith(
      terminalResultSupported: true,
      terminalResult: AutoIPoETerminalResult(
        phase: AutoIPoETerminalPhase.completed,
        operation: AutoIPoETerminalResult.applyOperation,
        exitCode: 0,
        reason: 'Completed',
        connectivityVerified: true,
      ),
    );

/// Status shaped like older firmware: no structured contract, so the fallback
/// probe still has to run.
AutoIPoEStatus _legacyStatus() => const AutoIPoEStatus.init();

AutoIPoEIssue _issue(AutoIPoERecoveryAction action, {bool retryable = true}) =>
    AutoIPoEIssue(
      category: AutoIPoEIssueCategory.retryable,
      code: 'Code',
      retryable: retryable,
      recoveryAction: action,
    );

class _FakeBridge extends Fake implements AutoIPoEInternetSettingsBridge {
  _FakeBridge({
    required this.waitOutcomes,
    this.runtimeStatus,
    this.progressToEmit = const [],
  });

  /// One entry per expected call: null completes normally, an Object is thrown.
  final List<Object?> waitOutcomes;

  /// Reported through `onProgress` so the coordinator can decide about the
  /// legacy probe.
  final AutoIPoEStatus? runtimeStatus;

  final List<AutoIPoEReconciliationProgress> progressToEmit;

  int waitCalls = 0;
  int legacyProbeCalls = 0;

  @override
  Future<AutoIPoELog> waitForPnpIPoESetupCompletion({
    int maxRetry = 80,
    Duration retryDelay = const Duration(seconds: 3),
    AutoIPoEMode? expectedMode,
    bool useStructuredProgress = false,
    AutoIPoEProgressCallback? onProgress,
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
  }) async {
    final outcome = waitOutcomes[waitCalls];
    waitCalls++;
    for (final progress in progressToEmit) {
      onReconciliationProgress?.call(progress);
    }
    if (runtimeStatus != null) {
      onProgress?.call(runtimeStatus!, const AutoIPoELog.init());
    }
    if (outcome != null) {
      throw outcome;
    }
    return const AutoIPoELog.init();
  }

  @override
  Future<void> waitForPnpIPoEInternetConnectivity({
    int maxRetry = 40,
    Duration retryDelay = const Duration(seconds: 5),
    Duration maxDuration = const Duration(minutes: 5),
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
    bool Function()? shouldContinue,
  }) async {
    legacyProbeCalls++;
  }

  // Anything that would dispatch an Apply is a test failure, not a stub.
  @override
  Future<void> saveIPoEInternetSettings({
    required AutoIPoESettings settings,
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) async =>
      fail('reconciliation must never dispatch Apply');

  @override
  Future<void> savePnpIPoE({AutoIPoESettings? settings}) async =>
      fail('reconciliation must never dispatch Apply');
}

void main() {
  AutoIPoEReconciliationCoordinator coordinator(
    _FakeBridge bridge, {
    Future<void> Function()? verifyInternet,
  }) =>
      AutoIPoEReconciliationCoordinator(
        bridge: bridge,
        verifyInternet: verifyInternet ?? () async {},
      );

  group('shouldRunLegacyPnpIPoEConnectivityProbe', () {
    test('runs for firmware without the structured contract', () {
      expect(shouldRunLegacyPnpIPoEConnectivityProbe(_legacyStatus()), isTrue);
    });

    test('is skipped once the backend confirms connectivity itself', () {
      expect(
        shouldRunLegacyPnpIPoEConnectivityProbe(_newFirmwareStatus()),
        isFalse,
      );
    });
  });

  group('follow', () {
    test('completes and skips the duplicate probe on new firmware', () async {
      final bridge = _FakeBridge(
        waitOutcomes: [null],
        runtimeStatus: _newFirmwareStatus(),
      );

      final outcome = await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
      );

      expect(outcome, isA<AutoIPoEReconciliationCompleted>());
      expect(bridge.waitCalls, 1);
      expect(bridge.legacyProbeCalls, 0);
    });

    test('keeps the fallback probe for legacy firmware', () async {
      final bridge =
          _FakeBridge(waitOutcomes: [null], runtimeStatus: _legacyStatus());

      final outcome = await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
      );

      expect(outcome, isA<AutoIPoEReconciliationCompleted>());
      expect(bridge.legacyProbeCalls, 1);
    });

    test('polls again when a window ends with the worker still running',
        () async {
      final bridge = _FakeBridge(
        waitOutcomes: [
          AutoIPoERecoveryPending(
              _issue(AutoIPoERecoveryAction.continueChecking)),
          null,
        ],
        runtimeStatus: _newFirmwareStatus(),
      );
      final windowsEnded = <AutoIPoEIssue>[];

      final outcome = await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
        onPollingWindowEnded: windowsEnded.add,
      );

      // Two read-only windows, one Apply -- the one the caller already sent.
      expect(bridge.waitCalls, 2);
      expect(windowsEnded, hasLength(1));
      expect(outcome, isA<AutoIPoEReconciliationCompleted>());
    });

    test('stops looping as soon as the attempt is superseded', () async {
      var current = true;
      final bridge = _FakeBridge(
        waitOutcomes: [
          AutoIPoERecoveryPending(
              _issue(AutoIPoERecoveryAction.continueChecking)),
          null,
        ],
      );

      final outcome = await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        // Goes stale the moment the first window reports back.
        isCurrent: () => current,
        onPollingWindowEnded: (_) => current = false,
      );

      expect(outcome, isA<AutoIPoEReconciliationCancelled>());
      // The second window never opened, so nothing can overwrite the state that
      // replaced this attempt.
      expect(bridge.waitCalls, 1);
    });

    test('reports a superseded success as cancelled, not completed', () async {
      var current = true;
      final bridge = _FakeBridge(
        waitOutcomes: [null],
        runtimeStatus: _newFirmwareStatus(),
      );

      final outcome = await coordinator(
        bridge,
        verifyInternet: () async => current = false,
      ).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => current,
      );

      expect(outcome, isA<AutoIPoEReconciliationCancelled>());
    });

    test('drops progress from a superseded attempt', () async {
      var current = true;
      final bridge = _FakeBridge(
        waitOutcomes: [null],
        runtimeStatus: _newFirmwareStatus(),
        progressToEmit: const [
          AutoIPoEReconciliationProgress.connectivityChecking(
              attempt: 1, attemptTotal: 30),
        ],
      );
      final seen = <AutoIPoEReconciliationProgress>[];
      current = false;

      await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => current,
        onProgress: seen.add,
      );

      expect(seen, isEmpty);
    });

    test('surfaces a terminal failure as terminal', () async {
      final bridge = _FakeBridge(waitOutcomes: [
        AutoIPoETerminalFailure(
            _issue(AutoIPoERecoveryAction.retrySetup, retryable: false)),
      ]);

      final outcome = await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
      );

      expect(outcome, isA<AutoIPoEReconciliationFailed>());
      expect((outcome as AutoIPoEReconciliationFailed).terminal, isTrue);
    });

    test('surfaces a retry-setup pending failure as recoverable', () async {
      final bridge = _FakeBridge(waitOutcomes: [
        AutoIPoERecoveryPending(_issue(AutoIPoERecoveryAction.retrySetup)),
      ]);

      final outcome = await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
      );

      expect(outcome, isA<AutoIPoEReconciliationFailed>());
      expect((outcome as AutoIPoEReconciliationFailed).terminal, isFalse);
    });

    test('separates a reported no-internet from an expired budget', () async {
      final reported = _FakeBridge(
          waitOutcomes: [null], runtimeStatus: _newFirmwareStatus());
      final reportedOutcome = await coordinator(
        reported,
        verifyInternet: () async => throw ExceptionNoInternetConnection(),
      ).follow(expectedMode: AutoIPoEMode.auto, isCurrent: () => true);

      expect(
        (reportedOutcome as AutoIPoEReconciliationNoInternet).cause,
        AutoIPoENoInternetCause.reported,
      );

      final timedOut = _FakeBridge(
          waitOutcomes: [null], runtimeStatus: _newFirmwareStatus());
      final timedOutOutcome = await coordinator(
        timedOut,
        verifyInternet: () async => throw TimeoutException('budget'),
      ).follow(expectedMode: AutoIPoEMode.auto, isCurrent: () => true);

      expect(
        (timedOutOutcome as AutoIPoEReconciliationNoInternet).cause,
        AutoIPoENoInternetCause.timedOut,
      );
    });

    test('maps an unexpected error through the issue mapper', () async {
      final bridge = _FakeBridge(waitOutcomes: [StateError('boom')]);

      final outcome = await coordinator(bridge).follow(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
      );

      expect(outcome, isA<AutoIPoEReconciliationFailed>());
    });
  });
}
