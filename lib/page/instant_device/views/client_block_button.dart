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
import 'package:privacy_gui/page/instant_device/providers/client_block_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class ClientBlockButton extends ConsumerStatefulWidget {
  const ClientBlockButton({super.key, required this.device});
  final DeviceListItem device;

  @override
  ConsumerState<ClientBlockButton> createState() => _ClientBlockButtonState();
}

class _ClientBlockButtonState extends ConsumerState<ClientBlockButton> {
  @override
  Widget build(BuildContext context) {
    if (!widget.device.isOnlineWireless || widget.device.macAddress.isEmpty) {
      return const SizedBox.shrink();
    }
    return WriteGuard(
      child: AppTextButton.noPadding(
        loc(context).blockClient,
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
    final result = await showSubmitAppDialog<ClientBlockOutcome>(
      context,
      title: '${loc(context).blockClient}: ${device.name}',
      positiveLabel: loc(context).blockClient,
      checkPositiveEnabled: () => container.read(accessPolicyProvider).canWrite,
      contentBuilder: (context, _, __) => AppText.bodyMedium(
        serviceHelper.isSupportClientDeauth()
            ? loc(context).blockClientDescription
            : loc(context).blockClientPolicyOnlyDescription,
      ),
      event: () => container.read(clientBlockProvider).block(device.deviceId),
      onError: (error, _) {
        if (!actionContext.mounted || error is ReadOnlyAccessException) return;
        if (error is ClientBlockException) {
          snackbar.showFailedSnackBar(
              actionContext,
              switch (error.failure) {
                ClientBlockFailure.protectedDevice =>
                  strings.blockClientProtected,
                ClientBlockFailure.capacity => strings.blockClientCapacity,
                _ => strings.blockClientUnavailable,
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
      ClientBlockOutcome.disconnectRequested => strings.blockClientSaved,
      ClientBlockOutcome.policyOnly => strings.blockClientPolicyOnlySaved,
      ClientBlockOutcome.disconnectFailed =>
        strings.blockClientDisconnectFailed,
      ClientBlockOutcome.unverified => strings.blockClientUnverified,
    };
    if (result == ClientBlockOutcome.disconnectFailed ||
        result == ClientBlockOutcome.unverified) {
      snackbar.showFailedSnackBar(actionContext, message);
    } else {
      snackbar.showSuccessSnackBar(actionContext, message);
    }
  }
}
