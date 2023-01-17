part of '../storybook.dart';

Iterable<Story> switchStories() {
  return [
    Story(
      name: 'Switches/Full Switch',
      description: 'A custom switch widget used in app',
      builder: (context) => Column(
        children: [
          AppSwitch.full(value: true, onChanged: (value){},),
          AppSwitch.full(value: false, onChanged: (value){},),
          const AppSwitch.full(value: true,),
          const AppSwitch.full(value: false,),
        ],
      ),
    ),
    Story(
      name: 'Switches/Partial Switch',
      description: 'A custom switch widget used in app',
      builder: (context) => Column(
        children: [
          AppSwitch.partial(value: true, onChanged: (value){},),
          AppSwitch.partial(value: false, onChanged: (value){},),
          const AppSwitch.partial(value: true,),
          const AppSwitch.partial(value: false,),
        ],
      ),
    ),
  ];
}
