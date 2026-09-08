import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The two bail-out affordances a recovery dialog can offer, one per
/// `SessionOutcome`.
///
/// ## Why they are widgets, and why they are here
///
/// `SurfaceStrategy.sessionExitAction()` hands one of these to both recovery
/// dialogs, so neither dialog contains an `if` about which mode it is in. Making
/// them named widgets rather than inline `AppButton.text(...)` calls inside
/// `LocalSurface`/`RemoteSurface` keeps those two files pure composition —
/// constructor calls only — and it is what puts `loc(context).returnToLoginPage`
/// outside `lib/page/` entirely, which is acceptance 5c of #1497 stated as a
/// grep: *no page decides where an ending session lands*.
///
/// `lib/components/` rather than beside the dialogs for the same reason. The
/// strategy implementations themselves live under `lib/page/_shared/mode/`
/// (Article XVII Rule 3 — they build `Widget`s, and `lib/core/` may not depend on
/// `lib/page/`), so authoring the labels inline there would have satisfied the
/// contract and failed the grep.
///
/// ## The identifiers are the firmware dialog's, deliberately
///
/// Both were introduced by `firmware_update_recovery_dialog.dart` and are kept
/// verbatim even though these widgets now also serve the generic recovery
/// dialog. `identifier:` values are harvested by reading Dart source *text* into
/// the E2E suite's identifier list, in another repository this change cannot see;
/// renaming them to something mode-neutral would silently retire two selectors
/// there to buy a tidier name here. The generic dialog previously had no
/// identifier at all, so this is added coverage rather than moved coverage.
class ReturnToLoginAction extends ConsumerWidget {
  const ReturnToLoginAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton.text(
      label: loc(context).returnToLoginPage,
      identifier: 'firmware-recovery-return-login',
      onTap: () {
        logger.d('[Recovery] User tapped Return to login');
        ref.read(appConnectionStateProvider.notifier).exitToLogout();
      },
    );
  }
}

/// The Remote Assistance counterpart: end the Guardian session instead of
/// offering a login page the one-shot token can never get back into.
///
/// Goes straight to `logout(cause:)` rather than through `exitToLogout()`, which
/// would be the tidier-looking reuse: `exitToLogout()`'s own `logout()` is bare,
/// and its default [EndCause.sessionLost] skips `endSessionForCA` on the one path
/// where the operator explicitly asked to end the session. Navigation is the
/// route redirect's job either way — cause 3 clears the RA session and the
/// `/usp*` guard answers a session-less remote build with the confirm page's
/// session-ended surface.
class EndSessionAction extends ConsumerWidget {
  const EndSessionAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton.text(
      label: loc(context).endSession,
      identifier: 'firmware-recovery-end-session',
      onTap: () {
        logger.d('[Recovery] Support engineer tapped End session');
        ref.read(authProvider.notifier).logout(cause: EndCause.userRequested);
      },
    );
  }
}
