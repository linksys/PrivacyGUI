import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

/// The router's own reboot and factory reset, confirmed and then waited out.
///
/// One flow for every place that offers them: the Administration page and the
/// router's node detail page (#876). Both are `Device.Reboot()` /
/// `Device.FactoryReset()`, which on FL-WRT 2.0 take every mesh child down
/// first (FWDEV#202), so with nodes attached the confirmation says the whole
/// mesh goes, and on a single router it says what it always said. A second
/// copy of the flow could only drift from this one.
///
/// [UspAdminNotifier] holds the operation guard, so Remote Assistance refuses
/// the factory reset here as it does on the Administration page.
///
/// The notifier is autoDispose and the node detail page does not watch it, so
/// the flow keeps it alive itself until the call has returned.
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
  final keepAlive = ref.listenManual(uspAdminProvider, (_, __) {});
  try {
    await doSomethingWithSpinner(
      context,
      ref.read(uspAdminProvider.notifier).reboot(),
    );
    if (!context.mounted) return;

    await showRecoveryDialog(
      context,
      ref,
      trigger: RecoveryTrigger.operationalReboot,
      cooldown: const Duration(seconds: 60),
      title: loc(context).routerIsRebooting,
      message: loc(context).rebootWaitMessage,
      successMessage: loc(context).routerRebootComplete,
    );
  } catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));
    }
  } finally {
    keepAlive.close();
  }
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
  final keepAlive = ref.listenManual(uspAdminProvider, (_, __) {});
  try {
    await doSomethingWithSpinner(
      context,
      ref.read(uspAdminProvider.notifier).factoryReset(),
    );
    if (!context.mounted) return;

    await showRecoveryDialog(
      context,
      ref,
      trigger: RecoveryTrigger.operationalFactoryReset,
      cooldown: const Duration(seconds: 90),
      healthOnly: true,
      title: loc(context).factoryResetInProgress,
      message: loc(context).factoryResetWaitMessage,
    );
  } catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));
    }
  } finally {
    keepAlive.close();
  }
}

/// Whether the router has mesh nodes the call takes down with it. Not known
/// until the devices are read, and then the single-router copy is the one
/// shown: it is the copy this flow had before FWDEV#202, and it is true of the
/// router itself either way.
bool _hasMesh(WidgetRef ref) =>
    ref.read(devicesDataProvider).valueOrNull?.meshNetwork.hasMesh ?? false;
