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
    String text = this.text;
    Color color = this.color ?? theme.colors.textBoxText;
    TextStyle style = theme.typography.descriptionSub;

    switch (textLevel) {
      case AppTextLevel.mainTitle:
        style = theme.typography.mainTitle;
        break;
      case AppTextLevel.screenName:
        style = theme.typography.screenName;
        break;
      case AppTextLevel.subhead:
        style = theme.typography.subhead;
        break;
      case AppTextLevel.inputFieldText:
        style = theme.typography.inputFieldText;
        break;
      case AppTextLevel.flavorText:
        style = theme.typography.flavorText;
        color = theme.colors.textBoxTextAlert;
        break;
      case AppTextLevel.label:
        style = theme.typography.label;
        break;
      case AppTextLevel.tags:
        style = theme.typography.tags;
        color = ConstantColors.secondaryCyberPurple;
        text = text.toUpperCase();
        break;
      case AppTextLevel.navLabel:
        style = theme.typography.navLabel;
        break;
      case AppTextLevel.textLinkLarge:
        style = theme.typography.textLinkLarge;
        color = theme.colors.ctaSecondary;
        break;
      case AppTextLevel.textLinkSmall:
        style = theme.typography.textLinkSmall;
        color = theme.colors.ctaSecondary;
        break;
      case AppTextLevel.textLinkSecondaryLarge:
        style = theme.typography.textLinkSecondaryLarge;
        color = theme.colors.ctaSecondary;
        break;
      case AppTextLevel.textLinkTertiarySmall:
        style = theme.typography.textLinkTertiarySmall;
        color = theme.colors.ctaSecondary;
        break;
      case AppTextLevel.descriptionMain:
        style = theme.typography.descriptionMain;
        break;
      case AppTextLevel.descriptionSub:
        style = theme.typography.descriptionSub;
        break;
    }

    return Text(
      text,
      style: style.copyWith(
        color: color,
      ),
      maxLines: maxLines,
    );
  }
}
