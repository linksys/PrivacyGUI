part of 'storybook.dart';

Iterable<Story> buttonStories() {
  return [
    Story(
      name: 'Buttons/buttons',
      description: 'A custom buttons used in app',
      builder: (context) => Container(
        decoration: BoxDecoration(color: AppTheme.of(context).colors.textBoxBox),
        width: double.infinity,
        child: Column(
          children: [
            AppIconButton(icon: AppTheme.of(context).icons.characters.people, onTap: () {},),
            AppIconButton(icon: AppTheme.of(context).icons.characters.people, ),
            AppPrimaryButton('Continue', onTap: (){},),
            AppPrimaryButton('Disabled',),
            AppSecondaryButton('Continue', onTap: (){
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi!')));
            },),
            AppSecondaryButton('Secondary Disabled',),
            AppTertiaryButton('Continue', onTap: (){},),
            AppTertiaryButton('Tertiary Disabled',),
            AppNavButton(title: 'Home', icon: AppTheme.of(context).icons.characters.people, onTap: () {},),
          ],
        ),
      ),
    ),
  ];
}
