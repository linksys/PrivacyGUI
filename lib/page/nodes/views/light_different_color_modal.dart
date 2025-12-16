import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:privacy_gui/constants/color_const.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/nodes/views/light_info_tile.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
          AppGap.xxl(),
          ...isCogntive
              ? _cognitiveNodeLightSet(context)
              : _meshNodeLightSet(context),
          AppGap.xxl(),
          AppText.labelLarge(loc(context).modalLightDifferentToFactoryReset),
          AppGap.xxl(),
          _buildNumberedList(context, [
            loc(context).modalLightDifferentToFactoryResetStep1,
            loc(context).modalLightDifferentToFactoryResetStep2,
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
      AppGap.xxl(),
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
      AppGap.xxl(),
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
      AppGap.xxl(),
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
      AppGap.xxl(),
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
      AppGap.xxl(),
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
      AppGap.xxl(),
      LightInfoImageTile(
        image: SvgPicture(CustomTheme.of(context).images.nodeLightSolidRed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).solidRed),
            AppStyledText(
              text: loc(context).nodeSolidRedDesc,
            ),
          ],
        ),
      ),
      AppGap.xxl(),
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
      AppGap.xxl(),
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
      AppGap.xxl(),
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

  Widget _buildNumberedList(BuildContext context, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final text = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: AppText.bodyMedium('$index.'),
              ),
              Expanded(
                child: AppStyledText(text: text),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
