// The rules Advanced settings applies to an issue raised while it follows an
// Apply. These lived as two conditions inside a widget method and had no tests;
// between them they decide whether the page keeps waiting and whether the user
// is interrupted, which are not the same question.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue_presentation.dart';

AutoIPoEIssue _issue({
  required AutoIPoERecoveryAction action,
  bool retryable = true,
  AutoIPoEIssueCategory category = AutoIPoEIssueCategory.retryable,
  String code = 'Code',
}) =>
    AutoIPoEIssue(
      category: category,
      code: code,
      retryable: retryable,
      recoveryAction: action,
    );

void main() {
  test('a polling window ending keeps the page waiting and says nothing', () {
    final decision = decideAdvancedAutoIPoEIssue(
      _issue(action: AutoIPoERecoveryAction.continueChecking),
      isFinalizing: false,
      dialogVisible: false,
    );

    expect(decision.handled, isTrue);
    expect(decision.keepAwaiting, isTrue);
    // The worker is still running; interrupting for that would be noise.
    expect(decision.announce, isFalse);
  });

  test('a terminal failure stops the waiting and is announced', () {
    final decision = decideAdvancedAutoIPoEIssue(
      _issue(
        action: AutoIPoERecoveryAction.retrySetup,
        retryable: false,
        category: AutoIPoEIssueCategory.provider,
      ),
      isFinalizing: false,
      dialogVisible: false,
    );

    expect(decision.keepAwaiting, isFalse);
    expect(decision.announce, isTrue);
  });

  test('one needing a fresh Apply is announced without waiting on it', () {
    final decision = decideAdvancedAutoIPoEIssue(
      _issue(action: AutoIPoERecoveryAction.retrySetup),
      isFinalizing: false,
      dialogVisible: false,
    );

    expect(decision.keepAwaiting, isFalse);
    expect(decision.announce, isTrue);
  });

  test('a dialog already up suppresses the announcement but not the waiting',
      () {
    // At most one dialog, and the one on screen is describing the same
    // operation. The waiting decision is unaffected by what is on screen.
    final decision = decideAdvancedAutoIPoEIssue(
      _issue(
        action: AutoIPoERecoveryAction.retrySetup,
        retryable: false,
      ),
      isFinalizing: false,
      dialogVisible: true,
    );

    expect(decision.handled, isTrue);
    expect(decision.announce, isFalse);
  });

  test('while finalizing, nothing is touched at all', () {
    // Not "stop waiting" -- the page is already on its way to the saved state,
    // and writing these flags would drag it back.
    final decision = decideAdvancedAutoIPoEIssue(
      _issue(action: AutoIPoERecoveryAction.continueChecking),
      isFinalizing: true,
      dialogVisible: false,
    );

    expect(decision.handled, isFalse);
  });

  test('finalizing wins over an issue that would otherwise be announced', () {
    final decision = decideAdvancedAutoIPoEIssue(
      _issue(
        action: AutoIPoERecoveryAction.retrySetup,
        retryable: false,
      ),
      isFinalizing: true,
      dialogVisible: false,
    );

    expect(decision.handled, isFalse);
  });
}
