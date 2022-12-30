import 'package:flutter/material.dart';
import 'package:linksys_core/widgets/check_box/check_box.dart';
import 'package:linksys_core/widgets/switch/switch.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

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
