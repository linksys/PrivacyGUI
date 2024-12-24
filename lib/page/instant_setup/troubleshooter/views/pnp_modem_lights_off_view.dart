import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

class PnpModemLightsOffView extends ConsumerStatefulWidget {
  const PnpModemLightsOffView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpModemLightsOffView> createState() => _PnpLightOffViewState();
}

class _PnpLightOffViewState extends ConsumerState<PnpModemLightsOffView> {
  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).pnpModemLightsOffTitle,
      scrollable: true,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(
            loc(context).pnpModemLightsOffDesc,
          ),
          const AppGap.large3(),
          const AppGap.small2(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture(
                  CustomTheme.of(context).images.modemDevice,
                  semanticsLabel: 'modem Device image',
                  fit: BoxFit.fitWidth,
                ),
                const AppGap.large3(),
                const AppGap.large5(),
                Row(
                  children: [
                    Flexible(
                      child: AppTextButton.noPadding(
                        loc(context).pnpModemLightsOffTip,
                        onTap: () {
                          showSimpleAppOkDialog(
                            context,
                            content: _bottomSheetContent(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const AppGap.large3(),
          AppFilledButton(
            loc(context).next,
            onTap: () {
              context.pushNamed(RouteNamed.pnpWaitingModem);
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomSheetContent() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.large2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.headlineSmall(
            loc(context).pnpModemLightsOffTipTitle,
          ),
          const AppGap.large2(),
          AppText.bodyMedium(
            loc(context).pnpModemLightsOffTipDesc,
          ),
          const AppGap.large2(),
          AppBulletList(style: AppBulletStyle.number, children: [
            AppText.bodyMedium(
              loc(context).pnpModemLightsOffTipStep1,
            ),
            AppText.bodyMedium(
              loc(context).pnpModemLightsOffTipStep2,
            ),
            AppStyledText.bold(
              loc(context).pnpModemLightsOffTipStep3,
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              tags: const ['b'],
            ),
          ]),
        ],
      ),
    );
  }
}
