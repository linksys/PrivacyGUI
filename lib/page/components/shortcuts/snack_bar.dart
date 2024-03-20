import 'package:flutter/material.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

showSuccessSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    icon: const Icon(
      LinksysIcons.check,
      color: Colors.white,
    ),
    background: Color(greenTonal.get(40)),
  );
}

showFailedSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    icon: const Icon(
      LinksysIcons.close,
      color: Colors.white,
    ),
    background: Theme.of(context).colorScheme.error,
  );
}

showSimpleSnackBar(
  BuildContext context,
  String message, {
  Icon? icon,
  Color? background,
}) {
  showSnackBar(
    context,
    background: background,
    content: Row(
      children: [
        if (icon != null) ...[
          icon,
          const AppGap.regular(),
        ],
        AppText.labelMedium(
          message,
          color: Theme.of(context).colorScheme.onInverseSurface,
        ),
      ],
    ),
  );
}

showSnackBar(BuildContext context,
    {required Widget content, Color? background}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.6, right: 24, bottom: 24),
      content: content,
    ),
  );
}
