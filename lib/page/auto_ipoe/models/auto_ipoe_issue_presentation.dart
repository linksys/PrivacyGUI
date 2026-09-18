import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';

/// What Advanced settings should do about an issue raised while it is following
/// an Apply.
///
/// The two decisions do not coincide, which is why they are separate fields. A
/// scheduled provider retry keeps the page waiting *and* has to tell the user,
/// because nothing further will happen until the retry fires. An ordinary
/// polling window ending keeps the page waiting and says nothing. A terminal
/// failure stops the waiting and must be announced.
class AdvancedAutoIPoEIssueDecision {
  /// Change nothing. Used while the save is being finalized: the page is already
  /// on its way to the saved state, and a late issue must not drag it back.
  const AdvancedAutoIPoEIssueDecision.ignore()
      : handled = false,
        keepAwaiting = false,
        announce = false;

  const AdvancedAutoIPoEIssueDecision._({
    required this.keepAwaiting,
    required this.announce,
  }) : handled = true;

  /// False means leave every flag exactly as it is, rather than setting them to
  /// the values below.
  final bool handled;

  /// Whether the page should go on waiting for this Apply to resolve.
  final bool keepAwaiting;

  /// Whether the user should be interrupted about it.
  final bool announce;
}

/// Decides how to present [issue].
///
/// [dialogVisible] suppresses only the announcement: one dialog at a time, and
/// the one already up is describing the same operation.
AdvancedAutoIPoEIssueDecision decideAdvancedAutoIPoEIssue(
  AutoIPoEIssue issue, {
  required bool isFinalizing,
  required bool dialogVisible,
}) {
  if (isFinalizing) {
    return const AdvancedAutoIPoEIssueDecision.ignore();
  }
  final keepAwaiting =
      issue.recoveryAction == AutoIPoERecoveryAction.continueChecking ||
          issue.hasScheduledRecovery;
  final worthTelling = issue.isTerminal ||
      issue.requiresFreshApply ||
      issue.hasScheduledRecovery;
  return AdvancedAutoIPoEIssueDecision._(
    keepAwaiting: keepAwaiting,
    announce: worthTelling && !dialogVisible,
  );
}
