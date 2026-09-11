import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';

enum AutoIPoEIssueCategory {
  retryable,
  validation,
  provider,
  runtime,
  unknown,
}

enum AutoIPoEFieldGroup {
  none,
  mode,
  biglobeStaticIp,
  standardIpip,
  v6PlusStaticIp,
  transixStaticIp,
  asahiNetStaticIp,
  xpassStaticIp,
}

enum AutoIPoERecoveryAction {
  none,
  continueChecking,
  retrySetup,
  scheduledRetry,
}

class AutoIPoEIssue extends Equatable {
  const AutoIPoEIssue({
    required this.category,
    required this.code,
    required this.retryable,
    this.fieldGroup = AutoIPoEFieldGroup.none,
    this.recoveryAction = AutoIPoERecoveryAction.none,
    this.detail,
  });

  final AutoIPoEIssueCategory category;
  final String code;
  final bool retryable;
  final AutoIPoEFieldGroup fieldGroup;
  final AutoIPoERecoveryAction recoveryAction;
  final String? detail;

  bool get isTerminal => !retryable;
  bool get requiresFreshApply =>
      recoveryAction == AutoIPoERecoveryAction.retrySetup;
  bool get hasScheduledRecovery =>
      recoveryAction == AutoIPoERecoveryAction.scheduledRetry;

  @override
  List<Object?> get props => [
        category,
        code,
        retryable,
        fieldGroup,
        recoveryAction,
        detail,
      ];
}

class AutoIPoETerminalFailure implements Exception {
  const AutoIPoETerminalFailure(this.issue);

  final AutoIPoEIssue issue;

  @override
  String toString() => 'AutoIPoETerminalFailure(${issue.code})';
}

/// The settings request was interrupted before Apply was dispatched. A caller
/// may safely return to the form and let the user submit again.
class AutoIPoEApplyNotStarted implements Exception {
  const AutoIPoEApplyNotStarted(this.cause);

  final Object cause;

  @override
  String toString() => 'AutoIPoEApplyNotStarted: $cause';
}

class AutoIPoERecoveryPending implements Exception {
  const AutoIPoERecoveryPending(this.issue);

  final AutoIPoEIssue issue;

  @override
  String toString() => 'AutoIPoERecoveryPending(${issue.code})';
}

class AutoIPoEIssueMapper {
  const AutoIPoEIssueMapper._();

  static const _retryableTokens = <String>{
    'wan6',
    'ipv6prefix',
    'prefixnotready',
    'prefixunavailable',
    'dad',
    'connectivity',
    'internetconnect',
    'networkunavailable',
    'temporar',
    'timeout',
    'notready',
    'pending',
    'alreadyrunning',
  };

  static const _providerTokens = <String>{
    'provider',
    'credential',
    'authentication',
    'ruleapi',
    'ddns',
  };

  static const _validationTokens = <String>{
    'missing',
    'invalid',
    'unsupportedmode',
    'disabled',
    'requiredparameter',
  };

  static const _runtimeTokens = <String>{
    'execution',
    'resetfailed',
    'refreshfailed',
    'featurenotsupported',
  };

  static const _endedRetryTokens = <String>{
    'failed',
    'timeout',
    'unavailable',
    'wan6notready',
    'prefixnotready',
  };

  static const _knownTerminalFailureCodes = <String>{
    'WaitingForIPv6',
    'DADPending',
    'DADDuplicate',
    'ConnectivityFailed',
    'MAPEInterfaceDown',
    'DSLiteInterfaceDown',
    'IPIPInterfaceDown',
    'ProviderUnavailable',
    'CompletionUnconfirmed',
    'ProcessFailed',
    'StateCommitFailed',
    'InvalidBIGLOBEStaticIPSettings',
    'BIGLOBECredentialsHandoffFailed',
    'InvalidMode',
    'Disabled',
    'AlreadyRunning',
    'ResetFailed',
    'reset_failed',
    'FeatureNotSupported',
  };

