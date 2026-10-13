import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firmware_update.dart';
import '../../../golden_framework/overlay_host.dart';

/// The dialog a firmware upgrade waits behind while the router reboots, opened
/// through `showFirmwareUpdateRecoveryDialog` itself (#905).
///
/// This file used to render a hand-written copy of the dialog, because the real
/// one is a private widget reachable only through a function that takes a
/// `WidgetRef`. The copy hard-coded its English strings, so every locale's
/// golden read English, and it had stopped tracking the real dialog: no
/// `sessionExitAction()`, no "Checking…" state, no "still waiting" copy.
/// [OverlayHost] supplies the `ref`, so the copy is gone.
///
/// What each probe state shows comes from the pinned connection notifier. The
/// countdown is the dialog's own 1-second ticker against `baseline`, read from
/// `clock.now()`, so it follows the test's fake time and not the machine's: the
/// runner advances less than a second before the capture, which reads the full
/// default baseline, and would read exactly one second less if it ever advanced
/// further. `baseline: Duration.zero` is the elapsed case.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'firmware_recovery_dialog',
      view: () => const OverlayHost(),
      shell: ShellType.custom,
      states: const {},
      interactions: {
        'waiting_initial': _open(
          recoveryDialogOverrides(
            consecutiveFailures: 0,
            lastProbeResult: null,
          ),
        ),
        'waiting_unreachable': _open(
          recoveryDialogOverrides(
            consecutiveFailures: 3,
            lastProbeResult: ProbeResult.unreachable,
          ),
        ),
        // Ten failed 10-second probes is the 90-second threshold
        // (`kFirmwareWifiSwitchWarningAfter`) at which the Wi-Fi warning appears.
        'wifi_warning': _open(
          recoveryDialogOverrides(
            consecutiveFailures: 10,
            lastProbeResult: ProbeResult.unreachable,
          ),
        ),
        'serial_mismatch': _open(
          recoveryDialogOverrides(
            consecutiveFailures: 1,
            lastProbeResult: ProbeResult.serialMismatch,
          ),
        ),
        // The countdown has run out and the router is still away.
        'still_waiting': _open(
          recoveryDialogOverrides(
            consecutiveFailures: 3,
            lastProbeResult: ProbeResult.unreachable,
          ),
          baseline: Duration.zero,
        ),
        // The user tapped Retry now and the probe has not answered yet.
        'retrying': _open(
          recoveryDialogOverrides(
            consecutiveFailures: 3,
            lastProbeResult: ProbeResult.unreachable,
            retryNeverCompletes: true,
          ),
          then: (tester) async {
            // By the button's E2E identifier, not its position among the
            // dialog's actions, so a reordered action list still taps Retry.
            await tester
                .tap(find.bySemanticsIdentifier('firmware-recovery-retry'));
            await tester.pump();
          },
        ),
        // Remote Assistance: the exit action ends the Guardian session instead
        // of offering a login page the one-shot token cannot get back into.
        'remote_assistance': _open(
          [
            ...recoveryDialogOverrides(
              consecutiveFailures: 3,
              lastProbeResult: ProbeResult.unreachable,
            ),
            appModeProfileProvider.overrideWithValue(const RemoteModeProfile()),
          ],
        ),
      },
    ),
  );
}

Interaction _open(
  List<Override> overrides, {
  Duration baseline = kFirmwareRebootBaseline,
  Future<void> Function(WidgetTester tester)? then,
}) =>
    Interaction(
      setup: (list) => list.addAll(overrides),
      steps: (tester) async {
        final host = overlayHostOf(tester);
        showFirmwareUpdateRecoveryDialog(
          host.context,
          host.ref,
          baseline: baseline,
        );
        await pumpOverlayIn(tester);
        await then?.call(tester);
      },
    );
