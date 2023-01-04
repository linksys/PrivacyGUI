import 'package:flutter/cupertino.dart';
import 'package:linksys_core/widgets/text/app_styled_text.dart';
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
          initial: AppTheme.of(context).colors.textBoxText,
          options: [
            Option(
                label: 'main text',
                value: AppTheme.of(context).colors.textBoxText),
            Option(
                label: 'description text',
                value: AppTheme.of(context).colors.tertiaryText),
            Option(
                label: 'error text',
                value: AppTheme.of(context).colors.textBoxTextAlert),
          ],
        ),
        textLevel: context.knobs.options(
          label: 'Text style',
          initial: AppTextLevel.screenName,
          options: const [
            Option(label: 'mainTitle', value: AppTextLevel.mainTitle),
            Option(label: 'screenName', value: AppTextLevel.screenName),
            Option(label: 'subhead', value: AppTextLevel.subhead),
            Option(label: 'inputFieldText', value: AppTextLevel.inputFieldText),
            Option(label: 'flavorText', value: AppTextLevel.flavorText),
            Option(label: 'label', value: AppTextLevel.label),
            Option(label: 'tags', value: AppTextLevel.tags),
            Option(label: 'navLabel', value: AppTextLevel.navLabel),
            Option(label: 'textLinkLarge', value: AppTextLevel.textLinkLarge),
            Option(label: 'textLinkSmall', value: AppTextLevel.textLinkSmall),
            Option(
                label: 'textLinkSecondaryLarge',
                value: AppTextLevel.textLinkSecondaryLarge),
            Option(
                label: 'textLinkTertiarySmall',
                value: AppTextLevel.textLinkTertiarySmall),
            Option(
                label: 'descriptionMain', value: AppTextLevel.descriptionMain),
            Option(label: 'descriptionSub', value: AppTextLevel.descriptionSub),
          ],
        ),
        maxLines: context.knobs.nullable
            .sliderInt(label: 'Max lines', min: 1, max: 10, enabled: false),
      ),
    ),
    Story(
        name: 'Text/Styled Text',
        description: 'A custom Styled Text widget used in app',
        builder: (context) => Column(
              children: [
                AppStyledText.descriptionMain(
                  'Lorem ipsum dolor sit amet, visit us at our website <link1 href="www.linksys.com">www.linksys.com</link1>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  tags: {
                    'link1': (String? text, Map<String?, String?> attrs) {
                      String? link = attrs['href'];
                      print('The "$link" link1 is tapped.');
                    }
                  },
                ),
                AppStyledText.descriptionSub(
                  'Lorem ipsum dolor sit amet, visit us at our website <link1 href="www.linksys.com">www.linksys.com</link1>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  tags: {
                    'link1': (String? text, Map<String?, String?> attrs) {
                      String? link = attrs['href'];
                      print('The "$link" link1 is tapped.');
                    }
                  },
                ),
              ],
            )),
  ];
}
