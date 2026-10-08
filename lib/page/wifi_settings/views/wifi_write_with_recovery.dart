import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';

/// How a Wi-Fi write ended, when it did not throw.
sealed class WifiWriteDone {
  const WifiWriteDone();
}

/// The router confirmed the write — answered, or read back.
final class WifiWriteConfirmed extends WifiWriteDone {
  const WifiWriteConfirmed();
}

/// The write went out but the router could not be read back in time — a
/// rename, with the browser rejoining the new network. [confirm] reads it back
/// once the router is back, and throws if it did not apply.
final class WifiWriteAwaitsRouter extends WifiWriteDone {
  final Future<void> Function() confirm;
  const WifiWriteAwaitsRouter(this.confirm);
}

/// Runs one Wi-Fi write under one recovery, and reports its outcome.
///
/// Every Wi-Fi write reloads all the radios, so the app enters recovery before
/// [write] sends anything and shows the one recovery dialog for it. The app is
/// then already waiting when the reload drops the event stream, so the shell —
/// which only enters its natural recovery from `authenticated` — puts up
/// nothing of its own, and the dashboard's polling pauses instead of timing
/// out against a reloading router. Before this a save showed "Processing",
/// then the shell's "Connection lost" mid-save, then a second recovery of its
/// own; the dashboard's toggle and channel writes entered none at all (bench
/// 2026-10-07).
///
/// The probe is held off while the write is in flight. FW 2.0.2 keeps
/// answering for the first ~38 s of the reload, so a probe then would end the
/// recovery before anything had restarted; this starts it once [write] has
/// settled, whatever the outcome. The dialog stays up until the outcome is
/// known — through a [WifiWriteAwaitsRouter] read-back too — so the page is
/// never shown before it is right.
///
/// Remote Assistance enters no recovery for a Wi-Fi change (#1323 — the
/// agent's path never breaks), so there a spinner covers the write, and a
/// router-away write waits through the natural recovery for the router to
/// rejoin the cloud.
Future<void> runWifiWriteWithRecovery(
  BuildContext context,
  WidgetRef ref, {
  required Future<WifiWriteDone> Function() write,
  required String successMessage,
}) async {
  final connection = ref.read(appConnectionStateProvider.notifier);
  final recovering = connection.enterWaiting(
    context: const RecoveryContext(
      trigger: RecoveryTrigger.operationalWifiChange,
      // Held off until the write settles — see `startProbingNow` below. Long
      // enough to outlast any write (`wifiSaveHardLimitProvider`).
      cooldown: Duration(minutes: 3),
    ),
  );
  // Settled once the outcome is known. The dialog stays up until then, not
  // only until the router is back: closing at recovery showed the pre-save
  // form for the ~11 s a read-back took (bench 2026-10-07).
  final settled = Completer<void>();
  if (recovering) {
    // Not awaited: it closes itself when the recovery ends and [settled].
    unawaited(showRecoveryDialog(
      context,
      ref,
      trigger: RecoveryTrigger.operationalWifiChange,
      skipEnterWaiting: true,
      holdUntil: settled.future,
    ));
  }

  Object? failure;
  WifiWriteDone? done;
  try {
    logger.d('[WiFi][Write] Starting (recovery: $recovering)...');
    done =
        await (recovering ? write() : doSomethingWithSpinner(context, write()));
    logger.d('[WiFi][Write] Settled: ${done.runtimeType}');
  } catch (e) {
    logger.d('[WiFi][Write] Error: $e');
    failure = e;
  }

  final awaitsRouter = done is WifiWriteAwaitsRouter ? done : null;
  if (recovering) {
    connection.startProbingNow();
  } else if (awaitsRouter != null) {
    // Remote Assistance: the router still has to rejoin the cloud before it
    // can be read. The natural recovery is the wait both modes run.
    connection.enterWaiting(context: RecoveryContext.natural);
  }
  try {
    if (recovering || awaitsRouter != null) {
      if (!await awaitRecovery(ref)) return; // signed out: nothing to report
    }
    if (awaitsRouter != null) {
      try {
        await awaitsRouter.confirm();
      } catch (e) {
        failure = e;
      }
    }
  } finally {
    settled.complete();
  }
  if (!context.mounted) return;
  if (failure != null) {
    showFailedSnackBar(context, localizeServiceError(context, failure));
  } else {
    showSuccessSnackBar(context, successMessage);
  }
}
