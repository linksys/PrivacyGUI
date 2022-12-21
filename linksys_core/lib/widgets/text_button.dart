import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    Key? key,
    required this.text,
    this.onPress,
    this.textLevel = AppTextLevel.bold13,
    this.color,
    this.fontSize,
  }) : super(key: key);

  final String text;
  final void Function()? onPress;
  final AppTextLevel textLevel;
  final Color? color;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final color = this.color ?? theme.colors.primaryBlue;

    return TextButton(
      onPressed: onPress,
      child: AppText(
        text,
        color: onPress != null ? color : theme.colors.disabled,
        fontSize: fontSize,
        textLevel: textLevel,
      ),
    );
  }
}
