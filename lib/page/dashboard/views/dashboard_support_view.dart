import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/model/cloud_remote_assistance_info.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardSupportView extends ArgumentsBaseConsumerStatefulView {
  const DashboardSupportView({super.key, super.args});

  @override
  ConsumerState<DashboardSupportView> createState() =>
      _DashboardSupportViewState();
}

class _DashboardSupportViewState extends ConsumerState<DashboardSupportView> {
  @override
  void initState() {
    super.initState();
    ref.read(menuController).setTo(NaviType.support);
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      title: loc(context).support,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: (context, constraints) =>
          LayoutBuilder(builder: (context, constraints) {
        return ResponsiveLayout(
            desktop: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 6.col,
                  child: supportCards(context, ref),
                ),
              ],
            ),
            mobile: supportCards(context, ref));
      }),
    );
  }

  Widget supportCards(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SupportOptionCard(
            icon: const Icon(
              LinksysIcons.faq,
              semanticLabel: 'faq',
            ),
            title: loc(context).dashboardSupportFAQTitle,
            description: loc(context).dashboardSupportFAQDesc,
            tapAction: () {
              context.pushNamed(RouteNamed.faqList);
            },
          ),
          // const AppGap.small2(),
          // SupportOptionCard(
          //   icon: const Icon(LinksysIcons.supportAgent),
          //   title: loc(context).dashboardSupportCallbackTitle,
          //   description: loc(context).dashboardSupportCallbackDesc,
          //   tapAction: () {
          //     context.pushNamed(RouteNamed.callbackDescription);
          //   },
          // ),
          const AppGap.small2(),
          SupportOptionCard(
            icon: const Icon(LinksysIcons.call),
            title: loc(context).dashboardSupportCallSupportTitle,
            description: loc(context).dashboardSupportCallSupportDesc,
            tapAction: () {
              context.pushNamed(RouteNamed.callSupportMainRegion);
            },
          ),

          const AppGap.small2(),
          SupportOptionCard(
            icon: const Icon(LinksysIcons.help),
            title: 'Remote Assistance',
            description: '',
            tapAction: () {
              _doRemoteAssistance();
            },
          ),
        ],
      );

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

      if (!mounted) return;
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
          children: const [
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
            AppGap.medium(),
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

class SupportOptionCard extends StatelessWidget {
  final Icon icon;
  final String title;
  final String description;
  final VoidCallback? tapAction;

  const SupportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.tapAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        onTap: tapAction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const AppGap.small2(),
            AppText.titleSmall(title),
            const AppGap.small2(),
            AppText.bodyMedium(description),
          ],
        ),
      ),
    );
  }
}
