import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/support/faq_data.dart';

class FaqListView extends ArgumentsConsumerStatefulView {
  const FaqListView({super.key});

  @override
  ConsumerState<FaqListView> createState() => _FaqListViewState();
}

class _FaqListViewState extends ConsumerState<FaqListView> {
  @override
  void initState() {
    super.initState();
    ref.read(menuController).setTo(NaviType.support);
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).faqs,
      backState: StyledBackState.none,
      menuWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodySmall(loc(context).faqLookingFor),
          const AppGap.medium(),
          AppTextButton.noPadding(
            loc(context).faqVisitLinksysSupport,
            identifier:
                'now-faq-link-${FaqItem.faqVisitLinksysSupport.displayString(context).kebab()}',
            onTap: () {
              gotoOfficialWebUrl(FaqItem.faqVisitLinksysSupport.url,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ],
      ),
      menuOnRight: true,
      pageContentType: PageContentType.flexible,
      child: (context, constraints) {
        List<FaqCategory> categories = [
          FaqSetupCategory(),
          FaqConnectivityCategory(),
          FaqSpeedCategory(),
          FaqPasswordCategory(),
          FaqHardwareCategory(),
        ];
        return SizedBox(
          width: 9.col,
          child: ListView(
            primary: true,
            shrinkWrap: true,
            children: [
              ...categories.map((category) => Column(
                    children: [
                      _buildExpansionCard(
                        title: category.displayString(context),
                        children: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: category.items
                              .map((item) => AppTextButton(
                                    item.displayString(context),
                                    identifier:
                                        'now-faq-${item.displayString(context).kebab()}',
                                    onTap: () {
                                      gotoOfficialWebUrl(item.url,
                                          locale: ref
                                              .read(appSettingsProvider)
                                              .locale);
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                      const AppGap.small2(),
                    ],
                  )),
            ],
          ),
        );
      },
    );
  }

  AppExpansionCard _buildExpansionCard({
    required String title,
    required Widget children,
  }) {
    return AppExpansionCard(
      title: title,
      identifier: 'now-faq-${title.kebab()}',
      expandedIcon: LinksysIcons.add,
      collapsedIcon: LinksysIcons.remove,
      children: [
        Row(
          children: [
            Expanded(child: children),
          ],
        ),
      ],
    );
  }
}
