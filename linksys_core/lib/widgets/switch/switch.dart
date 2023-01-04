import 'package:flutter/cupertino.dart';
import 'package:linksys_core/theme/_theme.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    this.activeColor = ConstantColors.primaryLinksysBlue,
    this.onChanged,
  });

  const AppSwitch.full({
    super.key,
    required this.value,
    this.onChanged,
  }) : activeColor = ConstantColors.primaryLinksysBlue;

  const AppSwitch.partial({
    super.key,
    required this.value,
    this.onChanged,
  }) : activeColor = ConstantColors.secondaryCyberPurple;

  final Color? activeColor;
  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      thumbColor: ConstantColors.primaryLinksysWhite,
      trackColor: ConstantColors.baseTertiaryGray,
      // activeThumbImage: AssetImage('assets/icons/img_switch_thumb.png', package: 'linksys_core'),
      // thumbColor:
      //     MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
      //   if (states.contains(MaterialState.disabled)) {
      //     return ConstantColors.primaryLinksysWhite.withOpacity(.48);
      //   }
      //   return ConstantColors.primaryLinksysWhite;
      // }),
      // trackColor:
      //     MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
      //   final theme = AppTheme.of(context);
      //   var color = theme.colors.tertiaryText;
      //   if (states.contains(MaterialState.selected)) {
      //     color = ConstantColors.primaryLinksysBlue;
      //   }
      //   if (states.contains(MaterialState.disabled)) {
      //     return color.withOpacity(.48);
      //   }
      //   return color;
      // }),
    );
  }
}
