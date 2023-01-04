part of 'storybook.dart';

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
