part of 'storybook.dart';

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
  ];
}
