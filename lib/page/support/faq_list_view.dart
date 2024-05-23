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
      title: 'FAQs',
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: ListView(
          shrinkWrap: true,
          children: [
            AppExpansionCard(
              title: 'Setup',
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
              title: 'Connectivity',
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextButton(
                          'Child node keeps losing connection',
                          onTap: () {
                            //
                          },
                        ),
                        AppTextButton(
                          'Devices losing connection',
                          onTap: () {
                            //
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
              title: 'Speed',
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [],
            ),
            AppExpansionCard(
              title: 'Password & Access',
              expandedIcon: LinksysIcons.add,
              collapsedIcon: LinksysIcons.remove,
              children: [],
            ),
            AppExpansionCard(
              title: 'Hardware',
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
