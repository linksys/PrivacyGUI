import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';

void main() {
  group('BIGLOBE static IP settings', () {
    test('parses the wire mode and stored credential markers', () {
      final settings = AutoIPoESettings.fromMap(const {
        'isEnabled': true,
        'selectedMode': 'BIGLOBEStaticIP',
        'biglobeStaticIpSettings': {
          'userId': {'hasStoredValue': true},
          'userPassword': {'hasStoredValue': true},
        },
      });

      expect(settings.selectedMode, AutoIPoEMode.biglobeStaticIp);
      expect(settings.biglobeStaticIpSettings.userId.value, isNull);
      expect(
        settings.biglobeStaticIpSettings.userId.hasStoredValue,
        isTrue,
      );
      expect(settings.biglobeStaticIpSettings.userPassword.value, isNull);
      expect(
        settings.biglobeStaticIpSettings.userPassword.hasStoredValue,
        isTrue,
      );
    });

    test('serializes the exact settings key and SecretValue envelopes', () {
      final settings = const AutoIPoESettings.init().copyWith(
        isEnabled: true,
        selectedMode: AutoIPoEMode.biglobeStaticIp,
        biglobeStaticIpSettings: const BiglobeStaticIPSettings(
          userId: AutoIPoESecret(value: 'biglobe_id'),
          userPassword: AutoIPoESecret(value: 'pw-123'),
        ),
      );

      final map = settings.toMap();
      expect(map['selectedMode'], 'BIGLOBEStaticIP');
      expect(map['biglobeStaticIpSettings'], {
        'userId': {'value': 'biglobe_id', 'hasStoredValue': false},
        'userPassword': {'value': 'pw-123', 'hasStoredValue': false},
      });
    });
  });

  group('AutoIPoELog.fromMap', () {
    test('explicit backend failure is not promoted by the log footer', () {
      final log = AutoIPoELog.fromMap(const {
        'content': 'apply failed\n### end of logging ###',
        'isComplete': false,
        'rebootRecommended': false,
      });

      expect(log.isComplete, isFalse);
      expect(log.rebootRecommended, isFalse);
    });

    test('legacy response without isComplete may use the log footer', () {
      final log = AutoIPoELog.fromMap(const {
        'content': 'apply complete\n### end of logging ###',
      });

      expect(log.isComplete, isTrue);
      expect(log.rebootRecommended, isFalse);
    });
  });

  group('AutoIPoE reconciliation progress', () {
    test('moves through tunnel, connectivity, and final success stages', () {
      expect(
        const AutoIPoEReconciliationProgress.initial().currentStep,
        1,
      );
      expect(
        const AutoIPoEReconciliationProgress.waitingForTunnel().currentStep,
        2,
      );
      expect(
        const AutoIPoEReconciliationProgress.tunnelCompleted().currentStep,
        3,
      );
      expect(
        const AutoIPoEReconciliationProgress.connectivityChecking().currentStep,
        4,
      );
      expect(
        const AutoIPoEReconciliationProgress.completed().currentStep,
        5,
      );
    });

    test('maps structured runtime phases onto five friendly stages', () {
      AutoIPoEStatus statusFor(
        AutoIPoEProgressPhase phase, {
        int? attempt,
        int? total,
        bool? connectivityVerified,
      }) =>
          const AutoIPoEStatus.init().copyWith(
            progressPhase: phase,
            progressAttempt: attempt,
            progressTotal: total,
            connectivityVerified: connectivityVerified,
          );

      expect(
        AutoIPoEReconciliationProgress.fromStructuredStatus(
          statusFor(AutoIPoEProgressPhase.detecting),
        ).currentStep,
        1,
      );
      expect(
        AutoIPoEReconciliationProgress.fromStructuredStatus(
          statusFor(AutoIPoEProgressPhase.provisioning),
        ).currentStep,
        2,
      );
      expect(
        AutoIPoEReconciliationProgress.fromStructuredStatus(
          statusFor(AutoIPoEProgressPhase.retryScheduled),
        ).currentStep,
        2,
      );
      expect(
        AutoIPoEReconciliationProgress.fromStructuredStatus(
          statusFor(AutoIPoEProgressPhase.applyingNetwork),
        ).currentStep,
        3,
      );
      expect(
        AutoIPoEReconciliationProgress.fromStructuredStatus(
          statusFor(AutoIPoEProgressPhase.validatingTunnel),
        ).currentStep,
        4,
      );

      final attempt = AutoIPoEReconciliationProgress.fromStructuredStatus(
        statusFor(
          AutoIPoEProgressPhase.checkingInternet,
          attempt: 3,
          total: 5,
        ),
      );
      expect(attempt.currentStep, 4);
      expect((attempt.attempt, attempt.attemptTotal), (3, 5));

      expect(
        AutoIPoEReconciliationProgress.fromStructuredStatus(
          statusFor(
            AutoIPoEProgressPhase.completed,
            connectivityVerified: true,
          ),
        ).currentStep,
        5,
      );
    });

    test('never moves backwards but accepts newer attempts within step 4', () {
      const validating = AutoIPoEReconciliationProgress.validatingTunnel();
      const attempt2 = AutoIPoEReconciliationProgress.connectivityChecking(
        attempt: 2,
        attemptTotal: 5,
      );
      const attempt3 = AutoIPoEReconciliationProgress.connectivityChecking(
        attempt: 3,
        attemptTotal: 5,
      );

      expect(validating.advanceTo(attempt2), attempt2);
      expect(attempt2.advanceTo(attempt3), attempt3);
      expect(attempt3.advanceTo(attempt2), attempt3);
      expect(
        attempt3.advanceTo(
          const AutoIPoEReconciliationProgress(
            currentStep: 3,
            phase: AutoIPoEProgressPhase.applyingNetwork,
          ),
        ),
        attempt3,
      );
    });
  });

  group('AutoIPoEStatus structured progress', () {
    test('parses the exact operation-correlated terminal result', () {
      final status = AutoIPoEStatus.fromMap(const {
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'completed',
          'operation': 'auto_ipoe',
          'exitCode': 0,
          'reason': 'Completed',
          'connectivityVerified': true,
        },
      });

      expect(status.terminalResultSupported, isTrue);
      expect(status.terminalResult?.phase, AutoIPoETerminalPhase.completed);
      expect(status.terminalResult?.operation, 'auto_ipoe');
      expect(status.terminalResult?.exitCode, 0);
      expect(status.terminalResult?.reason, 'Completed');
      expect(status.hasVerifiedBackendConnectivity, isTrue);
      expect(status.hasTerminalApplyFailure, isFalse);
    });

    test('keeps a present malformed terminal result distinct from legacy', () {
      final status = AutoIPoEStatus.fromMap(const {
        'applyState': 'Failed',
        'progressPhase': 'Failed',
        'terminalResult': {
          'phase': 'completed',
          'operation': 'auto_ipoe',
          'exitCode': '0',
          'reason': 'Completed',
          'connectivityVerified': true,
        },
      });

      expect(status.terminalResultSupported, isTrue);
      expect(status.terminalResult, isNull);
      expect(status.hasVerifiedBackendConnectivity, isFalse);
      expect(status.hasTerminalApplyFailure, isFalse);
      expect(status.isTerminalApplyResultPending, isTrue);
    });

    test('does not accept mismatched or internally inconsistent results', () {
      final mismatched = AutoIPoEStatus.fromMap(const {
        'applyState': 'Failed',
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'completed',
          'operation': 'static_ip',
          'exitCode': 0,
          'reason': 'Completed',
          'connectivityVerified': true,
        },
      });
      final malformed = AutoIPoEStatus.fromMap(const {
        'applyState': 'Failed',
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'completed',
          'operation': 'auto_ipoe',
          'exitCode': 1,
          'reason': 'Completed',
          'connectivityVerified': true,
        },
      });

      expect(mismatched.terminalResult?.isValid, isTrue);
      expect(mismatched.hasVerifiedBackendConnectivity, isFalse);
      expect(mismatched.hasTerminalApplyFailure, isFalse);
      expect(mismatched.isTerminalApplyResultPending, isTrue);
      expect(malformed.terminalResult?.isValid, isFalse);
      expect(malformed.hasVerifiedBackendConnectivity, isFalse);
      expect(malformed.hasTerminalApplyFailure, isFalse);
      expect(malformed.isTerminalApplyResultPending, isTrue);
    });

    test('parses a correlated failed result as terminal failure', () {
      final status = AutoIPoEStatus.fromMap(const {
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'failed',
          'operation': 'auto_ipoe',
          'exitCode': 1,
          'reason': 'ConnectivityFailed',
          'connectivityVerified': false,
        },
      });

      expect(status.hasTerminalApplyFailure, isTrue);
      expect(status.hasVerifiedBackendConnectivity, isFalse);
      expect(status.isTerminalApplyResultPending, isFalse);
    });

    test('accepts a backend-correlated failed result with exit code zero', () {
      final status = AutoIPoEStatus.fromMap(const {
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'failed',
          'operation': 'auto_ipoe',
          'exitCode': 0,
          'reason': 'MAPEInterfaceDown',
          'connectivityVerified': false,
        },
      });

      expect(status.terminalResult?.isValid, isTrue);
      expect(status.hasTerminalApplyFailure, isTrue);
      expect(status.hasVerifiedBackendConnectivity, isFalse);
      expect(status.isTerminalApplyResultPending, isFalse);
    });

    test('parses a correlated Busy result as an immediate outcome', () {
      final status = AutoIPoEStatus.fromMap(const {
        'applyState': 'Failed',
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'busy',
          'operation': 'auto_ipoe',
          'exitCode': 75,
          'reason': 'Busy',
          'connectivityVerified': false,
        },
      });

      expect(status.terminalResult?.isValid, isTrue);
      expect(status.hasTerminalApplyFailure, isFalse);
      expect(status.hasTerminalApplyBusy, isTrue);
      expect(status.hasTerminalApplyOutcome, isTrue);
      expect(status.isTerminalApplyResultPending, isFalse);
    });

    test('parses scheduled provider recovery as a distinct outcome', () {
      final status = AutoIPoEStatus.fromMap(const {
        'applyState': 'Idle',
        'progressPhase': 'RetryScheduled',
        'lastResult': 'RetryScheduled',
        'retryable': true,
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'retry_scheduled',
          'operation': 'auto_ipoe',
          'exitCode': 0,
          'reason': 'RetryScheduled',
          'connectivityVerified': false,
        },
      });

      expect(status.progressPhase, AutoIPoEProgressPhase.retryScheduled);
      expect(status.terminalResult?.isValid, isTrue);
      expect(status.hasTerminalApplyRetryScheduled, isTrue);
      expect(status.hasVerifiedBackendConnectivity, isFalse);
      expect(status.hasTerminalApplyFailure, isFalse);
      expect(status.hasTerminalApplyOutcome, isTrue);
      expect(status.isTerminalApplyResultPending, isFalse);
    });

    test('never promotes completed progress without verified connectivity', () {
      final status = AutoIPoEStatus.fromMap(const {
        'applyState': 'Active',
        'progressPhase': 'Completed',
        'connectivityVerified': false,
        'terminalResultSupported': true,
        'terminalResult': {
          'phase': 'completed',
          'operation': 'auto_ipoe',
          'exitCode': 0,
          'reason': 'Completed',
          'connectivityVerified': false,
        },
      });

      expect(status.hasVerifiedBackendConnectivity, isFalse);
      expect(status.terminalResult?.isValid, isFalse);
      expect(status.isTerminalApplyResultPending, isTrue);
    });

    test('parses optional progress and connectivity fields', () {
      final status = AutoIPoEStatus.fromMap(const {
        'progressPhase': 'checking_internet',
        'progressAttempt': 3,
        'progressTotal': 5,
        'connectivityVerified': false,
      });

      expect(status.progressPhase, AutoIPoEProgressPhase.checkingInternet);
      expect((status.validProgressAttempt, status.validProgressTotal), (3, 5));
      expect(status.connectivityVerified, isFalse);
      expect(status.hasStructuredProgress, isTrue);
      expect(status.hasVerifiedBackendConnectivity, isFalse);
    });

    test('accepts every runtime phase and its normalized JNAP value', () {
      const mappings = <String, AutoIPoEProgressPhase>{
        'checking_ipv6': AutoIPoEProgressPhase.detecting,
        'Detecting': AutoIPoEProgressPhase.detecting,
        'getting_isp_settings': AutoIPoEProgressPhase.provisioning,
        'Provisioning': AutoIPoEProgressPhase.provisioning,
        'applying_network': AutoIPoEProgressPhase.applyingNetwork,
        'ApplyingNetwork': AutoIPoEProgressPhase.applyingNetwork,
        'validating_connection': AutoIPoEProgressPhase.validatingTunnel,
        'ValidatingTunnel': AutoIPoEProgressPhase.validatingTunnel,
        'checking_internet': AutoIPoEProgressPhase.checkingInternet,
        'CheckingInternet': AutoIPoEProgressPhase.checkingInternet,
        'retry_scheduled': AutoIPoEProgressPhase.retryScheduled,
        'RetryScheduled': AutoIPoEProgressPhase.retryScheduled,
        'completed': AutoIPoEProgressPhase.completed,
        'Completed': AutoIPoEProgressPhase.completed,
        'failed': AutoIPoEProgressPhase.failed,
        'Failed': AutoIPoEProgressPhase.failed,
      };

      for (final entry in mappings.entries) {
        expect(
          AutoIPoEStatus.fromMap({
            'progressPhase': entry.key,
          }).progressPhase,
          entry.value,
          reason: 'wire value ${entry.key}',
        );
      }
    });

    test('keeps legacy responses distinguishable from explicit false', () {
      final legacy = AutoIPoEStatus.fromMap(const {});
      final legacyFailed = AutoIPoEStatus.fromMap(const {
        'applyState': 'Failed',
      });
      final completed = AutoIPoEStatus.fromMap(const {
        'progressPhase': 'Completed',
        'connectivityVerified': true,
      });

      expect(legacy.progressPhase, isNull);
      expect(legacy.connectivityVerified, isNull);
      expect(legacy.terminalResultSupported, isFalse);
      expect(legacy.hasStructuredProgress, isFalse);
      expect(legacyFailed.hasTerminalApplyFailure, isTrue);
      expect(legacyFailed.isTerminalApplyResultPending, isFalse);
      expect(completed.hasVerifiedBackendConnectivity, isTrue);
    });

    test('ignores malformed or out-of-range attempt counters', () {
      for (final counters in const [
        {'progressAttempt': 0, 'progressTotal': 5},
        {'progressAttempt': 3, 'progressTotal': 101},
        {'progressAttempt': 6, 'progressTotal': 5},
        {'progressAttempt': '3', 'progressTotal': 5},
      ]) {
        final status = AutoIPoEStatus.fromMap({
          'progressPhase': 'checking_internet',
          ...counters,
        });
        expect(status.validProgressAttempt, isNull);
        expect(status.validProgressTotal, isNull);
      }
    });
  });
}
