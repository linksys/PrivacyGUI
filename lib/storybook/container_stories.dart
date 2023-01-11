part of 'storybook.dart';

Iterable<Story> containerStories() {
  return [
    Story(
      name: 'Container/Slide Action Container',
      description: 'A custom slide action widget used in app',
      builder: (context) => Column(
        children: [
          AppSlideActionContainer(
            child: Container(
              decoration:
              BoxDecoration(color: ConstantColors.secondaryBoostedGold),
              height: 60,
              child: Row(
                children: [Expanded(child: Center(child: Text('Slide left')))],
              ),
            ),
            leftMenuItems: [
              AppMenuItem(
                  icon: AppTheme.of(context).icons.characters.profileDefault,
                  background: ConstantColors.tertiaryGreen,
                  onTap: () {}),
            ],
          ),
          AppGap.big(),
          AppSlideActionContainer(
            child: Container(
              decoration:
              BoxDecoration(color: ConstantColors.secondaryBoostedGold),
              height: 60,
              child: Row(
                children: [Expanded(child: Center(child: Text('Slide right')))],
              ),
            ),
            rightMenuItems: [
              AppMenuItem(
                  icon: AppTheme.of(context).icons.characters.crossDefault,
                  background: ConstantColors.tertiaryRed,
                  onTap: () {}),
            ],
          ),
          AppGap.big(),
          AppSlideActionContainer(
            child: Container(
              decoration:
                  BoxDecoration(color: ConstantColors.secondaryBoostedGold),
              height: 60,
              child: Row(
                children: [Expanded(child: Center(child: Text('Slide left/right')))],
              ),
            ),
            leftMenuItems: [
              AppMenuItem(
                  icon: AppTheme.of(context).icons.characters.profileDefault,
                  background: ConstantColors.tertiaryGreen,
                  onTap: () {}),
            ],
            rightMenuItems: [
              AppMenuItem(
                  icon: AppTheme.of(context).icons.characters.searchDefault,
                  background: ConstantColors.primaryLinksysBlue,
                  onTap: () {}),
              AppMenuItem(
                  icon: AppTheme.of(context).icons.characters.addDefault,
                  background: ConstantColors.secondaryCyberPurple,
                  onTap: () {}),
              AppMenuItem(
                  icon: AppTheme.of(context).icons.characters.crossDefault,
                  background: ConstantColors.tertiaryRed,
                  onTap: () {}),
            ],
          ),
          AppGap.big(),
          AppSlideActionContainer(
            child: Container(
              decoration:
              BoxDecoration(color: ConstantColors.secondaryBoostedGold),
              height: 60,
              child: Row(
                children: [Expanded(child: Center(child: Text('Slide left')))],
              ),
            ),
            leftMenuItems: [
              AppMenuItem(label: 'Add', onTap: () {}),
            ],
          ),
          AppGap.big(),
          AppSlideActionContainer(
            child: Container(
              decoration:
              BoxDecoration(color: ConstantColors.secondaryBoostedGold),
              height: 60,
              child: Row(
                children: [Expanded(child: Center(child: Text('Slide right')))],
              ),
            ),
            rightMenuItems: [
              AppMenuItem(label: 'Remove', background: ConstantColors.tertiaryRed, onTap: () {}),
            ],
          ),
          AppGap.big(),
          AppSlideActionContainer(
            child: Container(
              decoration:
                  BoxDecoration(color: ConstantColors.secondaryBoostedGold),
              height: 60,
              child: Row(
                children: [Expanded(child: Center(child: Text('Slide left/right')))],
              ),
            ),
            leftMenuItems: [
              AppMenuItem(label: 'Add', onTap: () {}),
            ],
            rightMenuItems: [
              AppMenuItem(label: 'Remove', background: ConstantColors.tertiaryRed, onTap: () {}),
            ],
          ),
        ],
      ),
    ),
  ];
}
