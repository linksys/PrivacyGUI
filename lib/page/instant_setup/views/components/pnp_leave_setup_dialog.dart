import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Asked when the user leaves the PnP wizard while editing — Back from its
/// first step (#1511 P4).
///
/// Leaving the setup means logging out: there is nothing before the wizard
/// but the entry checks, which would only start it again, and the dashboard is
/// not where an unfinished setup belongs. Returns `true` to log out.
///
/// Existing strings only: the title is the app's "Log out", and the message is
/// the unsaved-changes one, which says exactly what leaving costs.
Future<bool?> showPnpLeaveSetupAlert(BuildContext context) {
  return showMessageAppDialog<bool>(
    context,
    title: loc(context).logout,
    message: loc(context).unsavedChangesDesc,
    actions: [
      AppButton.text(
        label: loc(context).cancel,
        identifier: 'pnp-leave-setup-cancel',
        onTap: () => context.pop(false),
      ),
      AppButton.dangerText(
        label: loc(context).logout,
        identifier: 'pnp-leave-setup-log-out',
        onTap: () => context.pop(true),
      ),
    ],
  );
}
