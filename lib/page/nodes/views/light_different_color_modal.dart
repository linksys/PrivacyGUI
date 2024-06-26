import 'package:flutter/material.dart';
import 'package:privacy_gui/constants/color_const.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/nodes/views/light_info_tile.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';

class LightDifferentColorModal extends StatelessWidget {
  const LightDifferentColorModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelLarge(loc(context).modalLightDifferentSeeRedLightDesc),
        const AppGap.large2(),
        LightInfoTile(
          color: ledBlue,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(loc(context).solidBlue),
              AppText.bodyMedium(loc(context).readyForSetup)
            ],
          ),
        ),
        const AppGap.large2(),
        LightInfoTile(
          color: ledPurple,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(loc(context).solidPurple),
              AppText.bodyMedium(loc(context).readyForSetup)
            ],
          ),
        ),
        const AppGap.large2(),
        LightInfoTile(
          color: ledRed,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(loc(context).modalLightDifferentSeeRedLight),
              AppText.bodyMedium(
                  loc(context).modalLightDifferentSeeRedLightDesc)
            ],
          ),
        ),
        const AppGap.large2(),
        AppText.labelLarge(loc(context).modalLightDifferentToFactoryReset),
        const AppGap.large2(),
        AppBulletList(style: AppBulletStyle.number, itemSpacing: 24, children: [
          AppStyledText.bold(
              loc(context).modalLightDifferentToFactoryResetStep1,
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              tags: const ['b']),
          AppStyledText.bold(
              loc(context).modalLightDifferentToFactoryResetStep2,
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              tags: const ['b']),
        ]),
      ],
    );
  }
}
