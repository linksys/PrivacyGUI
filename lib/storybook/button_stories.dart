import 'package:flutter/material.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

Iterable<Story> buttonStories() {
  return [
    // Story(
    //   name: 'Button/PrimaryButton',
    //   description: 'Top one button used in app',
    //   builder: (context) => Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 20),
    //     child: PrimaryButton(
    //       text: context.knobs.text(label: 'Title', initial: 'title'),
    //       onPress: () {},
    //     ),
    //   ),
    // ),
    // Story(
    //   name: 'Button/PrimaryButton with Icon',
    //   description: 'Top one button used in app',
    //   builder: (context) => Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 20),
    //     child: PrimaryButton(
    //       text: context.knobs.text(label: 'Title', initial: 'title'),
    //       icon: const Icon(Icons.lock),
    //       onPress: () {},
    //     ),
    //   ),
    // ),
    // Story(
    //   name: 'Button/SecondaryButton',
    //   description: 'Second kind of button used in app',
    //   builder: (context) => Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 20),
    //     child: SecondaryButton(
    //       text: context.knobs.text(label: 'Title', initial: 'title'),
    //       onPress: () {},
    //     ),
    //   ),
    // ),
    // Story(
    //   name: 'Button/SecondaryButton with Icon',
    //   description: 'Second kind of button used in app',
    //   builder: (context) => Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 20),
    //     child: SecondaryButton(
    //       text: context.knobs.text(label: 'Title', initial: 'title'),
    //       icon: const Icon(Icons.add_a_photo),
    //       onPress: () {},
    //     ),
    //   ),
    // ),
    // Story(
    //   name: 'Button/SimpleTextButton',
    //   description: 'Button with only blue text',
    //   builder: (context) => SimpleTextButton(
    //     text: context.knobs.text(label: 'Title', initial: 'title'),
    //     textLevel: AppTextLevel.bold17,
    //     padding: EdgeInsets.fromLTRB(
    //       context.knobs.slider(label: 'Left Padding', initial: 50.0, max: 50.0,),
    //       context.knobs.slider(label: 'Top Padding', initial: 50.0, max: 50.0,),
    //       context.knobs.slider(label: 'Right Padding', initial: 50.0, max: 50.0,),
    //       context.knobs.slider(label: 'Bottom Padding', initial: 50.0, max: 50.0,),
    //     ),
    //     onPressed: () {},
    //   ),
    //   /*
    //   builder: (context) => Padding(
    //     padding: EdgeInsets.symmetric(
    //         vertical: context.knobs
    //             .sliderInt(label: 'Padding vertical', initial: 10, max: 500)
    //             .toDouble(),
    //         horizontal: context.knobs
    //             .sliderInt(label: 'Padding horizontal', initial: 24, max: 500)
    //             .toDouble()),
    //     child: AppTextButton(
    //       text: context.knobs.text(label: 'Button', initial: 'AppTextButton'),
    //       onPress: context.knobs.boolean(label: 'Enable', initial: true)
    //           ? () {}
    //           : null,
    //     ),
    //   ),
    //    */
    // ),
  ];
}
