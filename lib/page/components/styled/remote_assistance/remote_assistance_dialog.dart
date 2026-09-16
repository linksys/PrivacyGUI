import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/timer_countdown_widget.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/views/components/remote_assistance_animation.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showRemoteAssistanceDialog(BuildContext context, WidgetRef ref,
    {bool isPassive = false}) {
  // Mark a dialog as shown so the dashboard does not auto-open a second
  // (passive) dialog while this one is open. Cleared when the dialog closes.
  ref.read(remoteClientProvider.notifier).setDialogShown(true);
  // Set when the session ends underneath the dialog, so the notice is shown
  // after it has closed rather than stacked on top of it.
  var endedUnderneath = false;
  // Both the Close button and the session ending lead to the same teardown, and
  // they can race; whichever gets there first does it.
  var isClosing = false;
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      bool isReady = isPassive;
      // One-time guard so the initialization side effect runs only on the
      // first build. The Consumer/StatefulBuilder below rebuild multiple times
      // (e.g. on setState and provider state changes); without this flag the
      // session would be initiated/streamed again on every rebuild.
      bool hasInitialized = false;
      return Consumer(
        builder: (context, ref, child) {
          void close() {
            if (isClosing) return;
            isClosing = true;
            ref.read(remoteClientProvider.notifier).endRemoteAssistance();
            // Resume polling. The dialog pauses it when the session goes ACTIVE
            // and closing is the only thing that turns it back on, so a session
            // that ends with the dialog still open used to leave the client
            // polling nothing for the rest of the login.
            ref.read(pollingProvider.notifier).checkAndStartPolling(true);
            Navigator.of(context).pop();
          }

          // #1559: the session can end while this dialog is open - the Guardian
          // closes it, or a new session replaces it. Keyed on leaving ACTIVE
          // rather than on reaching INVALID: in the CG#207 log every exit from
          // ACTIVE went to INITIATE (3) or to nothing (1), and INVALID never
          // occurred once. This mirrors the Guardian's own condition in
          // top_bar.dart, minus the logout - the client is a local login and
          // has nothing to log out of.
          ref.listen(
            remoteClientProvider.select((state) => state.sessionInfo?.status),
            (prevStatus, nextStatus) {
              if (prevStatus != GRASessionStatus.active ||
                  nextStatus == GRASessionStatus.active) {
                return;
              }
              logger.i(
                  '[RemoteAssistance]: session left ACTIVE ($nextStatus), closing dialog');
              endedUnderneath = true;
              close();
            },
          );
          return AlertDialog(
            title: AppText.titleMedium(loc(context).remoteAssistance),
            content: StatefulBuilder(builder: (context, setState) {
              if (!hasInitialized) {
                hasInitialized = true;
                if (isPassive) {
                  ref
                      .read(remoteClientProvider.notifier)
                      .startSessionInfoStream();
                } else {
                  ref
                      .read(remoteClientProvider.notifier)
                      .initiateRemoteAssistance()
                      .then((_) {
                    setState(() {
                      isReady = true;
                    });
                  });
                }
              }
              return SizedBox(
                width: 400,
                height: 400,
                child: !isReady
                    ? const Center(child: CircularProgressIndicator())
                    : _buildRemoteAssistanceDialog(ref, context),
              );
            }),
            actions: [
              AppFilledButton(
                loc(context).close,
                onTap: close,
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    // Dialog dismissed (Close button or barrier) - clear the shown flag so a
    // future session can auto-open a dialog again.
    ref.read(remoteClientProvider.notifier).setDialogShown(false);
    if (endedUnderneath && context.mounted) {
      // Told after the fact rather than left to guess: the dialog vanishing on
      // its own reads as a glitch without this.
      showSimpleAppDialog(
        context,
        dismissible: false,
        content:
            AppText.bodyMedium(loc(context).remoteAssistanceSessionExpired),
        actions: [
          AppTextButton(
            loc(context).ok,
            onTap: () => Navigator.of(context).pop(),
          )
        ],
      );
    }
  });
}

Widget _buildRemoteAssistanceDialog(WidgetRef ref, BuildContext context) {
  final state = ref.watch(remoteClientProvider);
  final sessionInfo = state.sessionInfo;
  final isPollingPaused = ref.read(pollingProvider.notifier).paused;
  if (sessionInfo?.status == GRASessionStatus.active && !isPollingPaused) {
    // Stop polling
    ref.read(pollingProvider.notifier).paused = true;
  }
  return switch (sessionInfo?.status ?? GRASessionStatus.initiate) {
    GRASessionStatus.initiate => _buildInitiateWidget(context),
    GRASessionStatus.pending => _buildPendingWidget(state, context),
    GRASessionStatus.active => _buildCountingWidget(state, context),
    GRASessionStatus.invalid => _buildInvalidWidget(context),
  };
}

Widget _buildInitiateWidget(BuildContext context) {
  return AppStyledText.link(
    loc(context).remoteAssistanceInitiateMessage,
    color: Theme.of(context).colorScheme.primary,
    defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
    tags: const ['a'],
    callbackTags: {
      'a': (tag, data) {
        final url = data['href'];
        if (url != null) {
          launchUrl(Uri.parse(url));
        }
      }
    },
  );
}

Widget _buildPendingWidget(RemoteClientState state, BuildContext context) {
  final initialSeconds =
      (kPendingSessionDurationSec + (state.sessionInfo?.expiredIn ?? 0)).abs();
  final pin = state.pinSessionId == state.sessionInfo?.id ? state.pin : null;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.labelLarge(loc(context).remoteAssistancePinCode),
      AppGap.large1(),
      // Only this session's PIN. Rendering `state.pin` unconditionally showed
      // one minted for a previous session, which no Guardian can use, and the
      // `?? ''` fallback made a missing PIN look like a rendering fault rather
      // than something still in flight (#1560).
      Center(
        child: pin != null
            ? AppText.displayLarge(pin)
            : const SizedBox.square(
                dimension: 48,
                child: Center(child: CircularProgressIndicator()),
              ),
      ),
      AppGap.large2(),
      TimerCountdownWidget(
        initialSeconds: initialSeconds,
        title: 'Pin code',
      ),
    ],
  );
}

Widget _buildInvalidWidget(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText.labelLarge(loc(context).remoteAssistanceInvalidSession),
    ],
  );
}

Widget _buildCountingWidget(RemoteClientState state, BuildContext context) {
  final initialSeconds = (state.sessionInfo?.expiredIn ?? 0).abs();
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const RemoteAssistanceAnimation(),
      AppText.labelLarge(loc(context).remoteAssistanceSessionActive),
      AppGap.large2(),
      TimerCountdownWidget(
        initialSeconds: initialSeconds,
        title: 'Session',
      ),
    ],
  );
}
