import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Enters recovery mode, shows a spinner dialog while probing the router,
/// and auto-dismisses when recovery completes or the user bails out.
///
/// Call this after a mutation that causes the router to restart (WiFi change,
/// reboot, factory reset, firmware upgrade, etc.).
Future<void> showRecoveryDialog(
  BuildContext context,
  WidgetRef ref, {
  required RecoveryTrigger trigger,
  Duration cooldown = const Duration(seconds: 20),
  bool healthOnly = false,
  bool skipEnterWaiting = false,
  String? title,
  String? message,
  String? successMessage,
}) async {
  logger
      .d('[Recovery] showRecoveryDialog: trigger=$trigger, cooldown=$cooldown, '
          'healthOnly=$healthOnly, skipEnterWaiting=$skipEnterWaiting');

  if (!skipEnterWaiting) {
    final waiting = ref.read(appConnectionStateProvider.notifier).enterWaiting(
          context: RecoveryContext(
            trigger: trigger,
            cooldown: cooldown,
            healthOnly: healthOnly,
          ),
        );

    // This mode has nothing to recover from — the mutation did not interrupt its
    // path to the router. Showing the dialog anyway would hang it: the listener
    // below pops on a *transition* into `authenticated`, and the app never left
    // it. See `RemoteProximityStrategy.planFor` for the case that measures this
    // way (Remote Assistance + a Wi-Fi change, where the Guardian path runs over
    // the WAN uplink and the restarting radios are not on it).
    if (!waiting) {
      logger.d('[Recovery] No recovery needed for $trigger — skipping dialog');
      if (successMessage != null) {
        showSuccessSnackBar(context, successMessage);
      }
      return;
    }
  }

  final navigator = Navigator.of(context, rootNavigator: true);

  final sub = ref.listenManual(appConnectionStateProvider, (prev, next) {
    logger.d('[Recovery] appConnectionState changed: $prev -> $next');
    if (next == AppConnectionState.authenticated) {
      logger.d('[Recovery] Popping recovery dialog (recovered)');
      navigator.pop();
    }
    // loggedOut: don't pop — route redirect will replace the entire page stack
  });

  logger.d('[Recovery] Showing recovery dialog');
  await showAppSpinnerDialog(
    context,
    title: title ?? 'Router is applying changes',
    messages: [
      message ??
          'Your Wi-Fi network may restart. Please reconnect to your router\'s network if needed.',
    ],
    actions: [
      // Acceptances 1 and 2 of #1323: the bail-out affordance is *relabelled and
      // rewired* per mode, not removed. `exitToLogout()` clears the credential and
      // lets the route redirect take the app to the login page — correct locally,
      // and in Remote Assistance an offer to go somewhere that is not reachable:
      // the credential was a one-shot Guardian token, so there is no password to
      // type and no way back in. Worse, the button reads as the *escape hatch*
      // from a recovery wait, so a support engineer presses it and is left on a
      // dead login form with the Guardian session still running.
      //
      // THE `else` IS NOT OPTIONAL, and the first cut of this change omitted it.
      // This is the whole `actions:` list, `showAppSpinnerDialog` passes
      // `barrierDismissible: false`, and the only `pop` is the `listenManual`
      // above, which fires on a transition *into* `authenticated` — deliberately
      // not on `loggedOut`. So a gate with no `else` renders a modal with no
      // affordance and no barrier, escapable only by the router coming back. In RA
      // that is reachable on three triggers `RemoteProximityStrategy.planFor`
      // still answers `needsRecovery: true` for — `natural`, `operationalReboot`
      // and `operationalFactoryReset` — and a Guardian-side reboot takes the
      // agent down with the box, which is exactly when it will not come back
      // quickly. That is acceptance 6, and an empty action list fails it.
      //
      // Asked as "where does an ending session land in this mode", not as "is
      // this remote". That is the cause: [SessionOutcome] is cause 3's own
      // vocabulary, and this dialog's two other mode-dependent behaviours (does
      // the trigger need recovery, how often to probe) are already reached the
      // same way.
      if (ref.read(appModeProfileProvider).session.destination ==
          SessionOutcome.loginPage)
        AppButton.text(
          label: loc(context).returnToLoginPage,
          onTap: () {
            logger.d('[Recovery] User tapped Return to login');
            ref.read(appConnectionStateProvider.notifier).exitToLogout();
          },
        )
      else
        // #1323's own wording: "In RA, label the exit affordance *End session*".
        // `loc(context).endSession` already exists in all 26 locales and is what
        // the session chip and the RA banner label the same action, so the
        // support engineer sees one verb for one thing.
        //
        // Goes straight to `logout()` rather than through `exitToLogout()`, which
        // would be the tidier-looking reuse: `exitToLogout()` also drives
        // `AppConnectionState` to `loggedOut`, and its `logout()` is bare — the
        // default `sessionLost`, which would skip `endSessionForCA` on the one
        // path where the operator explicitly asked to end the session. Navigation
        // is the route redirect's job either way: cause 3 clears the RA session,
        // and the `/usp*` guard answers a session-less remote build with the
        // confirm page's session-ended surface.
        AppButton.text(
          label: loc(context).endSession,
          onTap: () {
            logger.d('[Recovery] Support engineer tapped End session');
            ref
                .read(authProvider.notifier)
                .logout(cause: EndCause.userRequested);
          },
        ),
    ],
  );
  logger.d('[Recovery] Recovery dialog dismissed');

  sub.close();

  if (!context.mounted) return;

  if (ref.read(appConnectionStateProvider) ==
      AppConnectionState.authenticated) {
    logger.d('[Recovery] Recovery successful');
    if (successMessage != null) {
      showSuccessSnackBar(context, successMessage);
    }
  }
}
