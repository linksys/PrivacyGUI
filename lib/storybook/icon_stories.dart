part of 'storybook.dart';

Iterable<Story> iconStories() {
  return [
    Story(
      name: 'Icons/Linksys Icon Set',
      description: 'A custom Icon set used in app',
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: AppTheme.of(context).icons.characters.props.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                color: Colors.amber,
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppIcon.small(AppTheme.of(context).icons.characters.props.elementAt(index)?.value),
                        AppIcon.regular(AppTheme.of(context).icons.characters.props.elementAt(index)?.value),
                        AppIcon.big(AppTheme.of(context).icons.characters.props.elementAt(index)?.value),
                      ],
                    ),
                    Text('${AppTheme.of(context).icons.characters.props.elementAt(index)?.name}'),
                  ],
                )),
              );
            }),
      ),
    ),
  ];
}
