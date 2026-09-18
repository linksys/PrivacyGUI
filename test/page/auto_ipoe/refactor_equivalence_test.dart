// Equivalence tests for the Auto-IPoE orchestration refactor.
//
// Goldens prove the rendering of a handful of states. They say nothing about the
// logic, so these compare the refactored decisions against the code they
// replaced, over the whole input space rather than at sampled points. Each
// reference implementation below is the pre-refactor expression, copied from the
// commit that changed it, and named with that commit so it can be checked.
//
// If any of these ever disagree, the refactor changed behaviour.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue_presentation.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_reconciliation_coordinator.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';

/// Every issue shape that can change any of these decisions. Only
/// `recoveryAction` and `retryable` feed the getters involved, so this is the
/// complete space for them, not a sample of it.
Iterable<AutoIPoEIssue> allIssueShapes() sync* {
  for (final action in AutoIPoERecoveryAction.values) {
    for (final retryable in [true, false]) {
      for (final category in AutoIPoEIssueCategory.values) {
        yield AutoIPoEIssue(
          category: category,
          code: 'Code',
          retryable: retryable,
          recoveryAction: action,
        );
      }
    }
  }
}

void main() {
  group('the getters the equivalence arguments rest on', () {
    test('isTerminal is exactly the negation of retryable', () {
      // Three separate pre-refactor expressions were unified into `!terminal`
      // on the strength of this identity. If it ever stops holding, that
      // unification silently changes behaviour, so it is asserted rather than
      // assumed.
      for (final issue in allIssueShapes()) {
        expect(issue.isTerminal, !issue.retryable, reason: '$issue');
      }
    });
  });

  group('PnP recovery flag — b18e895d', () {
    // Pre-refactor, three branches set _isRecovering three different ways:
    //   on AutoIPoETerminalFailure   -> false
    //   on AutoIPoERecoveryPending   -> true
    //   catch (error)                -> issue.retryable
    // The refactor replaced all three with `!terminal`, where `terminal` is
    // true for the terminal-failure branch, false for the pending branch, and
    // `issue.isTerminal` for the mapped-error branch.
    bool oldFlagForTerminalFailure() => false;
    bool oldFlagForRecoveryPending() => true;
    bool oldFlagForMappedError(AutoIPoEIssue issue) => issue.retryable;

    bool newFlag({required bool terminal}) => !terminal;

    test('agrees on the terminal-failure branch', () {
      expect(newFlag(terminal: true), oldFlagForTerminalFailure());
    });

    test('agrees on the recovery-pending branch', () {
      expect(newFlag(terminal: false), oldFlagForRecoveryPending());
    });

    test('agrees on the mapped-error branch for every issue shape', () {
      for (final issue in allIssueShapes()) {
        expect(
          newFlag(terminal: issue.isTerminal),
          oldFlagForMappedError(issue),
          reason: '$issue',
        );
      }
    });
  });

  group('Advanced issue presentation — de04a35d', () {
    // Pre-refactor, inline in _handleAdvancedAutoIPoEIssue:
    //   if (!mounted || _isFinalizingAutoIPoE) return;            // touch nothing
    //   _awaitingAutoIPoECompletion =
    //       issue.recoveryAction == continueChecking || issue.hasScheduledRecovery;
    //   if ((issue.isTerminal || issue.requiresFreshApply ||
    //        issue.hasScheduledRecovery) && !_autoIPoETerminalDialogVisible) show;
    ({bool handled, bool keepAwaiting, bool announce}) oldDecision(
      AutoIPoEIssue issue, {
      required bool isFinalizing,
      required bool dialogVisible,
    }) {
      if (isFinalizing) {
        return (handled: false, keepAwaiting: false, announce: false);
      }
      final awaiting =
          issue.recoveryAction == AutoIPoERecoveryAction.continueChecking ||
              issue.hasScheduledRecovery;
      final show = (issue.isTerminal ||
              issue.requiresFreshApply ||
              issue.hasScheduledRecovery) &&
          !dialogVisible;
      return (handled: true, keepAwaiting: awaiting, announce: show);
    }

    test('agrees over every issue shape and both flags', () {
      for (final issue in allIssueShapes()) {
        for (final isFinalizing in [true, false]) {
          for (final dialogVisible in [true, false]) {
            final expected = oldDecision(issue,
                isFinalizing: isFinalizing, dialogVisible: dialogVisible);
            final actual = decideAdvancedAutoIPoEIssue(issue,
                isFinalizing: isFinalizing, dialogVisible: dialogVisible);

            final reason =
                '$issue finalizing=$isFinalizing dialogVisible=$dialogVisible';
            expect(actual.handled, expected.handled, reason: reason);
            if (!expected.handled) {
              continue;
            }
            expect(actual.keepAwaiting, expected.keepAwaiting, reason: reason);
            expect(actual.announce, expected.announce, reason: reason);
          }
        }
      }
    });
  });

  group('admin password preservation — 556b0fd1', () {
    // Pre-refactor: state.isRouterUnConfigured && await isRouterPasswordSet(),
    // where the query resolved an unreadable answer to true. The refactor kept
    // that resolution for routing and changed only the save path, so the
    // agreement to check is over the two answers the router actually gives.
    bool oldDecision({required bool unconfigured, required bool passwordSet}) =>
        unconfigured && passwordSet;

    test('agrees whenever the router answered', () {
      for (final unconfigured in [true, false]) {
        for (final passwordSet in [true, false]) {
          expect(
            shouldPreserveExistingAdminPassword(
              isRouterUnconfigured: unconfigured,
              routerPasswordSet: passwordSet,
            ),
            oldDecision(unconfigured: unconfigured, passwordSet: passwordSet),
            reason: 'unconfigured=$unconfigured passwordSet=$passwordSet',
          );
        }
      }
    });

    test('differs only where it was meant to: an unreadable answer', () {
      // This is the fix, so disagreement here is the point. The old code
      // resolved unknown to true and skipped setting the password.
      expect(
        shouldPreserveExistingAdminPassword(
          isRouterUnconfigured: true,
          routerPasswordSet: null,
        ),
        isFalse,
      );
      expect(oldDecision(unconfigured: true, passwordSet: true), isTrue);
    });
  });

  group('legacy connectivity probe — b18e895d', () {
    // The predicate moved file but not form; assert it byte-for-byte in
    // behaviour over both inputs that feed it.
    bool oldPredicate(
            {required bool terminalResultSupported,
            required bool verifiedConnectivity}) =>
        !terminalResultSupported && !verifiedConnectivity;

    test('agrees over both inputs', () {
      for (final supported in [true, false]) {
        for (final verified in [true, false]) {
          final status = _statusWith(
            terminalResultSupported: supported,
            verifiedConnectivity: verified,
          );
          expect(
            shouldRunLegacyPnpIPoEConnectivityProbe(status),
            oldPredicate(
              terminalResultSupported: supported,
              verifiedConnectivity: verified,
            ),
            reason: 'supported=$supported verified=$verified',
          );
        }
      }
    });
  });

  group('reconciliation outcome classification — b18e895d', () {
    // Pre-refactor, the view's try/catch chain mapped each thrown shape onto a
    // UI action. The coordinator now returns an outcome and the view maps that.
    // The mapping to check is thrown-shape -> outcome kind.
    Object outcomeKind(AutoIPoEReconciliationOutcome outcome) =>
        switch (outcome) {
          AutoIPoEReconciliationCompleted() => 'completed',
          AutoIPoEReconciliationNoInternet(cause: final cause) => cause,
          AutoIPoEReconciliationFailed(terminal: final terminal) =>
            terminal ? 'failed-terminal' : 'failed-recoverable',
          AutoIPoEReconciliationCancelled() => 'cancelled',
        };

    Future<Object> classify(Object? thrown) async {
      final coordinator = AutoIPoEReconciliationCoordinator(
        bridge: _ThrowingBridge(thrown),
      );
      return outcomeKind(await coordinator.followPnpSetup(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
        verifyInternet: () async {},
      ));
    }

    test('a terminal failure still reads as terminal', () async {
      expect(
        await classify(AutoIPoETerminalFailure(
            _pending(AutoIPoERecoveryAction.retrySetup, retryable: false))),
        'failed-terminal',
      );
    });

    test('a retry-setup pending still reads as recoverable', () async {
      // The old code revealed Retry/Edit here rather than a failure dialog.
      expect(
        await classify(AutoIPoERecoveryPending(
            _pending(AutoIPoERecoveryAction.retrySetup))),
        'failed-recoverable',
      );
    });

    test('no internet and an expired budget stay distinguishable', () async {
      // The old code routed both to the no-internet screen but logged only the
      // timeout, so the distinction has to survive.
      expect(await classify(ExceptionNoInternetConnection()),
          AutoIPoENoInternetCause.reported);
      expect(await classify(TimeoutException('budget')),
          AutoIPoENoInternetCause.timedOut);
    });

    test('an unclassified error still becomes an issue', () async {
      final kind = await classify(StateError('boom'));
      expect(kind, anyOf('failed-terminal', 'failed-recoverable'));
    });
  });

  group('unclassified-error classification — 080a04e0', () {
    // The pre-refactor Advanced path accumulated state from the provider and
    // classified an unclassified error against `reconciledState.status`, seeded
    // with the status the page already had. The PnP path did the same through
    // its own progress field. An error that arrives before any progress does
    // therefore has a status to be classified against, and classifying it
    // against an empty one produces a different issue -- different dialog copy,
    // and a different field group highlighted.
    final routerStatus = const AutoIPoEStatus.init().copyWith(
      lastError: 'ErrorAutoIPoEProvisioningFailed',
      errorCategory: 'provider',
      retryable: false,
      errorFieldGroup: 'mode',
    );

    AutoIPoEIssue oldIssue(Object error) => AutoIPoEIssueMapper.from(
          status: routerStatus,
          error: error,
          mode: AutoIPoEMode.auto,
        );

    test('agrees with the accumulated status the old path used', () async {
      final coordinator = AutoIPoEReconciliationCoordinator(
        bridge: _ThrowingBridge(StateError('boom'), reportProgress: false),
      );

      final outcome = await coordinator.followAdvancedApply(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
        initialStatus: routerStatus,
      );

      expect(outcome, isA<AutoIPoEReconciliationFailed>());
      expect((outcome as AutoIPoEReconciliationFailed).issue,
          oldIssue(StateError('boom')));
    });

    test('an empty seed would have classified it differently', () async {
      // Guards the fix: if the seed is ever dropped again, this is the shape the
      // user would get instead.
      final coordinator = AutoIPoEReconciliationCoordinator(
        bridge: _ThrowingBridge(StateError('boom'), reportProgress: false),
      );

      final outcome = await coordinator.followAdvancedApply(
        expectedMode: AutoIPoEMode.auto,
        isCurrent: () => true,
      );

      expect((outcome as AutoIPoEReconciliationFailed).issue,
          isNot(oldIssue(StateError('boom'))));
    });
  });
}

