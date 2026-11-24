import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/page/admin/models/network_action_models.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

/// The router's own reboot and factory reset, confirmed and then waited out.
///
/// One flow for every place that offers them: the Administration page, the
/// router's node detail page and the topology's node menu (#876). Both act on
/// the whole network: `X_LINKSYS_RebootAll()` / `X_LINKSYS_FactoryResetAll()`
/// where the router has them (Architecture#195, #1777), and
/// `Device.Reboot()` / `Device.FactoryReset()` where it does not, on firmware
/// that still takes the mesh nodes down with the router and on a unit with the
/// mesh off. So with nodes attached the confirmation says the whole mesh goes,
/// and on a single router it says what it always said. A second copy of the
/// flow could only drift from this one.
///
/// [UspAdminNotifier] holds the operation guard, so Remote Assistance refuses
/// the factory reset here as it does on the Administration page.
///
/// The notifier is autoDispose and the node detail page does not watch it, so
/// the flow keeps it alive itself until the wait is over.
Future<void> confirmAndRebootRouter(BuildContext context, WidgetRef ref) async {
  final mesh = _hasMesh(ref);
  final confirmed = await showConfirmActionDialog(
    context,
    title: mesh ? loc(context).rebootParentTitle : loc(context).rebootRouter,
    message: mesh
        ? loc(context).rebootMeshMessage
        : loc(context).rebootRouterMessage,
    confirmLabel: loc(context).restart,
  );
  if (confirmed != true || !context.mounted) return;
  await _runRestart(
    context,
    ref,
    send: () => ref.read(uspAdminProvider.notifier).reboot(),
    wait: _RestartWait(
      trigger: RecoveryTrigger.operationalReboot,
      cooldown: const Duration(seconds: 60),
      healthOnly: false,
      title: loc(context).routerIsRebooting,
      message: loc(context).rebootWaitMessage,
      successMessage: loc(context).routerRebootComplete,
    ),
  );
}

/// See [confirmAndRebootRouter].
Future<void> confirmAndFactoryResetRouter(
    BuildContext context, WidgetRef ref) async {
  final mesh = _hasMesh(ref);
  final confirmed = await showConfirmActionDialog(
    context,
    title: mesh
        ? loc(context).factoryResetParentTitle
        : loc(context).resetToFactoryDefault,
    message: mesh
        ? loc(context).factoryResetMeshMessage
        : loc(context).factoryResetDesc,
    confirmLabel: loc(context).reset,
  );
  if (confirmed != true || !context.mounted) return;
  await _runRestart(
    context,
    ref,
    send: () => ref.read(uspAdminProvider.notifier).factoryReset(),
    wait: _RestartWait(
      trigger: RecoveryTrigger.operationalFactoryReset,
      cooldown: const Duration(seconds: 90),
      // The reset wipes the credential the session was opened with.
      healthOnly: true,
      title: loc(context).factoryResetInProgress,
      message: loc(context).factoryResetWaitMessage,
    ),
  );
}

/// What the wait for the router differs by between a reboot and a reset.
class _RestartWait {
  final RecoveryTrigger trigger;

  /// From the moment the router goes down until the probe starts.
  final Duration cooldown;

  /// The action wipes the credential the session was opened with: the probe
  /// checks only that the router answers, and the session does not outlive it.
  final bool healthOnly;
  final String title;
  final String message;
  final String? successMessage;

  const _RestartWait({
    required this.trigger,
    required this.cooldown,
    required this.healthOnly,
    required this.title,
    required this.message,
    this.successMessage,
  });
}

Future<void> _runRestart(
  BuildContext context,
  WidgetRef ref, {
  required Future<RouterRestartStart> Function() send,
  required _RestartWait wait,
}) async {
  final keepAlive = ref.listenManual(uspAdminProvider, (_, __) {});
  try {
    final start = await doSomethingWithSpinner(context, send());
    if (start == null || !context.mounted) return;
    switch (start) {
      case RouterRestartStart.router:
        // It goes down soon after it replies, so the countdown starts here.
        await showRecoveryDialog(
          context,
          ref,
          trigger: wait.trigger,
          cooldown: wait.cooldown,
          healthOnly: wait.healthOnly,
          title: wait.title,
          message: wait.message,
          successMessage: wait.successMessage,
        );
      case RouterRestartStart.network:
        await _waitOutNetworkAction(context, ref, wait);
      case RouterRestartStart.alreadyRunning:
        // Started from somewhere else — another browser, or the other side of
        // a Remote Assistance session. The connection drops when it gets to
        // the controller, and the app's own recovery covers that.
        showSimpleSnackBar(context, loc(context).networkRestartAlreadyRunning);
    }
  } catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));
    }
  } finally {
    keepAlive.close();
  }
}

