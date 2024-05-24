import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/contact_support/contact_support_selection_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class ContactSupportDetailView extends ArgumentsConsumerStatelessView {
  const ContactSupportDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = args['region'] as ContactSupportRegion;

    return StyledAppPageView(
      title: selectedRegion.getTitle(context),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LinksysIcons.contact,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const AppGap.regular(),
                    AppText.titleLarge(
                      selectedRegion.phone,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 40,
                    top: Spacing.semiSmall,
                  ),
                  child: AppText.bodyMedium(
                      loc(context).callSupportDetailTwentyFourSeven),
                ),
              ],
            ),
            const AppGap.extraBig(),
            AppText.bodyLarge(loc(context).callSupportDetailDesc),
          ],
        ),
      ),
    );
  }
}
