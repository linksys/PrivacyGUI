part of '../storybook.dart';

Iterable<Story> modalStories() {
  return [
    Story(
      name: 'Modal/Full Modal Layout',
      description: 'A custom modal layout used in app',
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppModalLayout(
            closeCallback: () {},
            image: AppTheme.of(context).images.tempIllustration,
            title: 'Enable bridge mode?',
            description:
                'You won’t be able to use advanced settings such as Linksys Secure, Content filtering, or Internet schedule. (WIP)',
            positiveButton:
                ButtonData(text: 'Enable Bridge Mode', onClicked: () {}),
            negativeButton: ButtonData(text: 'Cancel', onClicked: () {}),
          ),
        ],
      ),
    ),
    Story(
      name: 'Modal/Normal Modal Layout',
      description: 'A custom modal layout used in app',
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppModalLayout(
            closeCallback: () {},
            title: 'Enable bridge mode?',
            description:
                'You won’t be able to use advanced settings such as Linksys Secure, Content filtering, or Internet schedule. (WIP)',
            positiveButton:
                ButtonData(text: 'Enable Bridge Mode', onClicked: () {}),
            negativeButton: ButtonData(text: 'Cancel', onClicked: () {}),
          ),
        ],
      ),
    ),
    Story(
      name: 'Modal/Title only Modal Layout',
      description: 'A custom modal layout used in app',
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppModalLayout(
            closeCallback: () {},
            title: 'Enable bridge mode?',
            positiveButton:
                ButtonData(text: 'Enable Bridge Mode', onClicked: () {}),
            negativeButton: ButtonData(text: 'Cancel', onClicked: () {}),
          ),
        ],
      ),
    ),
    Story(
      name: 'Modal/Description only Modal Layout',
      description: 'A custom modal layout used in app',
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppModalLayout(
            closeCallback: () {},
            description:
                'You won’t be able to use advanced settings such as Linksys Secure, Content filtering, or Internet schedule. (WIP)',
            positiveButton:
                ButtonData(text: 'Enable Bridge Mode', onClicked: () {}),
            negativeButton: ButtonData(text: 'Cancel', onClicked: () {}),
          ),
        ],
      ),
    ),
    Story(
      name: 'Modal/Description and positive button only Modal Layout',
      description: 'A custom modal layout used in app',
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppModalLayout(
            closeCallback: () {},
            description:
                'You won’t be able to use advanced settings such as Linksys Secure, Content filtering, or Internet schedule. (WIP)',
            positiveButton:
                ButtonData(text: 'Enable Bridge Mode', onClicked: () {}),
          ),
        ],
      ),
    ),
  ];
}
