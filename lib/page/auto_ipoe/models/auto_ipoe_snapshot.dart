import 'package:equatable/equatable.dart';
import 'auto_ipoe_models.dart';

enum AutoIPoEOutcome {
  idle,
  pending,
  succeeded,
  failed,
  busy,
  retryScheduled,
  rejected
}

/// A persisted correlation key contains no ISP credentials or settings.
class AutoIPoESubmission extends Equatable {
  const AutoIPoESubmission(this.requestId, {required this.reset});
  final String requestId;
  final bool reset;
  @override
  List<Object?> get props => [requestId, reset];
}

/// One bounded read from the native USP adapter, preserving the original forms.
class AutoIPoESnapshot extends Equatable {
  const AutoIPoESnapshot({
    this.capabilities = const AutoIPoECapabilities.init(),
    this.capabilitiesAvailable = true,
    this.settings = const AutoIPoESettings.init(),
    this.runtime = const AutoIPoEStatus.init(),
    this.log = const AutoIPoELog.init(),
    this.requestId,
    this.operationId,
    this.exitCode,
    this.accepted = false,
  });
  final AutoIPoECapabilities capabilities;

  /// An unreadable capability leaf is different from an unsupported router.
  final bool capabilitiesAvailable;
  final AutoIPoESettings settings;
  final AutoIPoEStatus runtime;
  final AutoIPoELog log;
  final String? requestId;
  final String? operationId;
  final int? exitCode;
  final bool accepted;

  AutoIPoEOutcome outcomeFor(AutoIPoESubmission? submission) {
    if (submission == null) return AutoIPoEOutcome.idle;
    if (requestId != submission.requestId ||
        operationId != submission.requestId) {
      return AutoIPoEOutcome.pending;
    }
    if (runtime.isBusy || exitCode == null) return AutoIPoEOutcome.pending;
    if (exitCode == 75 || runtime.hasTerminalApplyBusy) {
      return AutoIPoEOutcome.busy;
    }
    if (runtime.hasTerminalApplyRetryScheduled) {
      return AutoIPoEOutcome.retryScheduled;
    }
    if (exitCode != 0) return AutoIPoEOutcome.failed;
    if (submission.reset) {
      final terminal = runtime.terminalResult;
      return runtime.lastResult == 'ResetCompleted' &&
              terminal?.operation == 'reset' &&
              terminal?.phase == AutoIPoETerminalPhase.completed &&
              terminal?.exitCode == 0 &&
              terminal?.reason == 'ResetCompleted' &&
              terminal?.connectivityVerified == false
          ? AutoIPoEOutcome.succeeded
          : AutoIPoEOutcome.failed;
    }
    return runtime.isEnabled &&
            runtime.applyState == AutoIPoEApplyState.active &&
            runtime.connectivityVerified == true &&
            runtime.hasVerifiedBackendConnectivity
        ? AutoIPoEOutcome.succeeded
        : AutoIPoEOutcome.failed;
  }

  AutoIPoESnapshot withRuntime(AutoIPoEStatus status,
          {String? requestId, String? operationId, int? exitCode}) =>
      AutoIPoESnapshot(
          capabilities: capabilities,
          capabilitiesAvailable: capabilitiesAvailable,
          settings: settings,
          runtime: status,
          log: log,
          requestId: requestId ?? this.requestId,
          operationId: operationId ?? this.operationId,
          exitCode: exitCode ?? this.exitCode,
          accepted: accepted);

  @override
  List<Object?> get props => [
        capabilities,
        capabilitiesAvailable,
        settings,
        runtime,
        log,
        requestId,
        operationId,
        exitCode,
        accepted
      ];
}

/// Native command acknowledgment, distinct from verified Internet completion.
class AutoIPoEReceipt extends Equatable {
  const AutoIPoEReceipt(
      {required this.accepted,
      this.cancelled = false,
      this.error,
      this.requestId,
      this.operationId,
      this.exitCode,
      this.status = const AutoIPoEStatus.init()});
  final bool accepted;
  final bool cancelled;
  final String? error;
  final String? requestId;
  final String? operationId;
  final int? exitCode;
  final AutoIPoEStatus status;
  @override
  List<Object?> get props =>
      [accepted, cancelled, error, requestId, operationId, exitCode, status];
}