  static AutoIPoEIssue from({
    AutoIPoEStatus? status,
    Object? error,
    AutoIPoEMode? mode,
  }) {
    final notStarted = error is AutoIPoEApplyNotStarted;
    final effectiveError = notStarted ? error.cause : error;
    final envelope = _errorEnvelope(effectiveError);
    final terminalFailure = status?.hasTerminalApplyFailure == true
        ? _terminalFailureCode(status?.terminalResult?.reason)
        : null;
    final terminalBusy = status?.hasTerminalApplyBusy == true;
    final terminalBusyReason =
        terminalBusy ? status?.terminalResult?.reason : null;
    final terminalRetryScheduled =
        status?.hasTerminalApplyRetryScheduled == true;
    final terminalRetryScheduledReason =
        terminalRetryScheduled ? status?.terminalResult?.reason : null;
    final statusError = status?.terminalResultSupported == true
        ? status?.hasTerminalApplyFailure == true
            ? status?.lastError
            : null
        : status?.lastError;
    final terminalResultPending = status?.isTerminalApplyResultPending == true;
    final explicitCategory = _firstText(
      envelope['errorCategory'],
      status?.errorCategory,
    );
    final explicitRetryable =
        terminalResultPending || terminalBusy || terminalRetryScheduled
            ? true
            : _bool(envelope['retryable']) ?? status?.retryable;
    final fallbackError = _firstText(
      effectiveError is JNAPError ? effectiveError.result : null,
      notStarted ? 'ApplyNotStarted' : null,
      effectiveError is TimeoutException ? 'Timeout' : null,
      effectiveError is ClientException ? 'ConnectionInterrupted' : null,
      effectiveError is JNAPSideEffectError ? 'ApplyOutcomeUnknown' : null,
      effectiveError?.runtimeType.toString(),
    );
    final code = _firstText(
          terminalRetryScheduledReason,
          terminalBusyReason,
          terminalFailure,
          envelope['lastError'],
          statusError,
          fallbackError,
        ) ??
        'Unknown';
    final normalized = '${explicitCategory ?? ''} $code'.toLowerCase();
    final retryable = notStarted
        ? false
        : explicitRetryable ??
            explicitCategory?.toLowerCase().contains('retry') == true ||
                effectiveError is TimeoutException ||
                effectiveError is ClientException ||
                effectiveError is JNAPSideEffectError ||
                _containsAny(normalized, _retryableTokens);
    final category = terminalRetryScheduled
        ? AutoIPoEIssueCategory.provider
        : notStarted
            ? AutoIPoEIssueCategory.runtime
            : retryable
                ? AutoIPoEIssueCategory.retryable
                : _category(explicitCategory, normalized);
    final failedOperation = !terminalResultPending &&
        (status?.hasTerminalApplyOutcome == true ||
            (status?.terminalResultSupported != true &&
                envelope['applyState']?.toString().toLowerCase() == 'failed') ||
            (status != null &&
                !status.terminalResultSupported &&
                !status.isBusy &&
                status.lastError != null &&
                _containsAny(code.toLowerCase(), _endedRetryTokens) &&
                retryable) ||
            (effectiveError is JNAPError &&
                effectiveError.result != 'ErrorAlreadyRunning' &&
                retryable));
    final recoveryAction = terminalRetryScheduled
        ? AutoIPoERecoveryAction.scheduledRetry
        : !retryable
            ? AutoIPoERecoveryAction.none
            : failedOperation
                ? AutoIPoERecoveryAction.retrySetup
                : AutoIPoERecoveryAction.continueChecking;
    final fieldGroup = _fieldGroup(
      _firstText(envelope['errorFieldGroup'], status?.errorFieldGroup),
      code,
      mode ?? status?.selectedMode,
    );
    final detail = _firstText(
      envelope['detail'],
      envelope['message'],
      effectiveError is JNAPError ? effectiveError.error : null,
      notStarted ? effectiveError.toString() : null,
    );

    return AutoIPoEIssue(
      category: category,
      code: code,
      retryable: retryable,
      fieldGroup: fieldGroup,
      recoveryAction: recoveryAction,
      detail: detail == code ? null : detail,
    );
  }

  static bool isVerifiedActive(
    AutoIPoEStatus status, {
    AutoIPoEMode? expectedMode,
  }) {
    final activeRuntime = switch (status.runtimeKind) {
      AutoIPoERuntimeType.mape ||
      AutoIPoERuntimeType.dsLite ||
      AutoIPoERuntimeType.ipip6 =>
        true,
      _ => false,
    };
    final terminalResultVerified = !status.terminalResultSupported ||
        status.terminalResult?.isSuccessfulFor(
              AutoIPoETerminalResult.applyOperation,
            ) ==
            true;
    return status.isEnabled &&
        !status.isBusy &&
        status.applyState == AutoIPoEApplyState.active &&
        (expectedMode == null || status.selectedMode == expectedMode) &&
        activeRuntime &&
        terminalResultVerified;
  }

