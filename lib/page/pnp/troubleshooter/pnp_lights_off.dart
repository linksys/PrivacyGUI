import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

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
      child: AppBasicLayout(
        content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.big(),
              const AppText.headlineMedium(
                'Make sure the lights are off',
              ),
              const AppGap.big(),
              const AppText.bodyMedium(
                  'These settings are provided by your Internet Service Provider (ISP). If you aren\'t sure about yours, we recommend contacting your ISP.'),
              Expanded(
                child: Center(
                  child: SvgPicture(
                    CustomTheme.of(context).images.modemLights,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ]),
        footer: Column(children: [
          AppFilledButton.fillWidth(
            'Next',
            onTap: () {
              context.goNamed(RouteNamed.pnpWaitingModem);
            },
          ),
          AppTextButton.fillWidth(
            'Are the lights still on after unplugging?',
            onTap: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                useSafeArea: true,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (context) {
                  return _showBottomsheet();
                },
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _showBottomsheet() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: AppIconButton(
              icon: getCharactersIcons(context).crossDefault,
              onTap: () {
                context.pop();
              },
            ),
          ),
          const AppText.headlineMedium(
            'You may have a battery-powered modem that requires extra steps',
          ),
          const AppGap.big(),
          const AppText.bodyMedium(
              'Your modem may have a backup battery. To restart, DO NOT remove the battery. Follow these instructions:'),
          const AppGap.big(),
          AppBulletList(style: AppBulletStyle.number, children: [
            AppStyledText.bold(
                '<b>Find the modem\'s power, reboot or restart button. Press and hold it.</b> Do not press RESET as it may restore the modem to factory settings. If your modem does not have a power, reboot or restart button, contact your Internet Service Provider for guidance.',
                defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
                tags: const ['b']),
            AppStyledText.bold(
                '<b>Wait for the modem lights to turn OFF.</b> Wait 2 minutes to allow stored memory and power to be flushed from the device. Release the button.',
                defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
                tags: const ['b']),
            AppStyledText.bold(
                '<b>Wait for the modem to completely start up and continue setup.</b>',
                defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
                tags: const ['b']),
          ]),
        ],
      ),
    );
  }
}
