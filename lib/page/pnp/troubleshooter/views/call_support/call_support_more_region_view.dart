import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/call_support/call_support_main_region_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class CallSupportMoreRegionView extends ArgumentsConsumerStatelessView {
  const CallSupportMoreRegionView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = args['region'] as CallSupportRegion;
    final title = region.getTitle(context);
    final regionList = region.moreRegions();

    return StyledAppPageView(
      title: title,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: ResponsiveLayout(
          desktop: _desktopLayout(regionList),
          mobile: _mobileLayout(regionList),
        ),
      ),
    );
  }

  Widget _desktopLayout(List<CallSupportRegion> regionList) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.semiSmall,
        crossAxisSpacing: Spacing.semiBig,
        childAspectRatio: 5.8,
      ),
      itemCount: regionList.length,
      itemBuilder: (context, index) {
        final region = regionList[index];
        return _buildRegionCard(context, region);
      },
    );
  }

  Widget _mobileLayout(List<CallSupportRegion> regionList) {
    return ListView.builder(
      itemCount: regionList.length,
      itemBuilder: (context, index) {
        final region = regionList[index];
        return _buildRegionCard(context, region);
      },
    );
  }

  AppCard _buildRegionCard(BuildContext context, CallSupportRegion region) {
    return AppCard(
      onTap: () {
        _showCallInfoAlert(
          context,
          name: region.getTitle(context),
          number: region.phone ?? '',
        );
      },
      child: Container(
        alignment: Alignment.centerLeft,
        child: AppText.titleMedium(
          region.getTitle(context),
        ),
      ),
    );
  }

  Future<void> _showCallInfoAlert(
    BuildContext context, {
    required String name,
    required String number,
  }) {
    return showSimpleAppOkDialog(
      context,
      width: kDefaultDialogWidth + 1, // Particularly add 1 for Saudi Arabia
      title: name,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                  Flexible(
                    child: AppText.titleLarge(
                      number,
                      color: Theme.of(context).colorScheme.primary,
                      maxLines: 2,
                    ),
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
          AppText.bodyLarge(loc(context).callSupportDetailDesc2),
        ],
      ),
    );
  }
}
