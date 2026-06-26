import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firmware_update.dart';

class _TestableRecoveryDialog extends ConsumerWidget {
  const _TestableRecoveryDialog();

  static const _baseline = Duration(minutes: 4);

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(appConnectionStateProvider.notifier);
    final consecutive = notifier.consecutiveFailures;
    final lastResult = notifier.lastProbeResult;

    const kFirmwareWifiSwitchWarningAfter = Duration(seconds: 90);
    final wifiSwitchWarning =
        consecutive * 10 >= kFirmwareWifiSwitchWarningAfter.inSeconds;

    final countdownText =
        'Estimated time remaining: ${_formatRemaining(_baseline)}';

    final probeIndicator = switch (lastResult) {
      ProbeResult.recovered => 'Connection restored',
      ProbeResult.unreachable =>
        'Last check: router not yet responding (attempt $consecutive)',
      ProbeResult.serialMismatch => 'Router identity mismatch',
      null => 'Waiting for first connection check',
    };

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: AppDialog(
          title: SizedBox(
            width: 360,
            child: AppText.titleLarge('Router is rebooting'),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AppLoader()),
                AppGap.lg(),
                AppText.bodyMedium(countdownText),
                AppGap.sm(),
                AppText.bodySmall(probeIndicator),
                if (wifiSwitchWarning) ...[
                  AppGap.lg(),
                  AppText.bodyMedium(
                    'No response from your router. Please confirm your '
                    'computer is still connected to the router\'s Wi-Fi, then '
                    'tap Retry now.',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            AppButton.text(
              label: 'Return to login page',
              onTap: () {},
            ),
            AppButton.primary(
              label: 'Retry now',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'firmware_recovery_dialog',
      view: () => const _TestableRecoveryDialog(),
      shell: ShellType.custom,
      states: {
        'waiting_initial': (overrides) => overrides.addAll(
              recoveryDialogOverrides(
                consecutiveFailures: 0,
                lastProbeResult: null,
              ),
            ),
        'waiting_unreachable': (overrides) => overrides.addAll(
              recoveryDialogOverrides(
                consecutiveFailures: 3,
                lastProbeResult: ProbeResult.unreachable,
              ),
            ),
        'wifi_warning': (overrides) => overrides.addAll(
              recoveryDialogOverrides(
                consecutiveFailures: 10,
                lastProbeResult: ProbeResult.unreachable,
              ),
            ),
        'serial_mismatch': (overrides) => overrides.addAll(
              recoveryDialogOverrides(
                consecutiveFailures: 1,
                lastProbeResult: ProbeResult.serialMismatch,
              ),
            ),
      },
    ),
  );
}
