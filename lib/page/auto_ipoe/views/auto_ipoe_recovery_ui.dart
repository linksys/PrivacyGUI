import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

String autoIPoEIssueTitle(BuildContext context, AutoIPoEIssue issue) {
  final l = loc(context);
  if (issue.hasScheduledRecovery) {
    return l.autoIpoeRetryScheduledTitle;
  }
  return switch (issue.category) {
    AutoIPoEIssueCategory.validation => l.autoIpoeErrorValidationTitle,
    AutoIPoEIssueCategory.provider => l.autoIpoeErrorProviderTitle,
    AutoIPoEIssueCategory.runtime => l.autoIpoeErrorRuntimeTitle,
    AutoIPoEIssueCategory.retryable => issue.requiresFreshApply
        ? l.autoIpoeRecoveryRetryTitle
        : l.autoIpoeRecoveryTitle,
    AutoIPoEIssueCategory.unknown => l.autoIpoeErrorUnknownTitle,
  };
}

String autoIPoEIssueMessage(BuildContext context, AutoIPoEIssue issue) {
  final l = loc(context);
  if (issue.hasScheduledRecovery) {
    return l.autoIpoeRetryScheduledDescription;
  }
  return switch (issue.category) {
    AutoIPoEIssueCategory.validation => l.autoIpoeErrorValidationMessage,
    AutoIPoEIssueCategory.provider => l.autoIpoeErrorProviderMessage,
    AutoIPoEIssueCategory.runtime => l.autoIpoeErrorRuntimeMessage,
    AutoIPoEIssueCategory.retryable => issue.requiresFreshApply
        ? l.autoIpoeRecoveryRetryDescription
        : l.autoIpoeRecoveryDescription,
    AutoIPoEIssueCategory.unknown => l.autoIpoeErrorUnknownMessage,
  };
}

enum AutoIPoERetryScheduledDialogAction {
  continueChecking,
  editSettings,
}

Future<AutoIPoERetryScheduledDialogAction?> showAutoIPoERetryScheduledDialog(
  BuildContext context,
  AutoIPoEIssue issue,
) {
  return showDialog<AutoIPoERetryScheduledDialogAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('autoIpoeRetryScheduledDialog'),
      title: AppText.titleLarge(autoIPoEIssueTitle(dialogContext, issue)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(autoIPoEIssueMessage(dialogContext, issue)),
          const AppGap.small3(),
          AppText.bodySmall(
            loc(dialogContext).autoIpoeRetryScheduledGuidance,
          ),
        ],
      ),
      actions: [
        AppTextButton(
          loc(dialogContext).autoIpoeEditSettings,
          onTap: () {
            Navigator.of(dialogContext).pop(
              AutoIPoERetryScheduledDialogAction.editSettings,
            );
          },
        ),
        AppFilledButton(
          loc(dialogContext).autoIpoeRecoveryContinueChecking,
          onTap: () {
            Navigator.of(dialogContext).pop(
              AutoIPoERetryScheduledDialogAction.continueChecking,
            );
          },
        ),
      ],
    ),
  );
}

Future<void> showAutoIPoETerminalFailureDialog(
  BuildContext context,
  AutoIPoEIssue issue,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('autoIpoeTerminalFailureDialog'),
      title: AppText.titleLarge(autoIPoEIssueTitle(dialogContext, issue)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(autoIPoEIssueMessage(dialogContext, issue)),
          const AppGap.medium(),
          AppText.bodySmall(
            '${loc(dialogContext).autoIpoeErrorCode}: ${issue.code}',
          ),
        ],
      ),
      actions: [
        AppTextButton(
          loc(dialogContext).autoIpoeEditSettings,
          onTap: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

class AutoIPoECompactProgressContent extends StatelessWidget {
  const AutoIPoECompactProgressContent({
    super.key,
    required this.progress,
    this.centered = false,
  });

  final AutoIPoEReconciliationProgress progress;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l = loc(context);
    final progressMessage = switch (progress.currentStep) {
      1 => l.autoIpoeProgressPreparing,
      2 => l.autoIpoeProgressConfiguring,
      3 => l.autoIpoeProgressWaiting,
      4 => l.autoIpoeProgressCheckingInternet,
      _ => l.autoIpoeProgressReady,
    };
    final progressDetail = switch (progress.phase) {
      AutoIPoEProgressPhase.validatingTunnel =>
        l.autoIpoeProgressValidatingConnection,
      AutoIPoEProgressPhase.checkingInternet when progress.hasAttempt =>
        l.autoIpoeProgressConnectivityAttempt(
          progress.attempt!,
          progress.attemptTotal!,
        ),
      _ => null,
    };
    return Column(
      key: const ValueKey('autoIpoECompactProgressPanel'),
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AutoIPoEReconciliationProgressIndicator(progress: progress),
        const AppGap.medium(),
        AppText.bodyMedium(
          progressMessage,
          key: const ValueKey('autoIpoEProgressMessage'),
        ),
        if (progressDetail != null) ...[
          const AppGap.small3(),
          AppText.bodySmall(
            progressDetail,
            key: const ValueKey('autoIpoEProgressDetail'),
          ),
        ],
      ],
    );
  }
}

