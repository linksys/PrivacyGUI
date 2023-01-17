part of '../storybook.dart';

Iterable<Story> textStories() {
  return [
    Story(
      name: 'Text/AppText',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.from(AppTextLevel.values.map(
              (e) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: AppText(
                  e.toString(),
                  textLevel: e,
                ),
              ),
            )),
          ],
        ),
      ),
    ),
    Story(
      name: 'Text/Styled Text',
      description: 'A custom Styled Text widget used in app',
      builder: (context) => Column(
        children: [
          AppStyledText.descriptionMain(
            'Lorem ipsum dolor sit amet, visit us at our website <link1 href="www.linksys.com">www.linksys.com</link1>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            tags: {
              'link1': (String? text, Map<String?, String?> attrs) {
                String? link = attrs['href'];
                print('The "$link" link1 is tapped.');
              }
            },
          ),
          AppStyledText.descriptionSub(
            'Lorem ipsum dolor sit amet, visit us at our website <link1 href="www.linksys.com">www.linksys.com</link1>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            tags: {
              'link1': (String? text, Map<String?, String?> attrs) {
                String? link = attrs['href'];
                print('The "$link" link1 is tapped.');
              }
            },
          ),
        ],
      ),
    ),
  ];
}
