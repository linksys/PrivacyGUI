import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/base/icon.dart';

enum AppToastType {
  positive,
  negative,
}

class AppToast extends StatelessWidget {
  final AppToastType? type;
  final String text;

  const AppToast({super.key, required this.text, this.type});

  const AppToast.positive({
    super.key,
    required this.text,
  }): type = AppToastType.positive;

  const AppToast.negative({
    super.key,
    required this.text,
  }): type = AppToastType.negative;

  @override
  Widget build(BuildContext context) {
    Color? borderColor;
    IconData? icon;

    switch(type) {
      case AppToastType.positive:
        borderColor = ConstantColors.tertiaryGreen;
        icon = AppTheme.of(context).icons.characters.checkDefault;
        break;
      case AppToastType.negative:
        borderColor = ConstantColors.tertiaryRed;
        icon = AppTheme.of(context).icons.characters.crossDefault;
        break;
      default:
        break;
    }

    return Container(
      decoration: BoxDecoration(
          border: Border.all(
              color: borderColor ?? ConstantColors.primaryLinksysBlue)),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.of(context).spacing.semiBig),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (icon != null) AppIcon.regular(icon: icon),
            if (icon != null) const AppGap.regular(),
            AppText.subhead(text),
          ],
        ),
      ),
    );
  }
}

class AppToastHelp {
  static SnackBar positiveToast(BuildContext context, {required String text}) => SnackBar(
    padding: EdgeInsets.zero,
    backgroundColor: AppTheme.of(context).colors.textBoxBox,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    content: AppToast.positive(text: text,),
  );

  static SnackBar negativeToast(context, {required String text}) => SnackBar(
    padding: EdgeInsets.zero,
    backgroundColor: AppTheme.of(context).colors.textBoxBox,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    content: AppToast.negative(text: text,),
  );
}