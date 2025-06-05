import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/views/components/remote_assistance_animation.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:privacy_gui/utils.dart';

void showRemoteAssistanceDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      bool isLoading = true;
      return Consumer(
        builder: (context, ref, child) {
          return AlertDialog(
            title: AppText.titleMedium('Remote Assistance'),
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
              AppFilledButton(
                loc(context).close,
                onTap: () {
                  ref.read(remoteClientProvider.notifier).endRemoteAssistance();
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
  return switch (sessionInfo?.status ?? GRASessionStatus.initiate) {
    GRASessionStatus.pending => _buildPendingWidget(state),
    GRASessionStatus.active => _buildCountingWidget(state),
    GRASessionStatus.invalid => _buildInvalidWidget(),
    GRASessionStatus.initiate => _buildInitiateWidget(context),
  };
}

Widget _buildInitiateWidget(BuildContext context) {
  return Center(
    child: AppStyledText.link(
        'To take advantage of Remote Assistance, you must first contact a phone support agent. Go to <a href="http://www.linksys.com/support" target="_blank">linksys.com/support</a> and click on Phone Call to get started.',
        color: Theme.of(context).colorScheme.primary,
        defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
        tags: const [
          'a'
        ],
        callbackTags: {
          'a': (tag, data) {
            final url = data['href'];
            if (url != null) {
              launchUrl(Uri.parse(url));
            }
          }
        }),
  );
}

Widget _buildPendingWidget(RemoteClientState state) {
  final initialSeconds = (2700 + (state.sessionInfo?.expiredIn ?? 0)) * -1;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.labelLarge('Your pin code is:'),
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

Widget _buildInvalidWidget() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: const [
      AppText.labelLarge('Invalid session. Please contact a support agent.'),
    ],
  );
}

Widget _buildCountingWidget(RemoteClientState state) {
  final initialSeconds = (state.sessionInfo?.expiredIn ?? 0) * -1;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const RemoteAssistanceAnimation(),
      AppText.labelLarge(
          'A Linksys support agent has remote access to your Linksys Smart Wi-Fi account and your home network.'),
      AppGap.large2(),
      TimerCountdownWidget(
        initialSeconds: initialSeconds,
        title: 'Session',
      ),
    ],
  );
}

class TimerCountdownWidget extends StatelessWidget {
  final int initialSeconds;
  final String? title;
  const TimerCountdownWidget({
    Key? key,
    required this.initialSeconds,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (count) => initialSeconds - count,
      ).take(initialSeconds + 1),
      builder: (context, snapshot) {
        final secondsLeft = snapshot.data ?? initialSeconds;
        final display = secondsLeft > 0
            ? '${title ?? ''} expires in ${DateFormatUtils.formatTimeMSS(secondsLeft)}'
            : '${title ?? ''} expired';
        return AppText.bodyMedium(display);
      },
    );
  }
}