/// Waits out a whole-network reboot or reset: the controller goes down last,
/// after every agent, so the countdown starts when its turn comes rather than
/// at the reply.
///
/// Recovery is entered at once, with the cooldown as a ceiling, so the app is
/// already waiting when an agent — maybe the one this browser reaches the
/// router through — goes down, and the shell puts up no "Connection lost" of
/// its own. The status is read meanwhile, and the ceiling is replaced once it
/// settles: by the usual countdown when the controller is going down, or when
/// the status can no longer be read. When it failed, the controller is still
/// up, and the app leaves recovery with the session as it was — not through
/// the probe, which after a factory reset reads a router that answers as one
/// that was reset and ends the session. A reboot not settled by the limit
/// leaves the same way. Otherwise the ceiling is the time limit the probe
/// falls back to.
Future<void> _waitOutNetworkAction(
    BuildContext context, WidgetRef ref, _RestartWait wait) async {
  final connection = ref.read(appConnectionStateProvider.notifier);
  final waiting = connection.enterWaiting(
    context: RecoveryContext(
      trigger: wait.trigger,
      cooldown: UspAdminNotifier.networkActionLimit + wait.cooldown,
      healthOnly: wait.healthOnly,
    ),
  );
  if (!waiting) {
    // This mode's path to the router does not go down; see
    // `showRecoveryDialog`, which answers the same way.
    if (wait.successMessage != null) {
      showSuccessSnackBar(context, wait.successMessage!);
    }
    return;
  }

  final dialog = showRecoveryDialog(
    context,
    ref,
    trigger: wait.trigger,
    skipEnterWaiting: true,
    title: wait.title,
    message: wait.message,
  );
  final outcome =
      await ref.read(uspAdminProvider.notifier).awaitNetworkAction();
  switch (outcome) {
    case NetworkActionOutcome.controllerGoingDown:
    case NetworkActionOutcome.unreachable:
      connection.restartCooldown(wait.cooldown);
    case NetworkActionOutcome.failed:
      connection.leaveWaiting();
    case NetworkActionOutcome.timedOut:
      // Not settled is not "will not go down". A reboot can leave recovery:
      // if the controller restarts later, the natural recovery brings the same
      // session back. A reset cannot — the natural recovery would then retry a
      // credential the reset wiped, for good — so it stays waiting and the
      // ceiling's health-only probe ends it.
      if (!wait.healthOnly) connection.leaveWaiting();
    case NetworkActionOutcome.abandoned:
      break;
  }
  await dialog;

  if (!context.mounted ||
      ref.read(appConnectionStateProvider) !=
          AppConnectionState.authenticated) {
    return;
  }
  switch (outcome) {
    case NetworkActionOutcome.failed:
      showFailedSnackBar(context, loc(context).errorCommandRefused);
    case NetworkActionOutcome.controllerGoingDown:
    case NetworkActionOutcome.unreachable:
      if (wait.successMessage != null) {
        showSuccessSnackBar(context, wait.successMessage!);
      }
    // Nothing was seen to restart, so nothing is claimed.
    case NetworkActionOutcome.timedOut:
    case NetworkActionOutcome.abandoned:
      break;
  }
}

/// Whether the call may take mesh nodes down with the router. Only a router
/// read as having none gets the single-router copy. Until the devices are
/// read (the Administration page offers its buttons without them) the answer
/// is yes: on a destructive action the copy may overstate what goes down,
/// not understate it.
bool _hasMesh(WidgetRef ref) =>
    ref.read(devicesDataProvider).valueOrNull?.meshNetwork.hasMesh ?? true;
