import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/base/icon.dart';
import 'package:linksys_core/widgets/buttons/button.dart';
import 'package:linksys_core/widgets/buttons/nav_button.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

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
          const AppGap.small(),
          AppNavButton(
            title: 'Home',
            icon: AppTheme.of(context).icons.characters.profileDefault,
            onTap: () {},
          ),
          const AppGap.small(),
        ],
      ),
    ),
    Story(
        name: 'Buttons/Bottom Sheet Buttons',
        description: 'A custom buttons used in app',
        builder: (context) => Scaffold(
              bottomNavigationBar: BottomNavigationBar(items: [
                BottomNavigationBarItem(
                  icon: AppIcon.regular(
                      AppTheme.of(context).icons.characters.profileDefault),
                  label: 'tab 1'
                ),
                BottomNavigationBarItem(
                  icon: AppIcon.regular(
                      AppTheme.of(context).icons.characters.profileDefault),
                  label: 'tab 2'
                )
              ]),
            )),
  ];
}
