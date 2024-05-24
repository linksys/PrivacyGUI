import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class FaqListView extends ArgumentsConsumerStatelessView {
  const FaqListView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyledAppPageView(
      title: loc(context).faqs,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: ListView(
          shrinkWrap: true,
          children: [
            AppExpansionCard(
              title: loc(context).setup,
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [
                Row(
                  children: [
                    AppTextButton(
                      loc(context).noInternetConnectionTitle,
                      onTap: () {
                        //
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
            AppExpansionCard(
              title: loc(context).connectivity,
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextButton(
                          loc(context).faqListLoseChildNode,
                          onTap: () {
                            // TODO: Add link
                          },
                        ),
                        AppTextButton(
                          loc(context).faqListLoseDevices,
                          onTap: () {
                            // TODO: Add link
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
            AppExpansionCard(
              title: loc(context).speed,
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [],
            ),
            AppExpansionCard(
              title: loc(context).passwordAndAccess,
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [],
            ),
            AppExpansionCard(
              title: loc(context).hardware,
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [],
            ),
          ],
        ),
      ),
    );
  }
}
