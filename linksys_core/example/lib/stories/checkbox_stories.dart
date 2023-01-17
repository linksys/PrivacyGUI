part of '../storybook.dart';


Iterable<Story> checkboxStories() {
  return [
    Story(
      name: 'Checkbox/Checkbox',
      description: 'A custom checkbox widget used in app',
      builder: (context) => Column(
        children: [
          AppCheckbox(value: false,),
          AppCheckbox(value: true,),
          AppCheckbox(value: false,onChanged: (value) {},),
          AppCheckbox(value: true,onChanged: (value) {},),
          AppCheckbox(value: false, text: 'I agree to Terms & Conditions of Linksys',),
          AppCheckbox(value: true, text: 'I agree to Terms & Conditions of Linksys',),
          AppCheckbox(value: false, text: 'I agree to Terms & Conditions of Linksys', onChanged: (value) {},),
          AppCheckbox(value: true, text: 'I agree to Terms & Conditions of Linksys', onChanged: (value) {},),
        ],
      ),
    ),
  ];
}
