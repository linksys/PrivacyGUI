import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/design/text_style.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

Iterable<Story> themeStories() {
  Map<String, Color> colors = {
    'white': MoabColor.white,
    'whiteAlpha10': MoabColor.whiteAlpha10,
    'whiteAlpha70': MoabColor.whiteAlpha70,
    'black': MoabColor.black,
    'blackAlpha70': MoabColor.blackAlpha70,
    'primaryBlue': MoabColor.primaryBlue,
    'primaryBlueAlpha10': MoabColor.primaryBlueAlpha10,
    'progressBarBlue': MoabColor.progressBarBlue,
    'textButtonBlue': MoabColor.textButtonBlue,
    'placeholderGrey': MoabColor.placeholderGrey,
    'progressBarGreen': MoabColor.progressBarGreen,
    'dividerGrey': MoabColor.dividerGrey,
    'primaryDarkGrey': MoabColor.primaryDarkGrey,
    'primaryDarkGreen': MoabColor.primaryDarkGreen,
    'scannerBoarder': MoabColor.scannerBoarder,
    'listItemCheck': MoabColor.listItemCheck,
    'authBackground': MoabColor.authBackground,
    'setupFinishCardBackground': MoabColor.setupFinishCardBackground,
    'dashboardBackground': MoabColor.dashboardBackground,
    'dashboardTileBackground': MoabColor.dashboardTileBackground,
    'dashboardDisabled': MoabColor.dashboardDisabled,
    'cardBackground': MoabColor.cardBackground,
    'dashboardBottomBackground': MoabColor.dashboardBottomBackground,
    'topologyNoInternet': MoabColor.topologyNoInternet,
    'avatarBackground': MoabColor.avatarBackground,
    'contentFilterChildPreset': MoabColor.contentFilterChildPreset,
    'contentFilterTeenPreset': MoabColor.contentFilterTeenPreset,
    'contentFilterAdultPreset': MoabColor.contentFilterAdultPreset,
  };

  Map<String, TextStyle> textStyle = {
    'roman11': roman11,
    'roman13': roman13,
    'roman15': roman15,
    'roman17': roman17,
    'roman21': roman21,
    'roman25': roman25,
    'roman31': roman31,
    'bold11': bold11,
    'bold13': bold13,
    'bold15': bold15,
    'bold17': bold17,
    'bold19': bold19,
    'bold23': bold23,
    'bold27': bold27,
  };

  return [
    Story(
      name: 'Theme/Colors',
      description: '',
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.knobs
                .sliderInt(label: 'Padding vertical', initial: 10, max: 500)
                .toDouble(),
            horizontal: context.knobs
                .sliderInt(label: 'Padding horizontal', initial: 24, max: 500)
                .toDouble()),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: colors.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: colors.values.elementAt(index),
                  ),
                ),
                box12(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BaseText(
                      text: colors.keys.elementAt(index),
                      style: roman17,
                    ),
                    BaseText(
                      text: colors.values.elementAt(index).toString(),
                      style: roman13,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    Story(
      name: 'Theme/FontSize',
      description: '',
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.knobs
                .sliderInt(label: 'Padding vertical', initial: 10, max: 500)
                .toDouble(),
            horizontal: context.knobs
                .sliderInt(label: 'Padding horizontal', initial: 24, max: 500)
                .toDouble()),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: textStyle.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BaseText(
              text: textStyle.keys.elementAt(index),
              style: textStyle.values.elementAt(index),
            ),
          ),
        ),
      ),
    ),
  ];
}