class AutoIPoERecoveryPanel extends StatelessWidget {
  const AutoIPoERecoveryPanel({
    super.key,
    required this.isChecking,
    required this.onContinueChecking,
    required this.onRetry,
    required this.onEditSettings,
    this.issue,
    this.compactProgress = false,
    this.progress = const AutoIPoEReconciliationProgress.initial(),
  });

  final bool isChecking;
  final AutoIPoEIssue? issue;
  final VoidCallback onContinueChecking;
  final VoidCallback onRetry;
  final VoidCallback onEditSettings;
  final bool compactProgress;
  final AutoIPoEReconciliationProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = loc(context);
    final recoveryAction =
        issue?.recoveryAction ?? AutoIPoERecoveryAction.continueChecking;
    final requiresFreshApply =
        recoveryAction == AutoIPoERecoveryAction.retrySetup;
    final hasScheduledRecovery =
        recoveryAction == AutoIPoERecoveryAction.scheduledRetry;
    if (compactProgress && !requiresFreshApply && !hasScheduledRecovery) {
      return AutoIPoECompactProgressContent(progress: progress);
    }
    return AppCard(
      key: const ValueKey('autoIpoERecoveryPanel'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium(
            hasScheduledRecovery
                ? l.autoIpoeRetryScheduledTitle
                : requiresFreshApply
                    ? l.autoIpoeRecoveryRetryTitle
                    : l.autoIpoeRecoveryTitle,
          ),
          const AppGap.medium(),
          AppText.bodyMedium(
            hasScheduledRecovery
                ? l.autoIpoeRetryScheduledDescription
                : requiresFreshApply
                    ? l.autoIpoeRecoveryRetryDescription
                    : l.autoIpoeRecoveryDescription,
          ),
          const AppGap.small3(),
          AppText.bodySmall(
            hasScheduledRecovery
                ? l.autoIpoeRetryScheduledGuidance
                : requiresFreshApply
                    ? l.autoIpoeRecoveryFreshApplyRequired
                    : l.autoIpoeRecoveryNoDuplicateApply,
          ),
          if (issue != null) ...[
            const AppGap.small3(),
            AppText.bodySmall('${l.autoIpoeErrorCode}: ${issue!.code}'),
          ],
          const AppGap.large2(),
          Wrap(
            spacing: Spacing.small3,
            runSpacing: Spacing.small3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!requiresFreshApply)
                AppFilledButton(
                  isChecking
                      ? l.autoIpoeRecoveryChecking
                      : l.autoIpoeRecoveryContinueChecking,
                  onTap: isChecking ? null : onContinueChecking,
                ),
              if (requiresFreshApply)
                AppFilledButton(
                  l.autoIpoeRecoveryRetry,
                  onTap: isChecking ? null : onRetry,
                ),
              AppTextButton(
                l.autoIpoeEditSettings,
                onTap: onEditSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AutoIPoEReconciliationProgressIndicator extends StatelessWidget {
  const AutoIPoEReconciliationProgressIndicator({
    super.key,
    required this.progress,
    this.displayTotalSteps = AutoIPoEReconciliationProgress.totalSteps,
  }) : assert(displayTotalSteps > 0);

  final AutoIPoEReconciliationProgress progress;
  final int displayTotalSteps;

  @override
  Widget build(BuildContext context) {
    final visibleStep = progress.currentStep > displayTotalSteps
        ? displayTotalSteps
        : progress.currentStep;
    final progressText = loc(context).autoIpoeProgressStep(
      visibleStep,
      displayTotalSteps,
    );
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      tween: Tween<double>(end: visibleStep / displayTotalSteps),
      builder: (context, value, child) => SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                key: const ValueKey('autoIpoEProgressIndicator'),
                value: value,
                strokeWidth: 8,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                semanticsLabel: loc(context).autoIpoeRecoveryTitle,
                semanticsValue: progressText,
              ),
            ),
            AppText.titleLarge(
              '$visibleStep/$displayTotalSteps',
              key: const ValueKey('autoIpoEProgressStep'),
            ),
          ],
        ),
      ),
    );
  }
}
