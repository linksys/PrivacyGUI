import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';

AutoIPoEStatus _status({
  AutoIPoEApplyState applyState = AutoIPoEApplyState.failed,
  AutoIPoERuntimeType runtimeKind = AutoIPoERuntimeType.none,
  AutoIPoEMode selectedMode = AutoIPoEMode.v6PlusStaticIp,
  bool isEnabled = true,
  bool isBusy = false,
  String? lastError,
  String? errorCategory,
  bool? retryable,
  String? errorFieldGroup,
  bool terminalResultSupported = false,
  AutoIPoETerminalResult? terminalResult,
}) {
  return AutoIPoEStatus(
    isEnabled: isEnabled,
    isCurrentWANType: true,
    selectedMode: selectedMode,
    applyState: applyState,
    runtimeKind: runtimeKind,
    blockIPv6ManualConfiguration: true,
    isBusy: isBusy,
    needsResetBeforeLeaving: true,
    lastError: lastError,
    errorCategory: errorCategory,
    retryable: retryable,
    errorFieldGroup: errorFieldGroup,
    terminalResultSupported: terminalResultSupported,
    terminalResult: terminalResult,
  );
}

void main() {
  group('AutoIPoEStatus optional error envelope', () {
    test('parses richer fields and accepts mode alias defensively', () {
      final status = AutoIPoEStatus.fromMap(const {
        'isEnabled': true,
        'mode': 'V6PlusStaticIP',
        'applyState': 'Failed',
        'runtimeType': 'MAPE',
        'errorCategory': 'validation',
        'retryable': false,
        'errorFieldGroup': 'v6PlusStaticIpSettings',
      });

      expect(status.selectedMode, AutoIPoEMode.v6PlusStaticIp);
      expect(status.errorCategory, 'validation');
      expect(status.retryable, isFalse);
      expect(status.errorFieldGroup, 'v6PlusStaticIpSettings');
    });
  });

  group('AutoIPoEIssueMapper', () {
    test('classifies retryable WAN6/DAD/connectivity failures', () {
      for (final code in [
        'WAN6NotReady',
        'MapCeDADTimeout',
        'ConnectivityCheckFailed',
      ]) {
        final issue = AutoIPoEIssueMapper.from(
          status: _status(lastError: code),
        );
        expect(issue.retryable, isTrue, reason: code);
        expect(issue.category, AutoIPoEIssueCategory.retryable, reason: code);
        expect(
          issue.recoveryAction,
          AutoIPoERecoveryAction.retrySetup,
          reason: '$code is a Failed terminal operation, not a running worker',
        );
      }
    });

    test('keeps an in-progress IPv6 wait on read-only status checking', () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          applyState: AutoIPoEApplyState.applying,
          isBusy: true,
          lastError: 'WaitingForIPv6Prefix',
          retryable: true,
        ),
      );

      expect(
        issue.recoveryAction,
        AutoIPoERecoveryAction.continueChecking,
      );
    });

    test('legacy non-busy ConnectivityFailed requires a fresh setup', () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          applyState: AutoIPoEApplyState.idle,
          lastError: 'ConnectivityFailed',
          retryable: true,
        ),
      );

      expect(
        issue.recoveryAction,
        AutoIPoERecoveryAction.retrySetup,
      );
    });

    for (final scenario in <({String name, AutoIPoEMode mode})>[
      (name: 'dynamic MAP-E', mode: AutoIPoEMode.auto),
      (name: 'static IPIP6', mode: AutoIPoEMode.biglobeStaticIp),
    ]) {
      test(
          '${scenario.name} keeps a structured Failed state pending without an exact result',
          () {
        final issue = AutoIPoEIssueMapper.from(
          status: _status(
            selectedMode: scenario.mode,
            lastError: 'ConnectivityFailed',
            retryable: false,
            terminalResultSupported: true,
          ),
        );

        expect(issue.retryable, isTrue);
        expect(issue.category, AutoIPoEIssueCategory.retryable);
        expect(issue.code, 'Unknown');
        expect(
          issue.recoveryAction,
          AutoIPoERecoveryAction.continueChecking,
        );
      });
    }

    test('never turns a JNAP transport outage into a fresh Apply', () {
      final issue = AutoIPoEIssueMapper.from(
        error: ClientException('JNAP temporarily unavailable'),
      );

      expect(issue.retryable, isTrue);
      expect(
        issue.recoveryAction,
        AutoIPoERecoveryAction.continueChecking,
      );
    });

    test('uses backend category and field group when available', () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          lastError: 'MissingV6PlusStaticIPSettings',
          errorCategory: 'validation',
          retryable: false,
          errorFieldGroup: 'v6PlusStaticIpSettings',
        ),
      );

      expect(issue.isTerminal, isTrue);
      expect(issue.category, AutoIPoEIssueCategory.validation);
      expect(issue.fieldGroup, AutoIPoEFieldGroup.v6PlusStaticIp);
    });

    test('maps BIGLOBE credential errors to the shared field group', () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          lastError: 'MissingBIGLOBEStaticIPSettings',
          errorCategory: 'validation',
          retryable: false,
          errorFieldGroup: 'biglobeStaticIpSettings',
        ),
      );

      expect(issue.category, AutoIPoEIssueCategory.validation);
      expect(issue.fieldGroup, AutoIPoEFieldGroup.biglobeStaticIp);
      expect(issue.isTerminal, isTrue);
    });

    test('extracts a current status envelope from JNAP error output', () {
      const error = JNAPError(
        result: 'ErrorExecutionRejected',
        error:
            '{"status":{"lastError":"MissingTransixStaticIPSettings","errorCategory":"provider","retryable":false,"errorFieldGroup":"transixStaticIpSettings"}}',
      );

      final issue = AutoIPoEIssueMapper.from(error: error);

      expect(issue.code, 'MissingTransixStaticIPSettings');
      expect(issue.category, AutoIPoEIssueCategory.provider);
      expect(issue.fieldGroup, AutoIPoEFieldGroup.transixStaticIp);
      expect(issue.isTerminal, isTrue);
    });

    test('keeps a pre-Apply transport failure on the editable form', () {
      final issue = AutoIPoEIssueMapper.from(
        error: AutoIPoEApplyNotStarted(Exception('connection interrupted')),
      );

      expect(issue.code, 'ApplyNotStarted');
      expect(issue.category, AutoIPoEIssueCategory.runtime);
      expect(issue.isTerminal, isTrue);
    });

    test('reconciles ErrorAlreadyRunning instead of submitting again', () {
      final issue = AutoIPoEIssueMapper.from(
        error: const JNAPError(result: 'ErrorAlreadyRunning'),
      );

      expect(issue.retryable, isTrue);
      expect(issue.category, AutoIPoEIssueCategory.retryable);
      expect(
        issue.recoveryAction,
        AutoIPoERecoveryAction.continueChecking,
      );
    });
  });

  group('verified Active gate', () {
    test('requires an actual IPv4-over-IPv6 runtime', () {
      expect(
        AutoIPoEIssueMapper.isVerifiedActive(
          _status(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.dhcpAuto,
          ),
        ),
        isFalse,
      );
      expect(
        AutoIPoEIssueMapper.isVerifiedActive(
          _status(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.mape,
          ),
        ),
        isTrue,
      );
      expect(
        AutoIPoEIssueMapper.isVerifiedActive(
          _status(
            applyState: AutoIPoEApplyState.active,
            runtimeKind: AutoIPoERuntimeType.mape,
          ),
          expectedMode: AutoIPoEMode.auto,
        ),
        isFalse,
      );
    });

    test('requires the exact terminal result when the contract is supported',
        () {
      final awaiting = _status(
        applyState: AutoIPoEApplyState.active,
        runtimeKind: AutoIPoERuntimeType.mape,
        terminalResultSupported: true,
      );
      final completed = _status(
        applyState: AutoIPoEApplyState.active,
        runtimeKind: AutoIPoERuntimeType.mape,
        terminalResultSupported: true,
        terminalResult: const AutoIPoETerminalResult(
          phase: AutoIPoETerminalPhase.completed,
          operation: AutoIPoETerminalResult.applyOperation,
          exitCode: 0,
          reason: 'Completed',
          connectivityVerified: true,
        ),
      );

      expect(AutoIPoEIssueMapper.isVerifiedActive(awaiting), isFalse);
      expect(AutoIPoEIssueMapper.isVerifiedActive(completed), isTrue);
    });

    test('uses a correlated terminal failure reason before stale Active state',
        () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          applyState: AutoIPoEApplyState.active,
          runtimeKind: AutoIPoERuntimeType.mape,
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.failed,
            operation: AutoIPoETerminalResult.applyOperation,
            exitCode: 0,
            reason: 'ConnectivityFailed',
            connectivityVerified: false,
          ),
        ),
      );

      expect(issue.code, 'ConnectivityFailed');
      expect(issue.retryable, isTrue);
      expect(issue.recoveryAction, AutoIPoERecoveryAction.retrySetup);
    });

    test('maps an exact Busy result to immediate retry guidance', () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          applyState: AutoIPoEApplyState.failed,
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.busy,
            operation: AutoIPoETerminalResult.applyOperation,
            exitCode: 75,
            reason: 'Busy',
            connectivityVerified: false,
          ),
        ),
      );

      expect(issue.code, 'Busy');
      expect(issue.retryable, isTrue);
      expect(issue.category, AutoIPoEIssueCategory.retryable);
      expect(issue.recoveryAction, AutoIPoERecoveryAction.retrySetup);
    });

    test('maps scheduled provider recovery without treating it as failure', () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          applyState: AutoIPoEApplyState.idle,
          lastError: 'StaleFailure',
          retryable: true,
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.retryScheduled,
            operation: AutoIPoETerminalResult.applyOperation,
            exitCode: 0,
            reason: 'RetryScheduled',
            connectivityVerified: false,
          ),
        ),
      );

      expect(issue.code, 'RetryScheduled');
      expect(issue.category, AutoIPoEIssueCategory.provider);
      expect(issue.retryable, isTrue);
      expect(issue.isTerminal, isFalse);
      expect(issue.hasScheduledRecovery, isTrue);
      expect(issue.requiresFreshApply, isFalse);
    });

    test('uses a known correlated marker reason instead of stale status text',
        () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          lastError: 'ConnectivityFailed',
          errorCategory: 'runtime',
          retryable: false,
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.failed,
            operation: AutoIPoETerminalResult.applyOperation,
            exitCode: 1,
            reason: 'DADDuplicate',
            connectivityVerified: false,
          ),
        ),
      );

      expect(issue.code, 'DADDuplicate');
      expect(issue.isTerminal, isTrue);
    });

    test('unknown correlated reason falls back to generic execution failure',
        () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          lastError: 'MadeUpProviderSuccess',
          errorCategory: 'runtime',
          retryable: false,
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.failed,
            operation: AutoIPoETerminalResult.applyOperation,
            exitCode: 1,
            reason: 'MadeUpProviderSuccess',
            connectivityVerified: false,
          ),
        ),
      );

      expect(issue.code, 'ExecutionFailed');
      expect(issue.category, AutoIPoEIssueCategory.runtime);
      expect(issue.isTerminal, isTrue);
    });

    test('keeps correlated BIGLOBE authentication guidance specific', () {
      final issue = AutoIPoEIssueMapper.from(
        status: _status(
          selectedMode: AutoIPoEMode.biglobeStaticIp,
          lastError: 'ProviderAuthenticationFailed',
          errorCategory: 'provider',
          retryable: false,
          errorFieldGroup: 'biglobeStaticIpSettings',
          terminalResultSupported: true,
          terminalResult: const AutoIPoETerminalResult(
            phase: AutoIPoETerminalPhase.failed,
            operation: AutoIPoETerminalResult.applyOperation,
            exitCode: 1,
            reason: 'ProviderUnavailable',
            connectivityVerified: false,
          ),
        ),
      );

      expect(issue.code, 'ProviderUnavailable');
      expect(issue.category, AutoIPoEIssueCategory.provider);
      expect(issue.fieldGroup, AutoIPoEFieldGroup.biglobeStaticIp);
      expect(issue.isTerminal, isTrue);
      expect(issue.recoveryAction, AutoIPoERecoveryAction.none);
    });
  });
}
