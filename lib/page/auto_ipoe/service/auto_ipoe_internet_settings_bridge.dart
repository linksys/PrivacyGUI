import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';

final autoIPoEInternetSettingsBridgeProvider =
    Provider<AutoIPoEInternetSettingsBridge>((ref) {
  return AutoIPoEInternetSettingsBridge(ref.read(autoIPoEServiceProvider));
});

/// The Apply request was dispatched, but its final outcome could not be read.
/// Callers must reconcile the existing operation and must not dispatch Apply
/// again.
class AutoIPoEApplyOutcomeUnknown implements Exception {
  const AutoIPoEApplyOutcomeUnknown(this.cause);

  final Object cause;

  @override
  String toString() => 'AutoIPoEApplyOutcomeUnknown: $cause';
}

bool isAutoIPoEApplyOutcomeUnknownError(Object error) {
  return error is JNAPSideEffectError ||
      error is ClientException ||
      error is TimeoutException;
}

typedef AutoIPoEProgressCallback = void Function(
  AutoIPoEStatus status,
  AutoIPoELog log,
);

typedef AutoIPoEReconciliationProgressCallback = void Function(
  AutoIPoEReconciliationProgress progress,
);

class AutoIPoEInternetSettingsBridge {
  const AutoIPoEInternetSettingsBridge(this._service);

  final AutoIPoEService _service;

