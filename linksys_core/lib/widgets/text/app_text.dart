import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';

enum AppTextLevel {
  mainTitle,
  screenName,
  subhead,
  inputFieldText,
  flavorText,
  label,
  tags,
  navLabel,
  textLinkLarge,
  textLinkSmall,
  textLinkSecondaryLarge,
  textLinkTertiarySmall,
  descriptionMain,
  descriptionSub,
}

class AppText extends StatelessWidget {
  final String text;
  final Color? color;
  final int? maxLines;
  final AppTextLevel textLevel;

  const AppText(
    this.text, {
    Key? key,
    this.color,
    this.maxLines,
    this.textLevel = AppTextLevel.screenName,
  }) : super(key: key);

  const AppText.mainTitle(
    this.text, {
    Key? key,
    this.color,
    this.maxLines,
  })  : textLevel = AppTextLevel.mainTitle,
        super(key: key);

  const AppText.screenName(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.screenName,
        super(key: key);

  const AppText.subhead(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.subhead,
        super(key: key);

  const AppText.inputFieldText(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.inputFieldText,
        super(key: key);

  const AppText.flavorText(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.flavorText,
        super(key: key);

  const AppText.label(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.label,
        super(key: key);

  const AppText.tags(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.tags,
        super(key: key);

  const AppText.navLabel(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.navLabel,
        super(key: key);

  const AppText.textLinkLarge(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.textLinkLarge,
        super(key: key);

  const AppText.textLinkSmall(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.textLinkSmall,
        super(key: key);

  const AppText.textLinkSecondaryLarge(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.textLinkSecondaryLarge,
        super(key: key);

  const AppText.textLinkTertiarySmall(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.textLinkTertiarySmall,
        super(key: key);

  const AppText.descriptionMain(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.descriptionMain,
        super(key: key);

  const AppText.descriptionSub(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.descriptionSub,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final color = this.color ?? theme.colors.textBoxText;
    final style = () {
      switch (textLevel) {
        case AppTextLevel.mainTitle:
          return theme.typography.mainTitle;
        case AppTextLevel.screenName:
          return theme.typography.screenName;
        case AppTextLevel.subhead:
          return theme.typography.subhead;
        case AppTextLevel.inputFieldText:
          return theme.typography.inputFieldText;
        case AppTextLevel.flavorText:
          return theme.typography.flavorText;
        case AppTextLevel.label:
          return theme.typography.label;
        case AppTextLevel.tags:
          return theme.typography.tags;
        case AppTextLevel.navLabel:
          return theme.typography.navLabel;
        case AppTextLevel.textLinkLarge:
          return theme.typography.textLinkLarge;
        case AppTextLevel.textLinkSmall:
          return theme.typography.textLinkSmall;
        case AppTextLevel.textLinkSecondaryLarge:
          return theme.typography.textLinkSecondaryLarge;
        case AppTextLevel.textLinkTertiarySmall:
          return theme.typography.textLinkTertiarySmall;
        case AppTextLevel.descriptionMain:
          return theme.typography.descriptionMain;
        case AppTextLevel.descriptionSub:
          return theme.typography.descriptionSub;
      }
    }();

    return Text(
      text,
      style: style.copyWith(
        color: color,
      ),
      maxLines: maxLines,
    );
  }
}
