import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';

Iterable<Story> textStories() {
  return [
    Story(
      name: 'Text/AppText',
      description: 'A custom Text widget used in app',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.from(AppTextLevel.values.map((e) => AppText(e.toString(), textLevel: e,))),
        ],
      ),
    ),
  ];
}