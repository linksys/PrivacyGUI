import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart'
    as snackbar;
import 'package:privacy_gui/page/components/widgets/write_guard.dart';
import 'package:privacy_gui/page/instant_device/providers/client_removal_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class ClientActionMenu extends ConsumerStatefulWidget {
  const ClientActionMenu(
      {super.key, required this.device, this.restricted = false});
  final DeviceListItem device;
  final bool restricted;

  @override
  ConsumerState<ClientActionMenu> createState() => _ClientActionMenuState();
}

class _ClientActionMenuState extends ConsumerState<ClientActionMenu> {
  @override
  Widget build(BuildContext context) {
    if ((!widget.restricted && !widget.device.isOnlineWireless) ||
        widget.device.macAddress.isEmpty) {
      return const SizedBox.shrink();
    }
    return WriteGuard(
      child: PopupMenuButton<String>(
        tooltip: loc(context).clientDeviceActions,
        icon: const Icon(Icons.more_horiz),
        itemBuilder: (context) => [
          if (widget.restricted)
            PopupMenuItem(
                value: 'restore', child: Text(loc(context).restoreClientAccess))
          else ...[
            PopupMenuItem(
                value: 'remove', child: Text(loc(context).removeClient)),
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc(context).blockClientTraffic),
                  Text(loc(context).blockClientTrafficUnavailable,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
        onSelected: (action) {
          if (action == 'remove') _confirm();
          if (action == 'restore') _confirmRestore();
        },
      ),
    );
  }

  Future<void> _confirm() async {
    final device = widget.device;
    // Polling can remove this row while its dialog is still open.
    final actionContext = Navigator.of(context, rootNavigator: true).context;
    final strings = loc(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await showSubmitAppDialog<ClientRemovalOutcome>(
      context,
      title: '${loc(context).removeClient}: ${device.name}',
      positiveLabel: loc(context).removeClient,
      checkPositiveEnabled: () => container.read(accessPolicyProvider).canWrite,
      contentBuilder: (context, _, __) => AppText.bodyMedium(
        serviceHelper.isSupportClientDeauth()
            ? loc(context).removeClientDescription
            : loc(context).removeClientPolicyOnlyDescription,
      ),
      event: () =>
          container.read(clientRemovalProvider).remove(device.deviceId),
      onError: (error, _) {
        if (!actionContext.mounted || error is ReadOnlyAccessException) return;
        if (error is ClientRemovalException) {
          snackbar.showFailedSnackBar(
              actionContext,
              switch (error.failure) {
                ClientRemovalFailure.protectedDevice =>
                  strings.removeClientProtected,
                ClientRemovalFailure.capacity => strings.removeClientCapacity,
                _ => strings.removeClientUnavailable,
              });
        } else {
          snackbar.showFailedSnackBar(
              actionContext,
              switch (error) {
                JNAPError() => errorCodeHelper(actionContext, error.result) ??
                    strings.unknownErrorCode(error.result),
                TimeoutException() => strings.generalError,
                _ => strings.unknownError,
              });
        }
      },
    );
    if (!actionContext.mounted || result == null) return;
    final message = switch (result) {
      ClientRemovalOutcome.disconnectRequested => strings.removeClientSaved,
      ClientRemovalOutcome.policyOnly => strings.removeClientPolicyOnlySaved,
      ClientRemovalOutcome.disconnectFailed =>
        strings.removeClientDisconnectFailed,
      ClientRemovalOutcome.unverified => strings.removeClientUnverified,
    };
    if (result == ClientRemovalOutcome.disconnectFailed ||
        result == ClientRemovalOutcome.unverified) {
      snackbar.showFailedSnackBar(actionContext, message);
    } else {
      snackbar.showSuccessSnackBar(actionContext, message);
    }
  }

  Future<void> _confirmRestore() async {
    final actionContext = Navigator.of(context, rootNavigator: true).context;
    final strings = loc(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final mac = widget.device.macAddress;
    final result = await showSubmitAppDialog<bool>(
      context,
      title: '${strings.restoreClientAccess}: ${widget.device.name}',
      positiveLabel: strings.restoreClientAccess,
      checkPositiveEnabled: () => container.read(accessPolicyProvider).canWrite,
      contentBuilder: (_, __, ___) =>
          Text(strings.restoreClientAccessDescription),
      event: () => container.read(clientRemovalProvider).restore(mac),
      onError: (error, _) {
        if (!actionContext.mounted || error is ReadOnlyAccessException) return;
        snackbar.showFailedSnackBar(
            actionContext,
            error is ClientRemovalException &&
                    error.failure == ClientRemovalFailure.capacity
                ? strings.restoreClientAccessCapacity
                : strings.restoreClientAccessFailed);
      },
    );
    if (!actionContext.mounted || result == null) return;
    if (result) {
      snackbar.showSuccessSnackBar(
          actionContext, strings.restoreClientAccessSaved);
    } else {
      snackbar.showFailedSnackBar(
          actionContext, strings.restoreClientAccessFailed);
    }
  }
}