  bool shouldResetBeforeLeaving({
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) {
    return shouldResetAutoIPoE(
      originalWanType: originalWanType,
      originalStatus: originalStatus,
    );
  }

  Future<void> saveIPoEInternetSettings({
    required AutoIPoESettings settings,
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) async {
    final enabledSettings = buildEnabledAutoIPoESettings(settings);
    try {
      await _service.setSettings(enabledSettings);
    } catch (error, stackTrace) {
      if (!isAutoIPoEApplyOutcomeUnknownError(error)) {
        rethrow;
      }
      Error.throwWithStackTrace(AutoIPoEApplyNotStarted(error), stackTrace);
    }
    try {
      await _service.apply(
        resetFirst: shouldResetBeforeLeaving(
          originalWanType: originalWanType,
          originalStatus: originalStatus,
        ),
        settings: enabledSettings,
      );
    } catch (error, stackTrace) {
      if (!isAutoIPoEApplyOutcomeUnknownError(error)) {
        rethrow;
      }
      Error.throwWithStackTrace(
        AutoIPoEApplyOutcomeUnknown(error),
        stackTrace,
      );
    }
  }

  Future<void> savePnpIPoE({
    AutoIPoESettings? settings,
  }) async {
    final enabledSettings = buildEnabledAutoIPoESettings(
      settings ?? const AutoIPoESettings.init(),
    );

    // Keep Set and Apply as separate stages. A Set failure is safe to surface
    // because Apply was never dispatched. Once Apply has been dispatched, a
    // transport/timeout/side-effect failure has an unknown outcome and must be
    // reconciled without submitting another Apply request.
    try {
      await _service.setSettings(enabledSettings);
    } catch (error, stackTrace) {
      if (!isAutoIPoEApplyOutcomeUnknownError(error)) {
        rethrow;
      }
      Error.throwWithStackTrace(AutoIPoEApplyNotStarted(error), stackTrace);
    }
    try {
      await _service.apply(
        settings: enabledSettings,
        pnpReflectAfterApply: true,
      );
    } catch (error, stackTrace) {
      if (!isAutoIPoEApplyOutcomeUnknownError(error)) {
        rethrow;
      }
      Error.throwWithStackTrace(
        AutoIPoEApplyOutcomeUnknown(error),
        stackTrace,
      );
    }
  }

  Future<AutoIPoELog> waitForPnpIPoESetupCompletion({
    int maxRetry = 80,
    Duration retryDelay = const Duration(seconds: 3),
    AutoIPoEMode? expectedMode,
    bool useStructuredProgress = false,
    AutoIPoEProgressCallback? onProgress,
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
  }) async {
    AutoIPoELog lastLog = const AutoIPoELog.init();
    AutoIPoEStatus lastStatus = const AutoIPoEStatus.init();
    Object? lastTransientError;
    AutoIPoEIssue? lastRetryableIssue;

    onReconciliationProgress?.call(
      const AutoIPoEReconciliationProgress.initial(),
    );
    for (var index = 0; index < maxRetry; index++) {
      try {
        lastStatus = await _service.getStatus();
        try {
          lastLog = await _service.getLog();
        } catch (error) {
          // A verified Active status is authoritative. A temporarily
          // unavailable log must not make the UI submit Apply again.
          lastTransientError = error;
        }
        onProgress?.call(lastStatus, lastLog);

        if (useStructuredProgress && lastStatus.hasStructuredProgress) {
          onReconciliationProgress?.call(
            AutoIPoEReconciliationProgress.fromStructuredStatus(lastStatus),
          );
        }

        if (AutoIPoEIssueMapper.isVerifiedActive(
          lastStatus,
          expectedMode: expectedMode,
        )) {
          if (!useStructuredProgress || !lastStatus.hasStructuredProgress) {
            onReconciliationProgress?.call(
              const AutoIPoEReconciliationProgress.tunnelCompleted(),
            );
          }
          return lastLog;
        }

        if (lastStatus.hasTerminalApplyOutcome) {
          final issue = AutoIPoEIssueMapper.from(status: lastStatus);
          if (issue.isTerminal) {
            throw AutoIPoETerminalFailure(issue);
          }
          // A legacy Failed state or an exact correlated Failed/Busy result
          // means this invocation ended. Retryable outcomes therefore require
          // a fresh, user-initiated Apply.
          throw AutoIPoERecoveryPending(issue);
        }
        if (!useStructuredProgress || !lastStatus.hasStructuredProgress) {
          onReconciliationProgress?.call(
            const AutoIPoEReconciliationProgress.waitingForTunnel(),
          );
        }
      } on AutoIPoETerminalFailure {
        rethrow;
      } on AutoIPoERecoveryPending {
        rethrow;
      } catch (error) {
        final issue = AutoIPoEIssueMapper.from(
          status: lastStatus,
          error: error,
        );
        if (error is JNAPError && issue.isTerminal) {
          throw AutoIPoETerminalFailure(issue);
        }
        if (issue.retryable) {
          lastRetryableIssue = issue;
        }
        lastTransientError = error;
        // QSDK 12.5 intentionally interrupts JNAP while mapv6 restarts WAN
        // and WiFi. Keep reconciling the same operation after the router is
        // reachable again instead of dispatching Apply a second time.
      }

      if (index < maxRetry - 1) {
        await Future.delayed(retryDelay);
      }
    }

    throw AutoIPoERecoveryPending(
      lastRetryableIssue ??
          AutoIPoEIssueMapper.from(
            status: lastStatus,
            error: lastTransientError ?? TimeoutException('Status pending'),
          ),
    );
  }

  Future<void> waitForPnpIPoEInternetConnectivity({
    int maxRetry = 40,
    Duration retryDelay = const Duration(seconds: 5),
    Duration maxDuration = const Duration(minutes: 5),
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
    bool Function()? shouldContinue,
  }) async {
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < maxRetry; index++) {
      if (shouldContinue?.call() == false) {
        return;
      }
      if (stopwatch.elapsed >= maxDuration) {
        break;
      }
      onReconciliationProgress?.call(
        const AutoIPoEReconciliationProgress.connectivityChecking(),
      );
      try {
        final remaining = maxDuration - stopwatch.elapsed;
        if (await _service.probeInternet(
          maxDuration: remaining,
          shouldContinue: shouldContinue,
        )) {
          onReconciliationProgress?.call(
            const AutoIPoEReconciliationProgress.completed(),
          );
          return;
        }
      } catch (_) {
        // The router can remain briefly unreachable after the WAN/Wi-Fi
        // restart. Keep the original bounded probe window without applying
        // settings or restarting the network again.
      }

      if (index < maxRetry - 1) {
        final remaining = maxDuration - stopwatch.elapsed;
        if (remaining <= Duration.zero) {
          break;
        }
        await Future.delayed(
          remaining < retryDelay ? remaining : retryDelay,
        );
      }
    }

    throw TimeoutException(
      'Auto-IPoE Internet connectivity check timed out',
    );
  }

  Future<void> resetIfNeededBeforeSaving({
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) async {
    if (!shouldResetBeforeLeaving(
      originalWanType: originalWanType,
      originalStatus: originalStatus,
    )) {
      return;
    }

    await _service.reset();
  }
}
