import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Default reboot baseline observed on dev routers (1.0.16): full SSE
/// blackout is ~3-4 minutes from `Reboot()` to first health probe success.
const Duration kFirmwareRebootBaseline = Duration(minutes: 4);

/// Sustained-unreachable threshold after which the dialog flips to the
/// "please confirm WiFi" warning copy. Picked so that a single hiccup
/// (one or two probe round-trips) does not flash the warning unnecessarily.
const Duration kFirmwareWifiSwitchWarningAfter = Duration(seconds: 90);

/// Returns once the dialog is dismissed.
///
/// The dialog shows a countdown anchored at [baseline] and transitions to a
/// warning copy after the user has had ~[kFirmwareWifiSwitchWarningAfter]
/// of sustained probe failures — that case is most often the local device
/// hopping onto a different SSID while the router is rebooting, so a
/// manual "Retry now" affordance is essential.
///
/// The caller is responsible for entering [AppConnectionState.waitingForRecovery]
/// (via [AppConnectionStateNotifier.enterWaiting]) before invoking this
/// helper, and for reading the resulting state afterwards.
Future<void> showFirmwareUpdateRecoveryDialog(
  BuildContext context,
  WidgetRef ref, {
  Duration baseline = kFirmwareRebootBaseline,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);

  final sub = ref.listenManual(appConnectionStateProvider, (prev, next) {
    if (next == AppConnectionState.authenticated) {
      logger.d('[FirmwareUpdate] recovery: recovered, popping dialog');
      navigator.pop();
    }
    // loggedOut: route redirect tears down the page stack; do not pop.
  });

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FirmwareRecoveryDialog(baseline: baseline),
  );

  sub.close();
}

class _FirmwareRecoveryDialog extends ConsumerStatefulWidget {
  const _FirmwareRecoveryDialog({required this.baseline});

  final Duration baseline;

  @override
  ConsumerState<_FirmwareRecoveryDialog> createState() =>
      _FirmwareRecoveryDialogState();
}

class _FirmwareRecoveryDialogState
    extends ConsumerState<_FirmwareRecoveryDialog> {
  Timer? _ticker;
  late DateTime _start;
  late Duration _elapsed;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_start);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final left = widget.baseline - _elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(appConnectionStateProvider.notifier);
    final consecutive = notifier.consecutiveFailures;
    final lastResult = notifier.lastProbeResult;

    // Probe loop ticks every 10s, so consecutive failures × 10s approximates
    // how long the router has been silent in the current waiting session.
    final wifiSwitchWarning =
        consecutive * 10 >= kFirmwareWifiSwitchWarningAfter.inSeconds;

    final remaining = _remaining;
    final countdownText = remaining > Duration.zero
        ? loc(context).estimatedTimeRemaining(_formatRemaining(remaining))
        : loc(context).stillWaitingLongerThanExpected;

    final probeIndicator = switch (lastResult) {
      ProbeResult.recovered => loc(context).connectionRestored,
      ProbeResult.unreachable =>
        loc(context).routerNotYetResponding(consecutive),
      ProbeResult.serialMismatch => loc(context).routerIdentityMismatch,
      null => loc(context).waitingForFirstConnectionCheck,
    };

    return AppDialog(
      title: SizedBox(
        width: 360,
        child: AppText.titleLarge(loc(context).routerIsRebooting),
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
              AppText.bodyMedium(loc(context).wifiSwitchWarning),
            ],
          ],
        ),
      ),
      actions: [
        AppButton.text(
          label: loc(context).returnToLoginPage,
          identifier: 'firmware-recovery-return-login',
          onTap: () {
            notifier.exitToLogout();
          },
        ),
        AppButton.primary(
          label:
              _retrying ? loc(context).checkingEllipsis : loc(context).retryNow,
          identifier: 'firmware-recovery-retry',
          onTap: _retrying
              ? null
              : () async {
                  setState(() => _retrying = true);
                  try {
                    await notifier.retryNow();
                  } finally {
                    if (mounted) {
                      setState(() => _retrying = false);
                    }
                  }
                },
        ),
      ],
    );
  }
}
