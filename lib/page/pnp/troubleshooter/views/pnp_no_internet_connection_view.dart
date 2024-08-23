import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

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
        padding: const EdgeInsets.all(Spacing.large3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LinksysIcons.publicOff,
              size: 48,
            ),
            const AppGap.large3(),
            _titleView(context),
            const AppGap.medium(),
            AppText.bodyLarge(
              loc(context).noInternetConnectionDescription,
            ),
            const AppGap.large3(),
            if (state.hasResetModem)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.small2),
                child: AppCard(
                  onTap: () {
                    context.pushNamed(RouteNamed.callSupportMainRegion);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.labelLarge(
                              loc(context).needHelp,
                            ),
                            const AppGap.small3(),
                            AppText.bodyMedium(
                              loc(context).pnpNoInternetConnectionContactSupport,
                            ),
                          ],
                        ),
                      ),
                      const Icon(LinksysIcons.chevronRight),
                    ],
                  ),
                ),
              ),
            AppCard(
              onTap: () {
                context.pushNamed(RouteNamed.pnpUnplugModem);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                          loc(context).pnpNoInternetConnectionRestartModem,
                        ),
                        const AppGap.small3(),
                        AppText.bodyMedium(
                          loc(context).pnpNoInternetConnectionRestartModemDesc,
                        ),
                      ],
                    ),
                  ),
                  const Icon(LinksysIcons.chevronRight),
                ],
              ),
            ),
            const AppGap.small2(),
            AppCard(
              onTap: () {
                context.pushNamed(RouteNamed.pnpIspTypeSelection);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                          loc(context).pnpNoInternetConnectionEnterISP,
                        ),
                        const AppGap.small3(),
                        AppText.bodyMedium(
                          loc(context).pnpNoInternetConnectionEnterISPDesc,
                        ),
                      ],
                    ),
                  ),
                  const Icon(LinksysIcons.chevronRight),
                ],
              ),
            ),
            const AppGap.large3(),
            AppFilledButton(
              loc(context).tryAgain,
              onTap: () {
                logger.d('[PnP Troubleshooter]: Try again internet connection');
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
        ? loc(context).noInternetConnectionWithSSIDTitle(_ssid!)
        : loc(context).noInternetConnectionTitle;
    return AppText.headlineSmall(titleString);
  }
}
