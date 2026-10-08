import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/views/auto_ipoe_issue_localization.dart';
import 'package:ui_kit_library/ui_kit.dart';

Widget buildAutoIPoERuntime(
  BuildContext context,
  WidgetRef ref,
  AutoIPoESnapshot snapshot,
  AutoIPoEOutcome outcome,
  AutoIPoESubmission? submission, {
  bool inline = false,
  bool showRecoveryActions = true,
}) {
  final l = loc(context);
  final editor =
      ref.watch(surfaceStrategyProvider).internetSettingsEditor(() {});
  final progress = snapshot.requestId == submission?.requestId
      ? AutoIPoEReconciliationProgress.fromStructuredStatus(snapshot.runtime)
      : const AutoIPoEReconciliationProgress.initial();
  final rejection = ref.watch(autoIPoERejectionProvider);
  final readError = ref.watch(autoIPoEDataProvider).error;
  if (outcome == AutoIPoEOutcome.pending && readError != null) {
    final message = AppText.bodyMedium(
      localizeServiceError(context, readError),
    );
    return inline ? message : AppCard(child: message);
  }
  final issue = AutoIPoEIssueMapper.from(
    status: rejection == null
        ? snapshot.runtime
        : const AutoIPoEStatus.init().copyWith(lastError: rejection),
    mode: snapshot.settings.selectedMode,
  );
  final title = switch (outcome) {
    AutoIPoEOutcome.succeeded => submission?.reset == true
        ? l.autoIpoeModeDisabled
        : l.autoIpoeProgressReady,
    AutoIPoEOutcome.failed ||
    AutoIPoEOutcome.rejected =>
      autoIPoEIssueTitle(context, issue),
    AutoIPoEOutcome.retryScheduled => l.autoIpoeRetryScheduledTitle,
    AutoIPoEOutcome.busy => l.autoIpoeRecoveryTitle,
    AutoIPoEOutcome.pending => l.autoIpoeRecoveryChecking,
    AutoIPoEOutcome.idle =>
      snapshot.runtime.applyState == AutoIPoEApplyState.active
          ? l.autoIpoeApplyStateActive
          : l.autoIpoeApplyStateIdle,
  };
  final description = switch (outcome) {
    AutoIPoEOutcome.failed ||
    AutoIPoEOutcome.rejected =>
      autoIPoEIssueMessage(context, issue),
    AutoIPoEOutcome.retryScheduled => l.autoIpoeRetryScheduledDescription,
    AutoIPoEOutcome.busy => l.autoIpoeRecoveryDescription,
    AutoIPoEOutcome.pending => l.autoIpoeRecoveryNoDuplicateApply,
    _ => '',
  };
  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.titleMedium(title),
      if (outcome == AutoIPoEOutcome.pending) ...[
        AppGap.md(),
        AppLoader(value: progress.value),
        AppGap.sm(),
        AppText.bodyMedium(
          l.autoIpoeProgressStep(
            progress.currentStep,
            AutoIPoEReconciliationProgress.totalSteps,
          ),
        ),
        AppGap.sm(),
        AppText.bodyMedium(switch (progress.currentStep) {
          1 => l.autoIpoeProgressPreparing,
          2 => l.autoIpoeProgressConfiguring,
          3 => l.autoIpoeProgressWaiting,
          4 => l.autoIpoeProgressCheckingInternet,
          _ => l.autoIpoeProgressCheckingInternet,
        }),
      ],
      if (showRecoveryActions &&
          editor != null &&
          submission != null &&
          (outcome == AutoIPoEOutcome.pending ||
              outcome == AutoIPoEOutcome.rejected)) ...[
        AppGap.md(),
        AppText.bodySmall(l.autoIpoeResolvePendingDescription),
        AppButton.text(
          identifier: 'auto-ipoe-resolve-pending',
          label: l.autoIpoeResolvePending,
          onTap: () async {
            if (ref
                    .read(surfaceStrategyProvider)
                    .internetSettingsEditor(() {}) ==
                null) {
              return;
            }
            try {
              await ref.read(autoIPoEDataProvider.notifier).resolvePending();
            } catch (e) {
              if (context.mounted) {
                showFailedSnackBar(context, localizeServiceError(context, e));
              }
            }
          },
        ),
      ],
      if (description.isNotEmpty &&
          (showRecoveryActions || outcome != AutoIPoEOutcome.pending)) ...[
        AppGap.md(),
        AppText.bodyMedium(description),
      ],
      if (showRecoveryActions &&
          (outcome == AutoIPoEOutcome.pending ||
              outcome == AutoIPoEOutcome.retryScheduled ||
              outcome == AutoIPoEOutcome.busy)) ...[
        AppGap.md(),
        AppButton.text(
          identifier: 'auto-ipoe-continue-checking',
          label: l.autoIpoeRecoveryContinueChecking,
          onTap: () {
            ref.read(autoIPoEDataProvider.notifier).continueChecking();
            ref.read(autoIPoEDataProvider.notifier).refresh();
          },
        ),
      ],
    ],
  );
  return inline ? content : AppCard(child: content);
}
