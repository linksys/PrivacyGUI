part of 'storybook.dart';

Iterable<Story> themeStories() {
  return [
    Story(
      name: 'Theme/Theme Colors',
      description: '',
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppTheme.of(context).colors.props.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: AppTheme.of(context)
                            .colors
                            .props
                            .elementAt(index)
                            ?.value ??
                        ConstantColors.primaryLinksysBlue,
                  ),
                ),
                box12(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTheme.of(context)
                              .colors
                              .props
                              .elementAt(index)
                              ?.name ??
                          'color name',
                      style: AppTheme.of(context).typography.descriptionMain,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    Story(
      name: 'Color set',
      description: '',
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppTheme.of(context).colors.props.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: ConstantColors()
                        .props
                        .elementAt(index)
                        ?.value ??
                        ConstantColors.primaryLinksysBlue,
                  ),
                ),
                box12(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ConstantColors()
                          .props
                          .elementAt(index)
                          ?.name ??
                          'color name',
                      style: AppTheme.of(context).typography.descriptionMain,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    Story(
      name: 'Theme/Typography',
      description: 'Combinations of Font Family, Size, and Weight',
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppTheme.of(context).typography.props.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              AppTheme.of(context)
                      .typography
                      .props
                      .elementAt(index)
                      ?.name ??
                  'null',
              style: AppTheme.of(context)
                      .typography
                      .props
                      .elementAt(index)
                      ?.value ??
                  AppTheme.of(context).typography.descriptionMain,
            ),
          ),
        ),
      ),
    ),
  ];
}
