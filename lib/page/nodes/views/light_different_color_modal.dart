import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:privacy_gui/constants/color_const.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/nodes/views/light_info_tile.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';

class LightDifferentColorModal extends StatelessWidget {
  final bool isCogntive;
  const LightDifferentColorModal({
    super.key,
    this.isCogntive = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.labelLarge(loc(context).modalLightDifferentDesc),
          const AppGap.large2(),
          ...isCogntive
              ? _cognitiveNodeLightSet(context)
              : _meshNodeLightSet(context),
          const AppGap.large2(),
          AppText.labelLarge(loc(context).modalLightDifferentToFactoryReset),
          const AppGap.large2(),
          AppBulletList(
              style: AppBulletStyle.number,
              itemSpacing: 24,
              children: [
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
      ),
    );
  }

  List<Widget> _cognitiveNodeLightSet(BuildContext context) {
    return [
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightOff),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).off),
            AppText.bodyMedium(loc(context).nodeOffDesc),
          ],
        ),
      ),
      const AppGap.large2(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightBlinkBlue),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).blinkingBlue),
            AppText.bodyMedium(loc(context).nodeBlinkBlueDesc),
          ],
        ),
      ),
      const AppGap.large2(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightSolidBlue),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).solidBlue),
            AppText.bodyMedium(loc(context).nodeSolidBlueDesc),
          ],
        ),
      ),
      const AppGap.large2(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightBlinkWhite),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).blinkingWhite),
            AppText.bodyMedium(loc(context).nodeBlinkWhiteDesc),
          ],
        ),
      ),
      const AppGap.large2(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightSolidWhite),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).solidWhite),
            AppText.bodyMedium(loc(context).nodeSolidWhiteDesc),
          ],
        ),
      ),
      const AppGap.large2(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightBlinkYellow),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).blinkingYellow),
            AppText.bodyMedium(loc(context).nodeBlinkYellowDesc),
          ],
        ),
      ),
      const AppGap.large2(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightSolidRed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).solidRed),
            AppStyledText.link(
              loc(context).nodeSolidRedDesc,
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              tags: const ['u'],
            ),
          ],
        ),
      ),
      const AppGap.large2(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightBlinkRed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).blinkingRed),
            AppText.bodyMedium(loc(context).nodeBlinkRedDesc),
          ],
        ),
      ),
    ];
  }

  List<Widget> _meshNodeLightSet(BuildContext context) {
    return [
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
            AppText.bodyMedium(loc(context).modalLightDifferentSeeRedLightDesc)
          ],
        ),
      ),
    ];
  }
}
