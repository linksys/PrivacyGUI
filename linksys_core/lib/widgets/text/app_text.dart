import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';

enum AppTextLevel {
  roman11,
  roman13,
  roman15,
  roman17,
  roman21,
  roman25,
  roman31,
  bold11,
  bold13,
  bold15,
  bold17,
  bold19,
  bold23,
  bold27,
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
    this.textLevel = AppTextLevel.roman13,
  }) : super(key: key);

  const AppText.roman11(
    this.text, {
    Key? key,
    this.color,
    this.maxLines,
  })  : textLevel = AppTextLevel.roman11,
        super(key: key);

  const AppText.roman13(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.roman13,
        super(key: key);

  const AppText.roman15(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.roman15,
        super(key: key);

  const AppText.roman17(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.roman17,
        super(key: key);

  const AppText.roman21(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.roman21,
        super(key: key);

  const AppText.roman25(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.roman25,
        super(key: key);

  const AppText.roman31(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.roman31,
        super(key: key);

  const AppText.bold11(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.bold11,
        super(key: key);

  const AppText.bold13(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.bold13,
        super(key: key);

  const AppText.bold15(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.bold15,
        super(key: key);

  const AppText.bold17(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.bold17,
        super(key: key);

  const AppText.bold19(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.bold19,
        super(key: key);

  const AppText.bold23(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.bold23,
        super(key: key);

  const AppText.bold27(
      this.text, {
        Key? key,
        this.color,
        this.maxLines,
      })  : textLevel = AppTextLevel.bold27,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final color = this.color ?? theme.colors.mainText;
    final style = () {
      switch (textLevel) {
        case AppTextLevel.roman11:
          return theme.typography.roman11;
        case AppTextLevel.roman13:
          return theme.typography.roman13;
        case AppTextLevel.roman15:
          return theme.typography.roman15;
        case AppTextLevel.roman17:
          return theme.typography.roman17;
        case AppTextLevel.roman21:
          return theme.typography.roman21;
        case AppTextLevel.roman25:
          return theme.typography.roman25;
        case AppTextLevel.roman31:
          return theme.typography.roman31;
        case AppTextLevel.bold11:
          return theme.typography.bold11;
        case AppTextLevel.bold13:
          return theme.typography.bold13;
        case AppTextLevel.bold15:
          return theme.typography.bold15;
        case AppTextLevel.bold17:
          return theme.typography.bold17;
        case AppTextLevel.bold19:
          return theme.typography.bold19;
        case AppTextLevel.bold23:
          return theme.typography.bold23;
        case AppTextLevel.bold27:
          return theme.typography.bold27;
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
