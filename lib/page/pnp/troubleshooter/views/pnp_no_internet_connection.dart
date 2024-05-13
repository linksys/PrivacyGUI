import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/pnp/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

class PnpNoInternetConnectionView extends ArgumentsConsumerStatefulView {
  const PnpNoInternetConnectionView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<PnpNoInternetConnectionView> createState() =>
      _PnpNoInternetConnectionState();
}

class _PnpNoInternetConnectionState
    extends ConsumerState<PnpNoInternetConnectionView> {
  late final String? _ssid;
  
  @override
  void initState() {
    _ssid = widget.args['ssid'] as String?;
    super.initState();
  }

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
    final state = ref.watch(pnpTroubleshooterProvider);
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
              loc(context).noInternetConnectionDescription,
            ),
            const AppGap.big(),
            if (state.hasResetModem)
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
                context.goNamed(RouteNamed.pnpIspTypeSelection);
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
                context.goNamed(RouteNamed.pnp);
              },
            )
          ],
        ),
      ),
    );
  }

  AppText _titleView(BuildContext context) {
    final titleString = _ssid != null
        ? '$_ssid has no internet connection'
        : loc(context).noInternetConnectionTitle;
    return AppText.headlineSmall(titleString);
  }
}