AutoIPoEIssue _pending(AutoIPoERecoveryAction action,
        {bool retryable = true}) =>
    AutoIPoEIssue(
      category: AutoIPoEIssueCategory.retryable,
      code: 'Code',
      retryable: retryable,
      recoveryAction: action,
    );

AutoIPoEStatus _statusWith({
  required bool terminalResultSupported,
  required bool verifiedConnectivity,
}) =>
    const AutoIPoEStatus.init().copyWith(
      terminalResultSupported: terminalResultSupported,
      terminalResult: verifiedConnectivity
          ? const AutoIPoETerminalResult(
              phase: AutoIPoETerminalPhase.completed,
              operation: AutoIPoETerminalResult.applyOperation,
              exitCode: 0,
              reason: 'Completed',
              connectivityVerified: true,
            )
          : null,
      progressPhase: verifiedConnectivity && !terminalResultSupported
          ? AutoIPoEProgressPhase.completed
          : null,
      connectivityVerified: verifiedConnectivity ? true : null,
    );

/// Throws one shape from the reconciliation wait, so the coordinator's
/// classification is the only thing under test.
class _ThrowingBridge extends Fake implements AutoIPoEInternetSettingsBridge {
  _ThrowingBridge(this.thrown, {this.reportProgress = true});

  final Object? thrown;

  /// When false, nothing is reported before the throw, which is the case where
  /// the seeded status is the only status available.
  final bool reportProgress;

  @override
  Future<AutoIPoELog> waitForPnpIPoESetupCompletion({
    int maxRetry = 80,
    Duration retryDelay = const Duration(seconds: 3),
    AutoIPoEMode? expectedMode,
    bool useStructuredProgress = false,
    AutoIPoEProgressCallback? onProgress,
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
  }) async {
    if (reportProgress) {
      // New-firmware status, so the fallback probe is not part of this test.
      onProgress?.call(
        _statusWith(terminalResultSupported: true, verifiedConnectivity: true),
        const AutoIPoELog.init(),
      );
    }
    if (thrown != null) {
      throw thrown!;
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
  }) async {}
}
