import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_issue.dart';

void main() {
  group('AutoIPoEIssueMapper.from — a timeout', () {
    // A timeout is retryable: the router did not answer in time, which says
    // nothing about the settings. It reaches this mapper as a TimeoutError —
    // from the request throttler, whose detail does not say "timeout", or from
    // the settings page's own wait, which has none (#1831).
    test('a TimeoutError with a detail of its own is retryable', () {
      final issue = AutoIPoEIssueMapper.from(
        error: const TimeoutError(detail: 'Throttler: request exceeded 15s'),
      );

      expect(issue.retryable, isTrue);
      expect(issue.category, AutoIPoEIssueCategory.retryable);
      expect(issue.recoveryAction, AutoIPoERecoveryAction.retrySetup);
    });

    test('a TimeoutError with no detail is retryable', () {
      final issue = AutoIPoEIssueMapper.from(error: const TimeoutError());

      expect(issue.retryable, isTrue);
      expect(issue.category, AutoIPoEIssueCategory.retryable);
      // The same as the throttler's, which has a detail: the detail changes only
      // the issue's code, and the code is never shown.
      expect(issue.recoveryAction, AutoIPoERecoveryAction.retrySetup);
    });

    test('an error that is not a timeout is not made retryable by this rule',
        () {
      final issue = AutoIPoEIssueMapper.from(
        error: const InvalidInputError(detail: 'InvalidMode'),
      );

      expect(issue.retryable, isFalse);
    });
  });
}
