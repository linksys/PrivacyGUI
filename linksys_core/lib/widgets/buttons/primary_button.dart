import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';

class PrimaryButton extends StatelessWidget {
  final String? text;
  final Icon? icon;
  final VoidCallback? onPress;

  const PrimaryButton({Key? key, this.text, this.icon, this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = AppText(
      text ?? '',
      color: AppTheme.of(context).colors.mainText,
      textLevel: AppTextLevel.bold15,
    );
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTheme.of(context).colors.firstButtonBackground,
      foregroundColor: AppTheme.of(context).colors.mainText,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.of(context).radius.asBorderRadius().none,
      ),
      minimumSize: const Size.fromHeight(56),
      elevation: 0,
    );

    return icon != null
        ? ElevatedButton.icon(
            icon: icon!,
            label: title,
            style: buttonStyle,
            onPressed: onPress,
          )
        : ElevatedButton(
            style: buttonStyle,
            onPressed: onPress,
            child: title,
          );
  }
}
