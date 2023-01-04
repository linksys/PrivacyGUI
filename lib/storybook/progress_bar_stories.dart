import 'package:flutter/material.dart';
import 'package:linksys_core/widgets/progress_bar/progress_bar.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

Iterable<Story> progressBarStories() {
  return [
    Story(
      name: 'Switches/Full Switch',
      description: 'A custom switch widget used in app',
      builder: (context) => Column(
        children: [
          AppProgressBar(),
        ],
      ),
    ),
  ];
}
