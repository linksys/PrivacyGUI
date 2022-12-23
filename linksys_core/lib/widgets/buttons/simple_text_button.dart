import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';

class SimpleTextButton extends StatelessWidget {
  final String text;
  final AppTextLevel textLevel;
  final EdgeInsets? padding;
  final void Function()? onPressed;

  const SimpleTextButton({
    Key? key,
    required this.text,
    this.textLevel = AppTextLevel.roman13,
    this.padding,
    this.onPressed,
  }) : super(key: key);

  factory SimpleTextButton.noPadding({
    Key? key,
    required String text,
    AppTextLevel textLevel = AppTextLevel.roman13,
    void Function()? onPressed,
  }) {
    return SimpleTextButton(
      text: text,
      textLevel: textLevel,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: padding != null ? TextButton.styleFrom(padding: padding) : null,
      onPressed: onPressed,
      child: AppText(
        text,
        color: AppTheme.of(context).colors.textButton,
        textLevel: textLevel,
      ),
    );
  }
}
