import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';

class AppButton extends StatelessWidget {
  final String? text;
  final Icon? icon;
  final VoidCallback? onPress;

  const AppButton({Key? key, this.text, this.icon, this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final buttonTitle = AppText(text ?? '');
    final buttonStyle = ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(theme.colors.primaryBlue));

    return icon != null
        ? ElevatedButton.icon(
            icon: icon!,
            label: buttonTitle,
            style: buttonStyle,
            onPressed: onPress,
          )
        : ElevatedButton(
            style: buttonStyle,
            onPressed: onPress,
            child: buttonTitle,
          );
  }
}
