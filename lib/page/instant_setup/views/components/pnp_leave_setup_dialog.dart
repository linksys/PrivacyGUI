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
/// the unsaved-changes one, which says exactly what leaving costs — shown only
/// when there is something to lose, [unsaved]. With nothing edited it said
/// there were unsaved changes when there were none (#1816 review); the title
/// and the two buttons say all there is.
Future<bool?> showPnpLeaveSetupAlert(
  BuildContext context, {
  required bool unsaved,
}) {
  return showSimpleAppDialog<bool>(
    context,
    title: loc(context).logout,
    content:
        unsaved ? AppText.bodyMedium(loc(context).unsavedChangesDesc) : null,
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
