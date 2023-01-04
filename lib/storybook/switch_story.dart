part of 'storybook.dart';

Iterable<Story> switchStories() {
  return [
    Story(
      name: 'Switches/Full Switch',
      description: 'A custom switch widget used in app',
      builder: (context) => Column(
        children: [
          AppSwitch(value: true, onChanged: (value){},),
          AppSwitch(value: false, onChanged: (value){},),
          AppSwitch(value: true,),
          AppSwitch(value: false,),
        ],
      ),
    ),
  ];
}
