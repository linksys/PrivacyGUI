import 'dart:async';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';

/// New Auto-IPoE runtimes perform their own multi-target connectivity check.
/// Older firmware has no structured completion signal, so it keeps the
/// LinksysNow probe as a compatibility fallback.
bool shouldRunLegacyPnpIPoEConnectivityProbe(AutoIPoEStatus status) =>
    !status.terminalResultSupported && !status.hasVerifiedBackendConnectivity;

/// How following one already-dispatched Apply ended.
///
/// The coordinator classifies; the caller decides what to show. Keeping the two
/// apart is what lets this be tested without a widget tree, and it is the reason
/// the same classification no longer has to be repeated per screen.
sealed class AutoIPoEReconciliationOutcome {
  const AutoIPoEReconciliationOutcome();
}

/// The tunnel came up and connectivity was confirmed.
class AutoIPoEReconciliationCompleted extends AutoIPoEReconciliationOutcome {
  const AutoIPoEReconciliationCompleted();
}

/// Reconciliation finished but the router still has no internet. Distinct from a
/// failure: the Apply itself may well have worked.
class AutoIPoEReconciliationNoInternet extends AutoIPoEReconciliationOutcome {
  const AutoIPoEReconciliationNoInternet(this.cause);

  /// Whether the budget expired rather than the router answering "no internet".
  final AutoIPoENoInternetCause cause;
}

enum AutoIPoENoInternetCause { reported, timedOut }

/// The worker ended and will not recover on its own.
class AutoIPoEReconciliationFailed extends AutoIPoEReconciliationOutcome {
  const AutoIPoEReconciliationFailed(this.issue, {required this.terminal});

  final AutoIPoEIssue issue;

  /// Terminal failures are worth interrupting the user for; the rest should
  /// surface as recovery actions.
  final bool terminal;
}

/// A newer attempt superseded this one, or the caller went away. Nothing should
/// be shown: the state this would have described is no longer on screen.
class AutoIPoEReconciliationCancelled extends AutoIPoEReconciliationOutcome {
  const AutoIPoEReconciliationCancelled();
}

/// Follows an Apply that has already been dispatched, and never dispatches one
/// itself. Every await is fenced by [isCurrent] so a superseded attempt reports
/// [AutoIPoEReconciliationCancelled] instead of writing over what replaced it.
class AutoIPoEReconciliationCoordinator {
  AutoIPoEReconciliationCoordinator({
    required AutoIPoEInternetSettingsBridge bridge,
    required Future<void> Function() verifyInternet,
  })  : _bridge = bridge,
        _verifyInternet = verifyInternet;

  final AutoIPoEInternetSettingsBridge _bridge;

  /// The native internet check the rest of the setup flow uses. Injected so the
  /// coordinator does not have to know which flow it is serving.
  final Future<void> Function() _verifyInternet;

  Future<AutoIPoEReconciliationOutcome> follow({
    required AutoIPoEMode expectedMode,
    required bool Function() isCurrent,
    void Function(AutoIPoEReconciliationProgress progress)? onProgress,
    void Function(AutoIPoEStatus status, AutoIPoELog log)? onRuntime,
    void Function(AutoIPoEIssue issue)? onPollingWindowEnded,
  }) async {
    var latestStatus = const AutoIPoEStatus.init();
    try {
      while (isCurrent()) {
        try {
          await _bridge.waitForPnpIPoESetupCompletion(
            expectedMode: expectedMode,
            useStructuredProgress: true,
            onReconciliationProgress: (progress) {
              if (isCurrent()) {
                onProgress?.call(progress);
              }
            },
            onProgress: (status, log) {
              latestStatus = status;
              if (isCurrent()) {
                onRuntime?.call(status, log);
              }
            },
          );
          if (shouldRunLegacyPnpIPoEConnectivityProbe(latestStatus)) {
            await _bridge.waitForPnpIPoEInternetConnectivity(
              shouldContinue: isCurrent,
              onReconciliationProgress: (progress) {
                if (isCurrent()) {
                  onProgress?.call(progress);
                }
              },
            );
          }
          await _verifyInternet();
          return isCurrent()
              ? const AutoIPoEReconciliationCompleted()
              : const AutoIPoEReconciliationCancelled();
        } on AutoIPoERecoveryPending catch (error) {
          if (error.issue.recoveryAction !=
              AutoIPoERecoveryAction.continueChecking) {
            rethrow;
          }
          if (!isCurrent()) {
            return const AutoIPoEReconciliationCancelled();
          }
          // A bounded polling window ended while the same worker may still be
          // running. Keep watching read-only; Set and Apply are never sent from
          // here, so looping cannot re-trigger the operation.
          onPollingWindowEnded?.call(error.issue);
        }
      }
      return const AutoIPoEReconciliationCancelled();
    } on ExceptionNoInternetConnection {
      return isCurrent()
          ? const AutoIPoEReconciliationNoInternet(
              AutoIPoENoInternetCause.reported)
          : const AutoIPoEReconciliationCancelled();
    } on TimeoutException catch (error, stackTrace) {
      logger.w(
        '[Auto-IPoE]: Post-IPoE Internet connectivity did not recover within '
        'the bounded retry window',
        error: error,
        stackTrace: stackTrace,
      );
      return isCurrent()
          ? const AutoIPoEReconciliationNoInternet(
              AutoIPoENoInternetCause.timedOut)
          : const AutoIPoEReconciliationCancelled();
    } on AutoIPoETerminalFailure catch (error) {
      return isCurrent()
          ? AutoIPoEReconciliationFailed(error.issue, terminal: true)
          : const AutoIPoEReconciliationCancelled();
    } on AutoIPoERecoveryPending catch (error) {
      // Only a real retrySetup failure reaches here: the worker ended, so
      // offering Retry and Edit cannot race a live operation.
      return isCurrent()
          ? AutoIPoEReconciliationFailed(error.issue, terminal: false)
          : const AutoIPoEReconciliationCancelled();
    } catch (error) {
      final issue = AutoIPoEIssueMapper.from(error: error, mode: expectedMode);
      return isCurrent()
          ? AutoIPoEReconciliationFailed(issue, terminal: issue.isTerminal)
          : const AutoIPoEReconciliationCancelled();
    }
  }
}
