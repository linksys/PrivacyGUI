import 'package:flutter/material.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

showSuccessSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    background: Theme.of(context).colorSchemeExt.secondaryGreen,
    textColor: Theme.of(context).colorSchemeExt.onSecondaryGreen,
    borderColor: Theme.of(context).colorSchemeExt.onSecondaryGreen,
  );
}

showFailedSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    background: Theme.of(context).colorScheme.errorContainer,
    textColor: Theme.of(context).colorScheme.onErrorContainer,
    borderColor: Theme.of(context).colorScheme.onErrorContainer,
  );
}

showSimpleSnackBar(
  BuildContext context,
  String message, {
  Icon? icon,
  Color? borderColor,
  Color? textColor,
  Color? background,
}) {
  showSnackBar(
    context,
    background: background,
    content: Card(
      color: background ?? Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: borderColor ??
                Theme.of(context).colorScheme.onSecondaryContainer),
        borderRadius: CustomTheme.of(context).radius.asBorderRadius().small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.medium),
        child: Row(
          children: [
            if (icon != null) ...[
              icon,
              const AppGap.medium(),
            ],
            Flexible(
              child: AppText.bodySmall(
                message,
                color: textColor ??
                    Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

showSnackBar(BuildContext context,
    {required Widget content, Color? background}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: ResponsiveLayout.isMobileLayout(context)
          ? const EdgeInsets.only(
              left: Spacing.large2,
              right: Spacing.large2,
              bottom: Spacing.large2)
          : EdgeInsets.only(
              left: ResponsiveLayout.getContentWidth(context) * 0.6,
              right: Spacing.large2,
              bottom: Spacing.large2),
      content: content,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
