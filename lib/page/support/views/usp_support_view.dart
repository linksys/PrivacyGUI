import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/support/faq_data.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Support page — reuses FAQ data/categories from the JNAP support page
/// without any JNAP provider dependencies.
class UspSupportView extends ConsumerWidget {
  const UspSupportView({super.key});

  static final List<FaqCategory> _categories = [
    FaqSetupCategory(),
    FaqConnectivityCategory(),
    FaqSpeedCategory(),
    FaqPasswordCategory(),
    FaqHardwareCategory(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      title: loc(context).faqs,
      child: (childContext, constraints) {
        return SizedBox(
          width: childContext.colWidth(9),
          child: ListView(
            primary: true,
            shrinkWrap: true,
            children: [
              ..._categories.map((category) => Column(
                    children: [
                      AppExpansionPanel.single(
                        headerTitle: category.displayString(childContext),
                        content: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: category.items
                                    .map((item) => AppButton.text(
                                          label:
                                              item.displayString(childContext),
                                          onTap: () {
                                            gotoOfficialWebUrl(
                                              item.url,
                                              locale: ref
                                                  .read(appSettingsProvider)
                                                  .locale,
                                            );
                                          },
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppGap.sm(),
                    ],
                  )),
            ],
          ),
        );
      },
    );
  }
}
