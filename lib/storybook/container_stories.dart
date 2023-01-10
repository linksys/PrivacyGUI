part of 'storybook.dart';

Iterable<Story> containerStories() {
  return [
    Story(
      name: 'Container/Slide Action Container',
      description: 'A custom slide action widget used in app',
      builder: (context) => Column(
        children: [
          SlideActionContainer(
            child: Container(
              decoration:
                  BoxDecoration(color: ConstantColors.secondaryBoostedGold),
              height: 60,
              child: Row(
                children: [Expanded(child: Center(child: Text('Try me')))],
              ),
            ),
            menuItems: [
              Icon(AppTheme.of(context).icons.characters.addDefault),
              Icon(AppTheme.of(context).icons.characters.crossDefault),
              Icon(AppTheme.of(context).icons.characters.searchDefault),
              Icon(AppTheme.of(context).icons.characters.mailB),
            ],
          ),
        ],
      ),
    ),
  ];
}
