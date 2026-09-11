import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows a confirmation dialog for destructive system actions
/// (Reboot / Factory Reset).
///
/// Returns `true` if the user confirms.
Future<bool?> showConfirmActionDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) {
  return showSimpleAppDialog<bool>(
    context,
    title: title,
    content: AppText.bodyMedium(message),
    actions: [
      AppButton.text(
        identifier: 'admin-confirm-action-cancel',
        label: loc(context).cancel,
        onTap: () => context.pop(),
      ),
      // `dangerText`, not `primary`: Reboot / Factory Reset are destructive, so
      // they follow the same pair as `showRebootModal` / `showFactoryResetModal`
      // (`dialogs.dart:456,494`) rather than the affirmative `primary` used for
      // save/confirm dialogs (#1224).
      AppButton.dangerText(
        identifier: 'admin-confirm-action-confirm',
        label: confirmLabel,
        onTap: () => context.pop(true),
      ),
    ],
  );
}
