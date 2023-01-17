part of '../storybook.dart';

Iterable<Story> avatarStories() {
  final customAvatars = [
    'https://images.freeimages.com/images/large-previews/77c/nemo-the-horse-1339807.jpg',
    'https://images.freeimages.com/variants/pTv77dUSf4hF1g7Z18o4SgGW/f4a36f6589a0e50e702740b15352bc00e4bfaf6f58bd4db850e167794d05993d'
  ];
  return [
    Story(
      name: 'Images/Avatar',
      description: 'A custom Icon set used in app',
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            itemCount: AppTheme.of(context).images.props.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                margin: EdgeInsets.all(AppTheme.of(context).spacing.regular),
                child: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppAvatar.extraSmall(
                            image: AppTheme.of(context)
                                .images
                                .props
                                .elementAt(index)
                                .value as ImageProvider),
                        const AppGap.regular(),
                        AppAvatar.small(
                            image: AppTheme.of(context)
                                .images
                                .props
                                .elementAt(index)
                                .value as ImageProvider),
                        const AppGap.regular(),
                        AppAvatar.normal(
                            image: AppTheme.of(context)
                                .images
                                .props
                                .elementAt(index)
                                .value as ImageProvider),
                        const AppGap.regular(),
                        AppAvatar.large(
                            image: AppTheme.of(context)
                                .images
                                .props
                                .elementAt(index)
                                .value as ImageProvider),
                      ],
                    ),
                  ],
                )),
              );
            }),
      ),
    ),
  ];
}
