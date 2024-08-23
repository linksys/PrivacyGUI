import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardSupportView extends ArgumentsConsumerStatelessView {
  final String _tag = 'dashboard-support';

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
                  child: supportCards(context),
                ),
              ],
            ),
            mobile: supportCards(context));
      }),
    );
  }

  Widget supportCards(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SupportOptionCard(
            identifier: semanticIdentifier(tag: _tag, description: 'faq'),
            semanticLabel: 'faq',
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
            identifier: semanticIdentifier(tag: _tag, description: 'call'),
            semanticLabel: 'call',
            icon: const Icon(LinksysIcons.call),
            title: loc(context).dashboardSupportCallSupportTitle,
            description: loc(context).dashboardSupportCallSupportDesc,
            tapAction: () {
              context.pushNamed(RouteNamed.callSupportMainRegion);
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
  final bool excludeSemantics;
  final bool explicitChildNodes;
  final String? identifier;
  final String? semanticLabel;

  const SupportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.tapAction,
    this.excludeSemantics = false,
    this.explicitChildNodes = true,
    this.identifier,
    this.semanticLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        identifier: identifier,
        semanticLabel: semanticLabel,
        onTap: tapAction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
                identifier: identifier != null ? '$identifier-icon' : null,
                label: semanticLabel != null ? '$semanticLabel icon' : null,
                child: icon),
            const AppGap.small2(),
            AppText.titleSmall(
              title,
              identifier: identifier != null ? '$identifier-title' : null,
              semanticLabel:
                  semanticLabel != null ? '$semanticLabel title' : null,
            ),
            const AppGap.small2(),
            AppText.bodyMedium(
              description,
              identifier: identifier != null ? '$identifier-description' : null,
              semanticLabel:
                  semanticLabel != null ? '$semanticLabel description' : null,
            ),
          ],
        ),
      ),
    );
  }
}
