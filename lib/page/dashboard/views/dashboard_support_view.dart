import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardSupportView extends ArgumentsConsumerStatelessView {
  const DashboardSupportView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      title: loc(context).support,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: LayoutBuilder(builder: (context, constraints) {
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
            icon: const Icon(LinksysIcons.faq),
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
              ref.read(raSessionProvider.notifier).raGenPin().then((pin) {
                showMessageAppOkDialog(context,
                    title: 'Remote assistance', message: 'PIN: $pin');
              }).catchError((error) {
                showSimpleAppOkDialog(context,
                    title: 'Remote assistance',
                    content: AppStyledText.link(
                        'To take advantage of Remote Assistance, you must first contact a phone support agent. Go to <a href="http://www.linksys.com/support" target="_blank">linksys.com/support</a> and click on Phone Call to get started.',
                        defaultTextStyle:
                            Theme.of(context).textTheme.bodyMedium!,
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
              }, test: (error) => error is RANoSessionException);
            },
          ),
        ],
      );
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
