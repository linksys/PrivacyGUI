part of '../storybook.dart';

Iterable<Story> appBarStories() {
  return [
    Story(
        name: 'AppBar/Title On Left',
        description: 'A custom app bar widget used in app',
        builder: (context) => ListView(
              children: [
                const LinksysAppBar(
                  leading: AppActionButton(
                    'Title',
                  ),
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: const AppActionButton(
                    'Title',
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.bellDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.bellDefault,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            )),
    Story(
        name: 'AppBar/No Title Name',
        description: 'A custom app bar widget used in app',
        builder: (context) => ListView(
              children: [
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  trailing: [
                    AppTertiaryButton.noPadding(
                      'Save',
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppTertiaryButton.noPadding(
                    'Next',
                    onTap: () {},
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    )
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppTertiaryButton.noPadding(
                    'Next',
                    onTap: () {},
                  ),
                  trailing: [
                    AppTertiaryButton.noPadding(
                      'Save',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            )),
    Story(
        name: 'AppBar/Screen Name',
        description: 'A custom app bar widget used in app',
        builder: (context) => ListView(
              children: [
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  title: const AppActionButton(
                    'Title',
                  ),
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  title: const AppActionButton(
                    'Title',
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  title: const AppActionButton(
                    'Title',
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppTertiaryButton.noPadding(
                    'Next',
                    onTap: () {},
                  ),
                  title: const AppActionButton(
                    'Title',
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  title: const AppActionButton(
                    'Title',
                  ),
                  trailing: [
                    AppTertiaryButton.noPadding(
                      'Save',
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppTertiaryButton.noPadding(
                    'Next',
                    onTap: () {},
                  ),
                  title: const AppActionButton(
                    'Title',
                  ),
                  trailing: [
                    AppTertiaryButton.noPadding(
                      'Save',
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  title: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  title: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  title: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppIconButton(
                    icon: AppTheme.of(context).icons.characters.arrowLeft,
                    onTap: () {},
                  ),
                  title: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                  trailing: [
                    AppTertiaryButton.noPadding(
                      'Save',
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppTertiaryButton.noPadding(
                    'Next',
                    onTap: () {},
                  ),
                  title: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                  trailing: [
                    AppIconButton(
                      icon: AppTheme.of(context).icons.characters.crossDefault,
                      onTap: () {},
                    ),
                  ],
                ),
                const AppGap.regular(),
                LinksysAppBar(
                  leading: AppTertiaryButton.noPadding(
                    'Next',
                    onTap: () {},
                  ),
                  title: AppActionButton(
                    'Title',
                    actions: () {},
                  ),
                  trailing: [
                    AppTertiaryButton.noPadding(
                      'Save',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            )),
  ];
}
