import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_issue.dart';

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
