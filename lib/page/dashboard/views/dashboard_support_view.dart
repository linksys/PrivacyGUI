import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

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
      child: AppBasicLayout(
        content: ListView(
          shrinkWrap: true,
          children: [
            SupportOptionCard(
              icon: const Icon(LinksysIcons.faq),
              title: 'View FAQ',
              description: 'Read most common help articles sorted by topic',
              tapAction: () {
                context.pushNamed(RouteNamed.faqList);
              },
            ),
            SupportOptionCard(
              icon: const Icon(LinksysIcons.supportAgent),
              title: 'Get a Callback',
              description: 'Skip waiting. Send a message and a Linksys support agent will call you.',
              tapAction: () {
                context.pushNamed(RouteNamed.callbackDescription);
              },
            ),
            SupportOptionCard(
              icon: const Icon(LinksysIcons.call),
              title: 'Call Support',
              description: 'Wait times apply',
              tapAction: () {
                context.pushNamed(RouteNamed.contactSupportChoose);
              },
            ),
          ],
        ),
      ),
    );
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
    return AppCard(
      onTap: tapAction,
      child: SizedBox(
        height: 130,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const AppGap.semiSmall(),
            AppText.titleSmall(title),
            const AppGap.semiSmall(),
            AppText.bodyMedium(description),
          ],
        ),
      ),
    );
  }
}
