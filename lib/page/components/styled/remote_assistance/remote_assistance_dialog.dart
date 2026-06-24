import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/timer_countdown_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/remote_assistance_animation.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:url_launcher/url_launcher.dart';

/// Total duration (in seconds) of the PENDING session window (45 minutes).
const int kPendingSessionDurationSec = 2700;

Future<void> showRemoteAssistanceDialog(BuildContext context, WidgetRef ref,
    {bool isPassive = false}) {
  // Mark a dialog as shown so the dashboard does not auto-open a second
  // (passive) dialog while this one is open. Cleared when the dialog closes.
  ref.read(remoteClientProvider.notifier).setDialogShown(true);
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
                onTap: () {
                  ref.read(remoteClientProvider.notifier).endRemoteAssistance();
                  // Resume polling
                  ref.read(pollingProvider.notifier).checkAndStartPolling(true);
                  Navigator.of(context).pop();
                },
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
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.labelLarge(loc(context).remoteAssistancePinCode),
      AppGap.large1(),
      Center(child: AppText.displayLarge(state.pin ?? '')),
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
