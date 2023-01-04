import 'package:flutter/widgets.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:styled_text/styled_text.dart';

enum AppStyledTextLevel {
  descriptionMain,
  descriptionSub,
}

class AppStyledText extends StatelessWidget {
  final String text;
  final Color? color;
  final AppStyledTextLevel styledTextLevel;
  final Map<String, StyledTextTagActionCallback> tags;

  // const AppStyledText(
  //     this.text, {
  //       Key? key,
  //       this.color,
  //       this.maxLines,
  //       this.textLevel = AppTextLevel.screenName,
  //     }) : super(key: key);

  const AppStyledText.descriptionMain(
    this.text, {
    Key? key,
    this.color,
    this.tags = const {},
  })  : styledTextLevel = AppStyledTextLevel.descriptionMain,
        super(key: key);

  const AppStyledText.descriptionSub(
    this.text, {
    Key? key,
    this.color,
    this.tags = const {},
  })  : styledTextLevel = AppStyledTextLevel.descriptionSub,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final color = this.color ?? theme.colors.textBoxText;
    final style = () {
      switch (styledTextLevel) {
        case AppStyledTextLevel.descriptionMain:
          return theme.typography.descriptionMain;
        case AppStyledTextLevel.descriptionSub:
          return theme.typography.descriptionSub;
      }
    }();

    return StyledText(text: text, style: style.copyWith(color: color), tags: {
      ...tags.map(
        (key, value) => MapEntry(
          key,
          StyledTextActionTag(
            value,
            style: style.copyWith(
              color: ConstantColors.primaryLinksysBlue,
            ),
          ),
        ),
      )
    });
  }
}
