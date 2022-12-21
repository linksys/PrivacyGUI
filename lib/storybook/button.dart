import 'package:flutter/material.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/design/text_style.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

Iterable<Story> buttonStories() {
  return [
    Story(
      name: 'Button/Button',
      description: '',
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.knobs
                .sliderInt(label: 'Padding vertical', initial: 10, max: 500)
                .toDouble(),
            horizontal: context.knobs
                .sliderInt(label: 'Padding horizontal', initial: 24, max: 500)
                .toDouble()),
        child: AppButton(
          text: context.knobs.text(label: 'Button', initial: 'AppButton'),
          onPress: context.knobs.boolean(label: 'Enable', initial: true)
              ? () {}
              : null,
        ),
      ),
    ),
    Story(
      name: 'Button/TextButton',
      description: '',
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.knobs
                .sliderInt(label: 'Padding vertical', initial: 10, max: 500)
                .toDouble(),
            horizontal: context.knobs
                .sliderInt(label: 'Padding horizontal', initial: 24, max: 500)
                .toDouble()),
        child: AppTextButton(
          text: context.knobs.text(label: 'Button', initial: 'AppTextButton'),
          onPress: context.knobs.boolean(label: 'Enable', initial: true)
              ? () {}
              : null,
        ),
      ),
    ),
  ];
}
