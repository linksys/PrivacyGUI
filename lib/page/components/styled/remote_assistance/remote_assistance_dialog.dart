import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/timer_countdown_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/remote_assistance_animation.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:url_launcher/url_launcher.dart';

void showRemoteAssistanceDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      bool isLoading = true;
      return Consumer(
        builder: (context, ref, child) {
          return AlertDialog(
            title: AppText.titleMedium(loc(context).remoteAssistance),
            content: StatefulBuilder(builder: (context, setState) {
              if (isLoading) {
                ref
                    .read(remoteClientProvider.notifier)
                    .initiateRemoteAssistance()
                    .then((_) {
                  setState(() {
                    isLoading = false;
                  });
                });
              }
              return SizedBox(
                width: 400,
                height: 400,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildRemoteAssistanceDialog(ref, context),
              );
            }),
            actions: [
              AppButton.primary(
                label: loc(context).close,
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
  );
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
    GRASessionStatus.pending => _buildPendingWidget(state, context),
    GRASessionStatus.active => _buildCountingWidget(state, context),
    GRASessionStatus.invalid => _buildInvalidWidget(context),
    GRASessionStatus.initiate => _buildInitiateWidget(context),
  };
}

Widget _buildInitiateWidget(BuildContext context) {
  return AppStyledText(
    text: loc(context).remoteAssistanceInitiateMessage,
    onTapHandlers: {
      'a': () {
        launchUrl(Uri.parse('http://www.linksys.com/support'));
      },
    },
  );
}

Widget _buildPendingWidget(RemoteClientState state, BuildContext context) {
  final initialSeconds = (2700 + (state.sessionInfo?.expiredIn ?? 0)) * -1;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.labelLarge(loc(context).remoteAssistancePinCode),
      AppGap.lg(),
      Center(child: AppText.displayLarge(state.pin ?? '')),
      AppGap.xl(),
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
  final initialSeconds = (state.sessionInfo?.expiredIn ?? 0) * -1;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const RemoteAssistanceAnimation(),
      AppText.labelLarge(loc(context).remoteAssistanceSessionActive),
      AppGap.xl(),
      TimerCountdownWidget(
        initialSeconds: initialSeconds,
        title: 'Session',
      ),
    ],
  );
}
