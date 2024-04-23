import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

class PnpNoInternetConnectionView extends ConsumerStatefulWidget {
  const PnpNoInternetConnectionView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpNoInternetConnectionView> createState() =>
      _PnpNoInternetConnectionState();
}

class _PnpNoInternetConnectionState
    extends ConsumerState<PnpNoInternetConnectionView> {
  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      scrollable: true,
      backState: StyledBackState.none,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: _contentView(context),
      ),
    );
  }

  Widget _contentView(BuildContext context) {
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.big),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LinksysIcons.publicOff,
              size: 48,
            ),
            const AppGap.big(),
            _titleView(context),
            const AppGap.regular(),
            AppText.bodyLarge(
              loc(context).no_internet_connection_description,
            ),
            const AppGap.big(),
            //TODO: Add condition check for Linksys Support
            AppCard(
              onTap: () {
                context.goNamed(RouteNamed.contactSupportChoose);
              },
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                          'Need help?',
                        ),
                        AppGap.small(),
                        AppText.bodyMedium(
                          'Contact Linksys support',
                        ),
                      ],
                    ),
                  ),
                  Icon(LinksysIcons.chevronRight),
                ],
              ),
            ),
            AppCard(
              onTap: () {
                context.goNamed(RouteNamed.pnpUnplugModem);
              },
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                          'Restart your modem',
                        ),
                        AppGap.small(),
                        AppText.bodyMedium(
                          'Some ISPs require this when setting up a new router',
                        ),
                      ],
                    ),
                  ),
                  Icon(LinksysIcons.chevronRight),
                ],
              ),
            ),
            AppCard(
              onTap: () {
                //TODO: GO to ISP setting
              },
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                          'Enter ISP settings',
                        ),
                        AppGap.small(),
                        AppText.bodyMedium(
                          'Enter Static IP or PPPoE settings provided by your ISP',
                        ),
                      ],
                    ),
                  ),
                  Icon(LinksysIcons.chevronRight),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.big),
              child: AppTextButton(
                'Log into router',
                onTap: () {
                  //TODO: Go to login local view
                },
              ),
            ),
            AppFilledButton(
              'Try Again',
              onTap: () {
                //TODO: Try again
              },
            )
          ],
        ),
      ),
    );
  }

  AppText _titleView(BuildContext context) {
    final isRouterNoInternet = true;
    final titleString = isRouterNoInternet
        ? '{Linksys00999} has no internet connection'
        : loc(context).no_internet_connection_title;
    return AppText.headlineSmall(
      titleString,
    );
  }
}
