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

class ClientRemovalButton extends ConsumerStatefulWidget {
  const ClientRemovalButton({super.key, required this.device});
  final DeviceListItem device;

  @override
  ConsumerState<ClientRemovalButton> createState() =>
      _ClientRemovalButtonState();
}

class _ClientRemovalButtonState extends ConsumerState<ClientRemovalButton> {
  @override
  Widget build(BuildContext context) {
    if (!widget.device.isOnlineWireless || widget.device.macAddress.isEmpty) {
      return const SizedBox.shrink();
    }
    return WriteGuard(
      child: AppTextButton.noPadding(
        loc(context).removeClient,
        color: Theme.of(context).colorScheme.error,
        onTap: _confirm,
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
}
