part of 'storybook.dart';

Iterable<Story> iconStories() {
  return [
    Story(
        name: 'Icons/icon',
        description: 'A custom Icon widget used in app',
        builder: (context) => Scaffold(
              body: Container(
                decoration: BoxDecoration(
                    color: AppTheme.of(context).colors.textBoxBox),
                width: double.infinity,
                child: Column(
                  children: [
                    AppIcon.small(AppTheme.of(context).icons.characters.people),
                    AppIcon.regular(
                        AppTheme.of(context).icons.characters.people),
                    AppIcon.big(AppTheme.of(context).icons.characters.people),
                  ],
                ),
              ),
            )),
  ];
}
