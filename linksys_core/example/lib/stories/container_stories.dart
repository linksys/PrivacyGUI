part of '../storybook.dart';

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
                children: [
                  Expanded(child: Center(child: Text('Slide left/right')))
                ],
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
              AppMenuItem(
                  label: 'Remove',
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
                children: [
                  Expanded(child: Center(child: Text('Slide left/right')))
                ],
              ),
            ),
            leftMenuItems: [
              AppMenuItem(label: 'Add', onTap: () {}),
            ],
            rightMenuItems: [
              AppMenuItem(
                  label: 'Remove',
                  background: ConstantColors.tertiaryRed,
                  onTap: () {}),
            ],
          ),
        ],
      ),
    ),
    Story(
        name: 'Container/Dashboard background',
        description: 'Backgrounds used in app',
        builder: (context) => Scaffold(
              body: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AppTheme.of(context).images.dashboardBg2,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                )),
              ),
              bottomNavigationBar: BottomNavigationBar(
                  elevation: 0,
                  unselectedItemColor: ConstantColors.tertiaryTextGray,
                  unselectedIconTheme: IconThemeData(
                      color: ConstantColors.tertiaryTextGray,
                      size: AppTheme.of(context).icons.sizes.regular),
                  selectedItemColor: AppTheme.of(context).colors.textBoxText,
                  selectedIconTheme: IconThemeData(
                      color: AppTheme.of(context).colors.textBoxText,
                      size: AppTheme.of(context).icons.sizes.regular),
                  selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                  showUnselectedLabels: true,
                  currentIndex: context.knobs.sliderInt(
                      label: 'Selected tab',
                      initial: 0,
                      min: 0,
                      max: 3,
                      divisions: 3),
                  onTap: (index) {},
                  items: [
                    BottomNavigationBarItem(
                        icon: AppIcon.regular(
                            icon: AppTheme.of(context)
                                .icons
                                .characters
                                .homeDefault),
                        label: 'Home'),
                    BottomNavigationBarItem(
                        icon: AppIcon.regular(
                            icon: AppTheme.of(context)
                                .icons
                                .characters
                                .securityDefault),
                        label: 'Security'),
                    BottomNavigationBarItem(
                        icon: AppIcon.regular(
                            icon: AppTheme.of(context)
                                .icons
                                .characters
                                .healthDefault),
                        label: 'Health'),
                    BottomNavigationBarItem(
                        icon: AppIcon.regular(
                            icon: AppTheme.of(context)
                                .icons
                                .characters
                                .settingsDefault),
                        label: 'Settings'),
                  ]),
            )),
  ];
}
