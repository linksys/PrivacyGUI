import 'package:flutter/material.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

showSuccessSnackBar(BuildContext context, String message) {
  final appColors = Theme.of(context).extension<AppColorScheme>();
  showSimpleSnackBar(
    context,
    message,
    background: appColors?.semanticSuccess,
    textColor: appColors?.onSemanticSuccess,
    borderColor: appColors?.onSemanticSuccess,
  );
}

showFailedSnackBar(BuildContext context, String message) {
  final appColors = Theme.of(context).extension<AppColorScheme>();
  showSimpleSnackBar(
    context,
    message,
    background: appColors?.semanticDanger,
    textColor: appColors?.onSemanticDanger,
    borderColor: appColors?.onSemanticDanger,
  );
}

/// Reports a save that threw.
///
/// A [SavedButUnconfirmedError] is a write that landed and could not be read
/// back (#1212): it is shown neutrally, because the failure style would have
/// the user press Save again and rewrite what the router already holds. Any
/// other error is a save that failed and keeps [showFailedSnackBar]: one that
/// wrote nothing, [SaveDiscardedForRouterRowsError] included (the page was
/// reloaded instead of writing, and the user has to make the change again),
/// and a [SavePartlyAppliedError] (issue #1711), whose message says which part
/// of it landed.
///
/// [localize] words the message; a page whose save errors read through its own
/// localizer passes it (Internet Settings names the field the firmware
/// refused). The style is chosen here either way.
showSaveErrorSnackBar(BuildContext context, Object error,
    {String Function(BuildContext context, Object error) localize =
        localizeServiceError}) {
  final message = localize(context, error);
  if (error is SavedButUnconfirmedError) {
    showSimpleSnackBar(context, message);
  } else {
    showFailedSnackBar(context, message);
  }
}

showSimpleSnackBar(
  BuildContext context,
  String message, {
  Widget? icon,
  Color? borderColor,
  Color? textColor,
  Color? background,
}) {
  showSnackBar(
    context,
    background: background,
    content: AppSurface(
      style: SurfaceStyle(
        backgroundColor:
            background ?? Theme.of(context).colorScheme.secondaryContainer,
        contentColor:
            textColor ?? Theme.of(context).colorScheme.onSecondaryContainer,
        borderColor:
            borderColor ?? Theme.of(context).colorScheme.onSecondaryContainer,
        borderWidth: 1.0,
        borderRadius: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          if (icon != null) ...[
            icon,
            AppGap.lg(),
          ],
          Flexible(
            child: AppText.bodySmall(
              message,
              color: textColor ??
                  Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    ),
  );
}

showSnackBar(BuildContext context,
    {required Widget content, Color? background}) {
  final useWidth = shellNavigatorKey.currentContext == null;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: useWidth
          ? null
          : context.isMobileLayout
              ? const EdgeInsets.only(
                  left: AppSpacing.xxl,
                  right: AppSpacing.xxl,
                  bottom: AppSpacing.xxl)
              : EdgeInsets.only(
                  left: context.screenWidth * 0.6,
                  right: AppSpacing.xxl,
                  bottom: AppSpacing.xxl),
      width: !useWidth ? null : context.screenWidth * 0.6,
      content: content,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
