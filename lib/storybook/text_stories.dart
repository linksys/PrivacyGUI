import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';

Iterable<Story> textStories() {
  return [
    Story(
      name: 'Text/AppText',
      description: 'A custom Text widget used in app',
      builder: (context) => AppText(
        context.knobs.text(label: 'Title', initial: 'title'),
        color: context.knobs.options(
          label: 'Text color',
          initial: AppTheme.of(context).colors.mainText,
          options: [
            Option(label: 'main text', value: AppTheme.of(context).colors.mainText),
            Option(label: 'description text', value: AppTheme.of(context).colors.descriptionText),
            Option(label: 'error text', value: AppTheme.of(context).colors.errorText),
          ],
        ),
        textLevel: context.knobs.options(
          label: 'Text style',
          initial: AppTextLevel.roman13,
          options: const [
            Option(label: 'Roman 11', value: AppTextLevel.roman11),
            Option(label: 'Roman 13', value: AppTextLevel.roman13),
            Option(label: 'Roman 15', value: AppTextLevel.roman15),
            Option(label: 'Roman 17', value: AppTextLevel.roman17),
            Option(label: 'Roman 21', value: AppTextLevel.roman21),
            Option(label: 'Roman 25', value: AppTextLevel.roman25),
            Option(label: 'Roman 31', value: AppTextLevel.roman31),
            Option(label: 'Bold 11', value: AppTextLevel.bold11),
            Option(label: 'Bold 13', value: AppTextLevel.bold13),
            Option(label: 'Bold 15', value: AppTextLevel.bold15),
            Option(label: 'Bold 17', value: AppTextLevel.bold17),
            Option(label: 'Bold 19', value: AppTextLevel.bold19),
            Option(label: 'Bold 23', value: AppTextLevel.bold23),
            Option(label: 'Bold 27', value: AppTextLevel.bold27),
          ],
        ),
        maxLines: context.knobs.nullable.sliderInt(label: 'Max lines', min: 1, max: 10, enabled: false),
      ),
    ),
  ];
}
