import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbImage: AssetImage('assets/icons/img_switch_thumb.png', package: 'linksys_core'),
      thumbColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return ConstantColors.primaryLinksysWhite.withOpacity(.48);
        }
        return ConstantColors.primaryLinksysWhite;
      }),
      trackColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        final theme = AppTheme.of(context);
        var color = theme.colors.tertiaryText;
        if (states.contains(MaterialState.selected)) {
          color = ConstantColors.primaryLinksysBlue;
        }
        if (states.contains(MaterialState.disabled)) {
          return color.withOpacity(.48);
        }
        return color;
      }),
    );
  }
}