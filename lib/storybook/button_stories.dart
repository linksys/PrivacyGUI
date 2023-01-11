part of 'storybook.dart';

Iterable<Story> buttonStories() {
  return [
    Story(
      name: 'Buttons/Icon Buttons',
      description: 'A custom buttons used in app',
      builder: (context) => Column(
        children: [
          Container(
              decoration: const BoxDecoration(
                  color: ConstantColors.secondaryCyberPurple),
              child: AppIconButton(
                icon: AppTheme.of(context).icons.characters.profileDefault,
                onTap: () {},
              )),
          const AppGap.small(),
          Container(
            decoration:
                const BoxDecoration(color: ConstantColors.secondaryCyberPurple),
            child: AppIconButton(
              icon: AppTheme.of(context).icons.characters.profileDefault,
            ),
          ),
          AppIconToggleButton(
              icon1: AppTheme.of(context).icons.characters.arrowUp,
              icon2: AppTheme.of(context).icons.characters.crossDefault,
            animation: AppTweenAnimationData.leftRotate90,
          ),
          AppIconToggleButton(
            icon1: AppTheme.of(context).icons.characters.arrowUp,
            icon2: AppTheme.of(context).icons.characters.homeDefault,
            animation: AppTweenAnimationData.leftRotate180,
          ),
          AppIconToggleButton(
            icon1: AppTheme.of(context).icons.characters.arrowUp,
            icon2: AppTheme.of(context).icons.characters.searchDefault,
            animation: AppTweenAnimationData.leftRotate270,
          ),
          AppIconToggleButton(
            icon1: AppTheme.of(context).icons.characters.searchDefault,
            icon2: AppTheme.of(context).icons.characters.crossDefault,
            animation: AppTweenAnimationData.leftRotate360,
          ),
        ],
      ),
    ),
    Story(
      name: 'Buttons/Buttons',
      description: 'A custom buttons used in app',
      builder: (context) => Column(
        children: [
          AppPrimaryButton(
            'Continue',
            onTap: () {},
          ),
          const AppGap.small(),
          AppPrimaryButton(
            'Disabled',
          ),
          const AppGap.small(),
          AppSecondaryButton(
            'Continue',
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Hi!')));
            },
          ),
          const AppGap.small(),
          AppSecondaryButton(
            'Secondary Disabled',
          ),
          const AppGap.small(),
          AppTertiaryButton(
            'Continue',
            onTap: () {},
          ),
          const AppGap.small(),
          AppTertiaryButton(
            'Tertiary Disabled',
          ),
        ],
      ),
    ),
    Story(
        name: 'Buttons/Bottom Sheet Buttons',
        description: 'A custom buttons used in app',
        builder: (context) => Scaffold(
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
