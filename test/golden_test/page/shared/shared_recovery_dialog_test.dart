import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';

import '../../golden_framework/golden_runner.dart';
import '../../golden_framework/golden_test_config.dart';
import '../../golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_framework/overlay_host.dart';

/// `showRecoveryDialog`, the spinner dialog every router-restarting mutation
/// waits behind, opened through its real signature (#905).
///
/// One interaction per caller, with that caller's own arguments copied as they
/// are written, so each golden is the dialog its user sees.
///
/// The Remote Assistance variant is on the reboot, not on the Wi-Fi change.
/// `RemoteProximityStrategy` plans no recovery for a Wi-Fi change (the Guardian
/// path runs over the WAN uplink), so in that mode the dialog never opens and
/// the agent sees only the success snackbar. Reboot is a disruption in both
/// modes, and what changes there is the exit action: End Session instead of
/// Return to login page. The surface's own message (`recoveryMessages()`) would
/// differ too, but only the Wi-Fi caller leaves `message` unset, so no user in
/// Remote Assistance ever sees it.
///
/// The connection state is pinned to `waitingForRecovery`, so the dialog stays
/// up: it closes only on a transition into `authenticated`, which never comes.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'shared_recovery_dialog',
      view: () => const OverlayHost(),
      shell: ShellType.custom,
      states: const {},
      interactions: {
        // `UspAdminView` after a reboot.
        'reboot': _open(
          (host) => showRecoveryDialog(
            host.context,
            host.ref,
            trigger: RecoveryTrigger.operationalReboot,
            cooldown: const Duration(seconds: 60),
            title: loc(host.context).routerIsRebooting,
            message: loc(host.context).rebootWaitMessage,
            successMessage: loc(host.context).routerRebootComplete,
          ),
        ),
        'reboot_remote_assistance': _open(
          (host) => showRecoveryDialog(
            host.context,
            host.ref,
            trigger: RecoveryTrigger.operationalReboot,
            cooldown: const Duration(seconds: 60),
            title: loc(host.context).routerIsRebooting,
            message: loc(host.context).rebootWaitMessage,
            successMessage: loc(host.context).routerRebootComplete,
          ),
          remote: true,
        ),
        // `UspAdminView` after a factory reset.
        'factory_reset': _open(
          (host) => showRecoveryDialog(
            host.context,
            host.ref,
            trigger: RecoveryTrigger.operationalFactoryReset,
            cooldown: const Duration(seconds: 90),
            healthOnly: true,
            title: loc(host.context).factoryResetInProgress,
            message: loc(host.context).factoryResetWaitMessage,
          ),
        ),
        // `wifiWriteWithRecovery` (`wifi_write_with_recovery.dart`) around a
        // Wi-Fi save. No title or message of its own, so this is the helper's
        // default title and the surface's message. The caller has entered the
        // waiting state itself, and holds the dialog open until the save has
        // settled; `holdUntil` is a future that never completes, which keeps the
        // dialog up for the capture the same way the pinned state does.
        'wifi_change': _open(
          (host) => showRecoveryDialog(
            host.context,
            host.ref,
            trigger: RecoveryTrigger.operationalWifiChange,
            skipEnterWaiting: true,
            holdUntil: Completer<void>().future,
          ),
        ),
        // `UspDashboardShell` when the SSE stream drops on its own. The
        // message is an English literal at that call site and is copied as-is,
        // so this golden reads English in every locale, as the app does.
        'connection_lost': _open(
          (host) => showRecoveryDialog(
            host.context,
            host.ref,
            trigger: RecoveryTrigger.natural,
            cooldown: Duration.zero,
            skipEnterWaiting: true,
            title: loc(host.context).connectionLost,
            message: 'Lost connection to the router. '
                'Attempting to reconnect automatically...',
            successMessage: loc(host.context).reconnectedToRouter,
          ),
        ),
      },
    ),
  );
}

/// An interaction that opens the dialog [show] opens, with the connection
/// pinned to `waitingForRecovery`. [remote] selects the Remote Assistance
/// surface the way the app does, through the mode profile.
Interaction _open(
  Future<void> Function(({BuildContext context, WidgetRef ref}) host) show, {
  bool remote = false,
}) =>
    Interaction(
      setup: (overrides) => overrides.addAll([
        ...recoveryDialogOverrides(),
        if (remote)
          appModeProfileProvider.overrideWithValue(const RemoteModeProfile()),
      ]),
      steps: (tester) async {
        show(overlayHostOf(tester));
        await pumpOverlayIn(tester);
      },
    );
