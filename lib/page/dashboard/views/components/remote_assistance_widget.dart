import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/model/cloud_remote_assistance_info.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:url_launcher/url_launcher.dart';

class RemoteAssistanceWidget extends ConsumerStatefulWidget {
  final Widget child;
  const RemoteAssistanceWidget({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<RemoteAssistanceWidget> createState() =>
      _RemoteAssistanceWidgetState();
}

class _RemoteAssistanceWidgetState
    extends ConsumerState<RemoteAssistanceWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _doRemoteAssistance,
      child: widget.child,
    );
  }

  void _doRemoteAssistance() {
    ref.read(raSessionProvider.notifier).raGenPin().then((pin) {
      String? status;
      final content = StreamBuilder<CloudRemoteAssistanceInfo>(
        stream: ref.read(raSessionProvider.notifier).pollSessionInfo(),
        builder: (BuildContext context,
            AsyncSnapshot<CloudRemoteAssistanceInfo> snapshot) {
          if (snapshot.hasError) {
            return AppText.bodyMedium(
                'Something wrong here: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return _buildShowPinWidget(pin);
          }
          final info = snapshot.data!;
          status = info.status;
          if (info.status == 'ACTIVE') {
            final countingFromInfo = 1800 + (info.expiredIn ?? -1800);
            final countStream = Stream<int>.periodic(const Duration(seconds: 1),
                (count) => countingFromInfo + count).take(200);
            return StreamBuilder(
                stream: countStream,
                builder: (context, counting) {
                  final currentCounting =
                      countingFromInfo > (counting.data ?? 0)
                          ? countingFromInfo
                          : (counting.data ?? 0);
                  return _buildCountingWidget(
                      DateFormatUtils.formatTimeMSS(currentCounting));
                });
          } else if (info.status == 'INVALID') {
            return _buildErrorWidget('Invalid Session!');
          } else {
            return _buildShowPinWidget(pin);
          }
        },
      );
      showSimpleAppDialog(context,
          dismissible: status == 'ACTIVE',
          title: 'Remote Assistance',
          content: content,
          actions: status == 'INVALID'
              ? [
                  AppTextButton(
                    'Ok',
                    onTap: () {
                      context.pop();
                    },
                  )
                ]
              : null);
    }).catchError((error) {
      _showSupportHintModal();
    }, test: (error) => error is RANoSessionException).catchError((error) {
      _showSessionInProgressModal();
    }, test: (error) => error is RASessionInProgressException);
  }

  Widget _buildCountingWidget(String counting) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelLarge(
            'A Linksys support agent has remote access to your Linksys Smart Wi-Fi account and your home network.'),
        AppText.labelLarge(counting),
        const AppGap.medium(),
        AppFilledButton(
          'End Session',
          onTap: () {
            ref.read(raSessionProvider.notifier).raLogout().then((value) {
              ref.read(authProvider.notifier).logout();
            });
          },
        )
      ],
    );
  }

  Widget _buildShowPinWidget(String pin) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.bodyMedium(
            'Share the PIN below with the Linksys support agent on the phone to authorize remote assistance.'),
        const AppGap.small2(),
        const AppText.bodyMedium('PIN:'),
        Center(
          child: AppText.displayMedium(
            pin,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const AppGap.medium(),
        ExpansionTile(
          title: AppText.bodyMedium(
            'Terms of service',
            color: Theme.of(context).colorScheme.primary,
          ),
          tilePadding: EdgeInsets.only(),
          children: [
            AppBulletList(children: [
              AppText.bodyMedium(
                  'You may end remote assistance at any time by clicking the orange End Session button on your screen.'),
              AppText.bodyMedium(
                  'Only the support agent to who whom you provided the PIN will have access to your Linksys Smart Wi-Fi account and home network.'),
              AppText.bodyMedium(
                  'The support agent will be able to view your home network and troubleshoot any support issues.'),
              AppText.bodyMedium(
                  'Your remote assistance session is open only until you end it. No one will have access to your Linksys Smart Wi-Fi account or home network after you end the session.'),
              AppText.bodyMedium(
                  'The support agent should never ask for your password.'),
            ]),
            const AppGap.medium(),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelLarge('Error - $errorMessage'),
        AppFilledButton(
          'End Session',
          onTap: () {
            ref.read(raSessionProvider.notifier).raLogout().then((value) {
              ref.read(authProvider.notifier).logout();
            });
          },
        )
      ],
    );
  }

  _showSupportHintModal() {
    showSimpleAppOkDialog(context,
        title: 'Remote assistance',
        content: AppStyledText.link(
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
            }));
  }

  _showSessionInProgressModal() {
    showSimpleAppOkDialog(context,
        icon: const Icon(LinksysIcons.error),
        title: 'Remote assistance',
        content: AppText.labelLarge('Error! Session is in progress'));
  }
}