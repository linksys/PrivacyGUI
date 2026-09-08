import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';

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
  final surface = ref.read(surfaceStrategyProvider);
  await showAppSpinnerDialog(
    context,
    title: title ?? 'Router is applying changes',
    // The caller's message when it has one; otherwise whatever this surface has
    // to say about a router that is away. Local's line is the "reconnect to your
    // router's network if needed" hint — advice an RA agent's browser cannot act
    // on, since it is nowhere near the Wi-Fi that is restarting — so the remote
    // surface contributes an empty list rather than a reworded one (acceptance
    // 5b of #1497).
    messages: message != null ? [message] : surface.recoveryMessages(),
    actions: [
      // Acceptances 1 and 2 of #1323, now composed rather than branched (#1497):
      // the bail-out affordance is *relabelled and rewired* per mode, not
      // removed. `exitToLogout()` clears the credential and lets the route
      // redirect take the app to the login page — correct locally, and in Remote
      // Assistance an offer to go somewhere that is not reachable: the credential
      // was a one-shot Guardian token, so there is no password to type and no way
      // back in. Worse, the button reads as the *escape hatch* from a recovery
      // wait, so a support engineer presses it and is left on a dead login form
      // with the Guardian session still running.
      //
      // NEITHER SURFACE MAY RETURN NULL HERE, and the first cut of #1323 shipped
      // a gate with no `else`, which is the same defect one shape earlier. This is
      // the whole `actions:` list, `showAppSpinnerDialog` passes
      // `barrierDismissible: false`, and the only `pop` is the `listenManual`
      // above, which fires on a transition *into* `authenticated` — deliberately
      // not on `loggedOut`. So an empty action list renders a modal with no
      // affordance and no barrier, escapable only by the router coming back. In RA
      // that is reachable on three triggers `RemoteProximityStrategy.planFor`
      // still answers `needsRecovery: true` for — `natural`, `operationalReboot`
      // and `operationalFactoryReset` — and a Guardian-side reboot takes the agent
      // down with the box, which is exactly when it will not come back quickly.
      // That is acceptance 6, and `SurfaceStrategy.sessionExitAction()` returns a
      // non-nullable `Widget` so it cannot be failed by omission.
      surface.sessionExitAction(),
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