  static AutoIPoEIssueCategory _category(
    String? explicitCategory,
    String normalized,
  ) {
    final explicit = explicitCategory?.toLowerCase() ?? '';
    if (explicit.contains('validation')) {
      return AutoIPoEIssueCategory.validation;
    }
    if (explicit.contains('provider')) {
      return AutoIPoEIssueCategory.provider;
    }
    if (explicit.contains('runtime')) {
      return AutoIPoEIssueCategory.runtime;
    }
    if (_containsAny(normalized, _validationTokens)) {
      return AutoIPoEIssueCategory.validation;
    }
    if (_containsAny(normalized, _providerTokens)) {
      return AutoIPoEIssueCategory.provider;
    }
    if (_containsAny(normalized, _runtimeTokens)) {
      return AutoIPoEIssueCategory.runtime;
    }
    return AutoIPoEIssueCategory.unknown;
  }

  static AutoIPoEFieldGroup _fieldGroup(
    String? explicitFieldGroup,
    String code,
    AutoIPoEMode? mode,
  ) {
    final normalized = '${explicitFieldGroup ?? ''} $code'
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]'), '');
    if (normalized.contains('standardipip')) {
      return AutoIPoEFieldGroup.standardIpip;
    }
    if (normalized.contains('biglobe')) {
      return AutoIPoEFieldGroup.biglobeStaticIp;
    }
    if (normalized.contains('v6plus')) {
      return AutoIPoEFieldGroup.v6PlusStaticIp;
    }
    if (normalized.contains('transix')) {
      return AutoIPoEFieldGroup.transixStaticIp;
    }
    if (normalized.contains('asahinet')) {
      return AutoIPoEFieldGroup.asahiNetStaticIp;
    }
    if (normalized.contains('xpass')) {
      return AutoIPoEFieldGroup.xpassStaticIp;
    }
    if (normalized.contains('mode')) {
      return AutoIPoEFieldGroup.mode;
    }
    if (!normalized.contains('missing') && explicitFieldGroup == null) {
      return AutoIPoEFieldGroup.none;
    }
    return switch (mode) {
      AutoIPoEMode.biglobeStaticIp => AutoIPoEFieldGroup.biglobeStaticIp,
      AutoIPoEMode.standardIpip => AutoIPoEFieldGroup.standardIpip,
      AutoIPoEMode.v6PlusStaticIp => AutoIPoEFieldGroup.v6PlusStaticIp,
      AutoIPoEMode.transixStaticIp => AutoIPoEFieldGroup.transixStaticIp,
      AutoIPoEMode.asahiNetStaticIp => AutoIPoEFieldGroup.asahiNetStaticIp,
      AutoIPoEMode.xpassStaticIp => AutoIPoEFieldGroup.xpassStaticIp,
      _ => AutoIPoEFieldGroup.mode,
    };
  }

  static Map<String, dynamic> _errorEnvelope(Object? error) {
    if (error is! JNAPError || error.error == null) {
      return const {};
    }
    try {
      final decoded = jsonDecode(error.error!);
      if (decoded is! Map) {
        return const {};
      }
      final map = Map<String, dynamic>.from(decoded);
      final status = map['status'];
      return status is Map ? Map<String, dynamic>.from(status) : map;
    } catch (_) {
      return const {};
    }
  }

  static bool _containsAny(String value, Set<String> tokens) {
    return tokens.any(value.contains);
  }

  static String? _terminalFailureCode(String? reason) {
    if (reason == null || reason.isEmpty) {
      return null;
    }
    if (_knownTerminalFailureCodes.contains(reason) ||
        (reason.startsWith('Missing') && reason.endsWith('Settings'))) {
      return reason;
    }
    // The backend may add a new stable reason before the UI knows how to
    // explain it. Fail closed with generic guidance instead of guessing a
    // category from a substring or accidentally presenting success.
    return 'ExecutionFailed';
  }

  static bool? _bool(Object? value) => value is bool ? value : null;

  static String? _firstText(
    Object? first, [
    Object? second,
    Object? third,
    Object? fourth,
    Object? fifth,
    Object? sixth,
    Object? seventh,
    Object? eighth,
    Object? ninth,
  ]) {
    for (final value in [
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      eighth,
      ninth,
    ]) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}
