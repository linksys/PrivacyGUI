import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

class PnpLightsOffView extends ConsumerStatefulWidget {
  const PnpLightsOffView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpLightsOffView> createState() => _PnpLightOffViewState();
}

class _PnpLightOffViewState extends ConsumerState<PnpLightsOffView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: 'Make sure the lights are off',
      scrollable: true,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppText.bodyLarge(
            'These settings are provided by your Internet Service Provider (ISP). If you aren\'t sure about yours, we recommend contacting your ISP.',
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture(
                    CustomTheme.of(context).images.modemDevice,
                    fit: BoxFit.fitWidth,
                  ),
                  const AppGap.large2(),
                  const AppGap.large3(),
                  Row(
                    children: [
                      AppTextButton(
                        'Are the lights still on after unplugging?',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            useSafeArea: true,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (context) {
                              return _bottomSheetContent();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
        footer: AppFilledButton.fillWidth(
          loc(context).next,
          onTap: () {
            context.goNamed(RouteNamed.pnpWaitingModem);
          },
        ),
      ),
    );
  }

  Widget _bottomSheetContent() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.large1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.headlineSmall(
            'You may have a battery-powered modem that requires extra steps',
          ),
          const AppGap.large1(),
          const AppText.bodyMedium(
            'Your modem may have a backup battery. To restart, DO NOT remove the battery. Follow these instructions:',
          ),
          const AppGap.large1(),
          AppBulletList(style: AppBulletStyle.number, children: [
            const AppText.bodyMedium(
              'Find the modem\'s power, reboot or restart button. Press and hold it. Do not press RESET as it may restore the modem to factory settings. If your modem does not have a power, reboot or restart button, contact your Internet Service Provider for guidance.',
            ),
            const AppText.bodyMedium(
              'Wait for the modem lights to turn OFF.</b> Wait 2 minutes to allow stored memory and power to be flushed from the device. Release the button.',
            ),
            AppStyledText.bold(
              '<b>Wait for the modem to completely start up and continue setup.</b>',
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              tags: const ['b'],
            ),
          ]),
        ],
      ),
    );
  }
}
